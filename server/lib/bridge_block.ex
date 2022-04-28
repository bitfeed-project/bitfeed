require Logger

defmodule BitcoinStream.Bridge.Block do
  @moduledoc """
  Bitcoin event bridge module.

  Consumes a source of ZMQ bitcoin tx events
  and forwards to connected websocket clients
  """
  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC
  alias BitcoinStream.BlockData, as: BlockData
  alias BitcoinStream.Index.Spend, as: SpendIndex

  def child_spec(host: host, port: port) do
    %{
      id: BitcoinStream.Bridge.Block,
      start: {BitcoinStream.Bridge.Block, :start_link, [host, port]}
    }
  end

  def start_link(host, port) do
    Logger.info("Starting Bitcoin Block bridge on #{host} port #{port}");
    GenServer.start_link(__MODULE__, {host, port})
  end

  @impl true
  def init({host, port}) do
    {:ok, {host, port}, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, {host, port}) do
    connect(host, port);
    {:noreply, {host, port}}
  end

  defp connect(host, port) do
    # check rpc online & synced
    wait_for_ibd();
    Logger.info("Node ready, connecting to block socket");

    # connect to socket
    {:ok, socket} = :chumak.socket(:sub);
    Logger.info("Connected block zmq socket on #{host} port #{port}");
    :chumak.subscribe(socket, 'rawblock')
    Logger.debug("Subscribed to rawblock events")
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> Logger.debug("Binding ok to block socket pid #{inspect pid}");
      {:error, reason} -> Logger.error("Binding block socket failed: #{reason}");
      _ -> Logger.debug("???");
    end

    # start block loop
    loop(socket, nil)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      :ok -> true

      _ ->
        Logger.info("Waiting for node to come online and fully sync before connecting to block socket");
        RPC.notify_on_ready(:rpc)
    end
  end

  defp send_block(block, count) do
    case Jason.encode(%{type: "block", block: %{id: block.id}, drop: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            Logger.debug("Forwarding to pid #{inspect pid}")
            Process.send(pid, payload, []);
          end
        end)
      {:error, reason} -> Logger.error("Error json encoding block: #{reason}");
    end
  end

  defp loop(socket, seq) do
    Logger.debug("waiting for block");
    with  {:ok, message} <- :chumak.recv_multipart(socket), # wait for the next zmq message in the queue
          _ <- Logger.debug("block msg received"),
          [_topic, payload, <<sequence::little-size(32)>>] <- message,
          _ <- Logger.debug("block msg decoded #{seq}"),
          true <- (seq != sequence), # discard contiguous duplicate messages
          _ <- Logger.info("new block received"),
          _ <- Mempool.set_block_locked(:mempool, true),
          _ <- Logger.debug("locked mempool resync"),
          {:ok, block} <- BitcoinBlock.decode(payload),
          _ <- Logger.debug("decoded block msg"),
          count <- Mempool.clear_block_txs(:mempool, block),
          _ <- Logger.debug("#{count} txs remain in mempool"),
          _ <- Mempool.set_block_locked(:mempool, false),
          _ <- Logger.debug("unlocked mempool resync"),
          {:ok, json} <- Jason.encode(block),
          _ <- Logger.debug("json encoded block data"),
          :ok <- File.write("data/last_block.json", json),
          _ <- Logger.debug("wrote block to file") do
      Logger.info("processed block #{block.id}");
      BlockData.set_json_block(:block_data, block.id, json);
      Logger.debug("cached block data");
      send_block(block, count);
      loop(socket, sequence)
    else
      _ ->
        Logger.debug("block exception");
        loop(socket, seq)
    end
  end

end
