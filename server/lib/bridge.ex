defmodule BitcoinStream.Bridge do
  @moduledoc """
  Bitcoin event bridge module.

  Consumes a source of ZMQ bitcoin tx and block events
  and forwards to connected websocket clients
  """
  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
  alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.RPC, as: RPC

  def child_spec(host: host, tx_port: tx_port, block_port: block_port, sequence_port: sequence_port) do
    %{
      id: BitcoinStream.Bridge,
      start: {BitcoinStream.Bridge, :start_link, [host, tx_port, block_port, sequence_port]}
    }
  end

  def start_link(host, tx_port, block_port, sequence_port) do
    IO.puts("Starting Bitcoin bridge on #{host} ports #{tx_port}, #{block_port}, #{sequence_port}")
    IO.puts("Mempool loaded, ready to syncronize");
    Task.start(fn -> connect_tx(host, tx_port) end);
    Task.start(fn -> connect_block(host, block_port) end);
    Task.start(fn -> connect_sequence(host, sequence_port) end);
    :timer.sleep(2000);
    Task.start(fn -> Mempool.sync(:mempool) end);
    GenServer.start_link(__MODULE__, %{})
  end

  def init(arg) do
    {:ok, arg}
  end

  defp connect_tx(host, port) do
    # check rpc online & synced
    IO.puts("Waiting for node to come online and fully sync before connecting to tx socket");
    wait_for_ibd();
    IO.puts("Node is fully synced, connecting to tx socket");

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
    tx_loop(socket, 0)
  end

  defp connect_block(host, port) do
    # check rpc online & synced
    IO.puts("Waiting for node to come online and fully sync before connecting to block socket");
    wait_for_ibd();
    IO.puts("Node is fully synced, connecting to block socket");

    # connect to socket
    {:ok, socket} = :chumak.socket(:sub);
    IO.puts("Connected block zmq socket on #{host} port #{port}");
    :chumak.subscribe(socket, 'rawblock')
    IO.puts("Subscribed to rawblock events")
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> IO.puts("Binding ok to block socket pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding block socket failed: #{reason}");
      _ -> IO.puts("???");
    end

    # start block loop
    block_loop(socket, 0)
  end

  defp connect_sequence(host, port) do
    # check rpc online & synced
    IO.puts("Waiting for node to come online and fully sync before connecting to sequence socket");
    wait_for_ibd();
    IO.puts("Node is fully synced, connecting to sequence socket");

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
    sequence_loop(socket)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      {:ok, %{"initialblockdownload" => false}} -> true
      _ ->
        Process.sleep(5000);
        wait_for_ibd()
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

  defp send_block(block, count) do
    case Jason.encode(%{type: "block", block: %{id: block.id}, drop: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            IO.puts("Forwarding to pid #{inspect pid}")
            Process.send(pid, payload, []);
          end
        end)
      {:error, reason} -> IO.puts("Error json encoding block: #{reason}");
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

  defp tx_process(payload) do
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

  defp tx_loop(socket, seq) do
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, payload, <<sequence::little-size(32)>>] <- message,
          true <- (seq  != sequence) do
      Task.start(fn -> tx_process(payload) end);
      tx_loop(socket, sequence)
    else
      _ -> tx_loop(socket, seq)
    end
  end

  defp block_loop(socket, seq) do
    IO.puts("client block loop");
    with  {:ok, message} <- :chumak.recv_multipart(socket), # wait for the next zmq message in the queue
          [_topic, payload, <<sequence::little-size(32)>>] <- message,
          true <- (seq != sequence), # discard contiguous duplicate messages
          _ <- IO.puts("block received"),
          {:ok, block} <- BitcoinBlock.decode(payload),
          count <- Mempool.clear_block_txs(:mempool, block),
          {:ok, json} <- Jason.encode(block),
          :ok <- File.write("data/last_block.json", json) do
      IO.puts("processed block #{block.id}");
      GenServer.cast(:block_data, {:json, { block.id, json }});
      send_block(block, count);
      block_loop(socket, sequence)
    else
      _ -> block_loop(socket, seq)
    end
  end

  defp sequence_loop(socket) do
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
    sequence_loop(socket)
  end

end
