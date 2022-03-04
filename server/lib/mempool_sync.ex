require Logger

defmodule BitcoinStream.Mempool.Sync do

  use GenServer
  use Task, restart: :transient

  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC

  def child_spec() do
    %{
      id: BitcoinStream.Mempool.Sync,
      start: {BitcoinStream.Mempool.Sync, :start_link, []}
    }
  end

  def start_link(args) do
    Logger.info("Starting Mempool Synchronizer")
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :sync, 2000);
    {:ok, []}
  end

  @impl true
  def handle_info(:sync, state) do
    first_sync();
    {:noreply, state}
  end

  @impl true
  def handle_info(:resync, state) do
    loop();
    {:noreply, state}
  end

  @impl true
  def handle_info(_event, state) do
    # if RPC responds after the calling process already timed out, garbled messages get dumped to handle_info
    # quietly discard
    {:noreply, state}
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      :ok -> true

      _ ->
        Logger.info("Waiting for node to come online and fully sync before synchronizing mempool");
        RPC.notify_on_ready(:rpc)
    end
  end

  defp first_sync() do
    wait_for_ibd();
    Logger.info("Preparing mempool sync");
    Mempool.sync(:mempool);
    Process.send_after(self(), :resync, 20 * 1000);
  end

  defp loop() do
    wait_for_ibd();
    case Mempool.is_block_locked(:mempool) do
      true ->
        Logger.debug("Processing block, delay mempool health check by 5 seconds");
        Process.send_after(self(), :resync, 5 * 1000)

      false ->
        with  {:ok, 200, %{"size" => size}} when is_integer(size) <- RPC.request(:rpc, "getmempoolinfo", []),
              count when is_integer(count) <- Mempool.get(:mempool) do
          Logger.debug("Mempool health check - Core count: #{size} | Bitfeed count: #{count}");

          # if we've diverged from the true count by more than 50 txs, then fix
          # ensures our count doesn't stray too far due to missed events & unexpected errors.
          if (abs(size - count) > 50) do
            Logger.debug("resync");
            Mempool.set(:mempool, size);
            newcount = Mempool.get(:mempool);
            Logger.debug("updated to #{newcount}");
          end
          # next check in 1 minute
          Process.send_after(self(), :resync, 60 * 1000)
        else
          err ->
            Logger.error("mempool health check failed");
            Logger.error("#{inspect(err)}");
            #retry in 10 seconds
            Process.send_after(self(), :resync, 10 * 1000)
        end
    end
  end
end
