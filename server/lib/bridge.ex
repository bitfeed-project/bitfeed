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

  def child_spec(host: host, tx_port: tx_port, block_port: block_port) do
    %{
      id: BitcoinStream.Bridge,
      start: {BitcoinStream.Bridge, :start_link, [host, tx_port, block_port]}
    }
  end

  def start_link(host, tx_port, block_port) do
    IO.puts("Starting Bitcoin bridge on #{host} ports #{tx_port}, #{block_port}")
    Task.start(fn -> connect_tx(host, tx_port) end);
    Task.start(fn -> connect_block(host, block_port) end);
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

    # sync mempool
    Mempool.sync(:mempool);

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

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      {:ok, %{"initialblockdownload" => false}} -> true
      _ ->
        Process.sleep(5000);
        wait_for_ibd()
    end
  end

  defp sendTxn(txn) do
    # IO.puts("Forwarding transaction to websocket clients")
    case Jason.encode(%{type: "txn", txn: txn}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
          for {pid, _} <- entries do
            Process.send(pid, payload, [])
          end
        end)
      {:error, reason} -> IO.puts("Error json encoding transaction: #{reason}");
    end
  end

  defp incrementMempool() do
    Mempool.increment(:mempool)
  end

  defp sendBlock(block) do
    case Jason.encode(%{type: "block", block: %{id: block.id}}) do
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

  defp sendMempoolCount() do
    count = Mempool.get(:mempool)
    case Jason.encode(%{type: "count", count: count}) do
      {:ok, payload} ->
        Registry.dispatch(Registry.BitcoinStream, "count", fn(entries) ->
          for {pid, _} <- entries do
            Process.send(pid, payload, []);
          end
        end)
      {:error, reason} -> IO.puts("Error json encoding count: #{reason}");
    end
  end

  defp tx_loop(socket, seq) do
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, payload, <<sequence::little-size(32)>>] <- message,
          true <- (seq  != sequence),
          {:ok, txn} <- BitcoinTx.decode(payload),
          inflated_txn <- BitcoinTx.inflate(txn) do
      sendTxn(inflated_txn);
      incrementMempool();
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
          _ <- IO.puts("received new block"),
          {:ok, block} <- BitcoinBlock.decode(payload),
          {:ok, json} <- Jason.encode(block),
          :ok <- File.write("data/last_block.json", json) do
      IO.puts("processed block #{block.id}");
      GenServer.cast(:block_data, {:json, { block.id, json }});
      sendBlock(block);
      Mempool.sync(:mempool);
      sendMempoolCount();
      block_loop(socket, sequence)
    else
      _ -> block_loop(socket, seq)
    end
  end

end
