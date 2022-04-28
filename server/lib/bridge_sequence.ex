require Logger

defmodule BitcoinStream.Bridge.Sequence do
  @moduledoc """
  Bitcoin event bridge module.

  Consumes a source of ZMQ bitcoin tx events
  and forwards to connected websocket clients
  """
  use GenServer

  alias BitcoinStream.Index.Spend, as: SpendIndex
  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC

  def child_spec(host: host, port: port) do
    %{
      id: BitcoinStream.Bridge.Sequence,
      start: {BitcoinStream.Bridge.Sequence, :start_link, [host, port]}
    }
  end

  def start_link(host, port) do
    Logger.info("Starting Bitcoin Sequence bridge on #{host} port #{port}")
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
    Logger.info("Node ready, connecting to sequence socket");

    # connect to socket
    {:ok, socket} = :chumak.socket(:sub);
    Logger.info("Connected sequence zmq socket on #{host} port #{port}");
    :chumak.subscribe(socket, 'sequence')
    Logger.debug("Subscribed to sequence events")
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> Logger.debug("Binding ok to sequence socket pid #{inspect pid}");
      {:error, reason} -> Logger.error("Binding sequence socket failed: #{reason}");
      _ -> Logger.info("???");
    end

    # start tx loop
    loop(socket)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      :ok -> true

      _ ->
        Logger.info("Waiting for node to come online and fully sync before connecting to sequence socket");
        RPC.notify_on_ready(:rpc)
    end
  end

  defp send_txn(txn, count) do
    # Logger.info("Forwarding transaction to websocket clients")
    case Jason.encode(%{type: "txn", txn: txn, count: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            Process.send(pid, payload, [])
          end
        end)
      {:error, reason} -> Logger.error("Error json encoding transaction: #{reason}");
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
      {:error, reason} -> Logger.error("Error json encoding drop message: #{reason}");
    end
  end

  defp loop(socket) do
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, <<id::binary-size(32), type::binary-size(1), rest::binary>>, <<_sequence::little-size(32)>>] <- message,
          hash <- Base.encode16(id, case: :lower),
          event <- to_charlist(type) do
      case event do
        # Transaction added to mempool
        'A' ->
          <<seq::little-size(64)>> = rest;
          case Mempool.register(:mempool, hash, seq, true) do
            false -> false

            { txn, count } ->
              send_txn(txn, count)
          end

        # Transaction removed from mempool for non block inclusion reason
        'R' ->
          <<seq::little-size(64)>> = rest;
          case Mempool.drop(:mempool, hash) do
            count when is_integer(count) ->
              send_drop_tx(hash, count);

            _ ->
              true
          end

        'D' ->
          SpendIndex.notify_block_disconnect(:spends, hash);
          true

        'C' ->
          SpendIndex.notify_block(:spends, hash);
          true

        # Don't care about other events
        other ->
          true
      end
    else
      _ -> false
    end
    loop(socket)
  end

end
