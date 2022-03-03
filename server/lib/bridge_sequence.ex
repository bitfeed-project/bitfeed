defmodule BitcoinStream.Bridge.Sequence do
  @moduledoc """
  Bitcoin event bridge module.

  Consumes a source of ZMQ bitcoin tx events
  and forwards to connected websocket clients
  """
  use GenServer

  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC

  def child_spec(host: host, port: port) do
    %{
      id: BitcoinStream.Bridge.Sequence,
      start: {BitcoinStream.Bridge.Sequence, :start_link, [host, port]}
    }
  end

  def start_link(host, port) do
    IO.puts("Starting Bitcoin Sequence bridge on #{host} port #{port}")
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
    IO.puts("Node ready, connecting to sequence socket");

    # connect to socket
    {:ok, socket} = :chumak.socket(:sub);
    IO.puts("Connected sequence zmq socket on #{host} port #{port}");
    :chumak.subscribe(socket, 'sequence')
    IO.puts("Subscribed to sequence events")
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> IO.puts("Binding ok to sequence socket pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding sequence socket failed: #{reason}");
      _ -> IO.puts("???");
    end

    # start tx loop
    loop(socket)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      :ok -> true

      _ ->
        IO.puts("Waiting for node to come online and fully sync before connecting to sequence socket");
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

  defp send_drop_tx(txid, count) do
    case Jason.encode(%{type: "drop", txid: txid, count: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            Process.send(pid, payload, []);
          end
        end)
      {:error, reason} -> IO.puts("Error json encoding drop message: #{reason}");
    end
  end

  defp loop(socket) do
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, <<hash::binary-size(32), type::binary-size(1), seq::little-size(64)>>, <<_sequence::little-size(32)>>] <- message,
          txid <- Base.encode16(hash, case: :lower),
          event <- to_charlist(type) do
      # IO.puts("loop #{sequence}");
      case event do
        # Transaction added to mempool
        'A' ->
          case Mempool.register(:mempool, txid, seq, true) do
            false -> false

            { txn, count } ->
              # IO.puts("*SEQ* #{txid}");
              send_txn(txn, count)
          end

        # Transaction removed from mempool for non block inclusion reason
        'R' ->
          case Mempool.drop(:mempool, txid) do
            count when is_integer(count) ->
              send_drop_tx(txid, count);

            _ ->
              true
          end

        # Don't care about other events
        _ -> true
      end
    else
      _ -> false
    end
    loop(socket)
  end

end
