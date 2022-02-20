defmodule BitcoinStream.Bridge.Tx do
  @moduledoc """
  Bitcoin event bridge module.

  Consumes a source of ZMQ bitcoin tx events
  and forwards to connected websocket clients
  """
  use GenServer

  alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC

  def child_spec(host: host, port: port) do
    %{
      id: BitcoinStream.Bridge.Tx,
      start: {BitcoinStream.Bridge.Tx, :start_link, [host, port]}
    }
  end

  def start_link(host, port) do
    IO.puts("Starting Bitcoin Tx bridge on #{host} port #{port}")
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
    IO.puts("Node ready, connecting to tx socket");

    # connect to socket
    {:ok, socket} = :chumak.socket(:sub);
    IO.puts("Connected tx zmq socket on #{host} port #{port}");
    :chumak.subscribe(socket, 'rawtx')
    IO.puts("Subscribed to rawtx events")
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> IO.puts("Binding ok to tx socket pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding tx socket failed: #{reason}");
      _ -> IO.puts("???");
    end

    # start tx loop
    loop(socket, 0)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      {:ok, %{"initialblockdownload" => false}} -> true

      _ ->
        IO.puts("Waiting for node to come online and fully sync before connecting to tx socket");
        RPC.notify_on_ready(:rpc)
    end
  end

  defp send_txn(txn, count) do
    # IO.puts("Forwarding transaction to websocket clients")
    case Jason.encode(%{type: "txn", txn: txn, count: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            Process.send(pid, payload, [])
          end
        end)
      {:error, reason} -> IO.puts("Error json encoding transaction: #{reason}");
    end
  end

  defp process(payload) do
    case BitcoinTx.decode(payload) do
      {:ok, txn} ->
        case Mempool.get_tx_status(:mempool, txn.id) do
          # :registered and :new transactions are inflated and inserted into the mempool
          status when (status in [:registered, :new]) ->
            inflated_txn = BitcoinTx.inflate(txn);
            case Mempool.insert(:mempool, txn.id, inflated_txn) do
              # Mempool.insert returns the size of the mempool if insertion was successful
              # Forward tx to clients in this case
              count when is_integer(count) -> send_txn(inflated_txn, count)

              _ -> false
            end

          # other statuses indicate duplicate or dropped transaction
          _ -> false
        end

      {:err, reason} ->
        IO.puts("Error decoding tx: #{reason}");
        false

      error ->
        IO.puts("Error decoding tx");
        IO.inspect(error);
        false
    end
  end

  defp loop(socket, seq) do
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, payload, <<sequence::little-size(32)>>] <- message,
          true <- (seq  != sequence) do
      Task.start(fn -> process(payload) end);
      loop(socket, sequence)
    else
      _ -> loop(socket, seq)
    end
  end

end
