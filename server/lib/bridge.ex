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

  def child_spec(host: host, tx_port: tx_port, block_port: block_port) do
    %{
      id: BitcoinStream.Bridge,
      start: {BitcoinStream.Bridge, :start_link, [host, tx_port, block_port]}
    }
  end

  def start_link(host, tx_port, block_port) do
    IO.puts("Starting Bitcoin bridge on #{host} ports #{tx_port}, #{block_port}")
    connect_to_server(host, tx_port);
    connect_to_server(host, block_port);
    txsub(host, tx_port);
    blocksub(host, block_port);
    GenServer.start_link(__MODULE__, %{})
  end

  def init(arg) do
    {:ok, arg}
  end

  @doc """
    Create zmq client
  """
  def start_client(host, port) do
    IO.puts("Starting client on #{host} port #{port}");
    {:ok, socket} = :chumak.socket(:pair);
    IO.puts("Client socket paired");
    {:ok, pid} = :chumak.connect(socket, :tcp, String.to_charlist(host), port);
    IO.puts("Client socket connected");
    {socket, pid}
  end

  @doc """
    Send a message from the client
  """
  def client_send(socket, message) do
    :ok = :chumak.send(socket, message);
    {:ok, response} = :chumak.recv(socket);
    response
  end

  def sendTxn(txn) do
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

  def incrementMempool() do
    Mempool.increment(:mempool)
  end

  def sendBlock(block) do
    case Jason.encode(%{type: "block", block: block}) do
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

  defp client_tx_loop(socket) do
    # IO.puts("client tx loop");
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, payload, _size] <- message,
          {:ok, txn} <- BitcoinTx.decode(payload) do
      sendTxn(txn);
      incrementMempool();
    else
      {:error, reason} -> IO.puts("Bitcoin node transaction feed bridge error: #{reason}");
      _ -> IO.puts("Bitcoin node transaction feed bridge error (unknown reason)");
    end

    client_tx_loop(socket)
  end

  defp client_block_loop(socket) do
    IO.puts("client block loop");
    with  {:ok, message} <- :chumak.recv_multipart(socket),
          [_topic, payload, _size] <- message,
          :ok <- File.write("data/block.dat", payload, [:binary]),
          {:ok, block} <- BitcoinBlock.decode(payload) do
      GenServer.cast(:block_data, {:block, block})
      sendBlock(block);
      Mempool.sync(:mempool);
      IO.puts("new block")
    else
      {:error, reason} -> IO.puts("Bitcoin node block feed bridge error: #{reason}");
      _ -> IO.puts("Bitcoin node block feed bridge error (unknown reason)");
    end

    client_block_loop(socket)
  end

  @doc """
    Set up demo zmq client
  """
  def connect_to_server(host, port) do
    IO.puts("Starting on #{host}:#{port}");
    {client_socket, _client_pid} = start_client(host, port);
    IO.puts("Started client");
    client_socket
  end

  def txsub(host, port) do
    IO.puts("Subscribing to rawtx events")
    {:ok, socket} = :chumak.socket(:sub)
    :chumak.subscribe(socket, 'rawtx')
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> IO.puts("Binding ok to pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding failed: #{reason}");
      _ -> IO.puts("unhandled response");
    end

    Task.start(fn -> client_tx_loop(socket) end);
  end

  def blocksub(host, port) do
    IO.puts("Subscribing to rawblock events")
    {:ok, socket} = :chumak.socket(:sub)
    :chumak.subscribe(socket, 'rawblock')
    case :chumak.connect(socket, :tcp, String.to_charlist(host), port) do
      {:ok, pid} -> IO.puts("Binding ok to pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding failed: #{reason}");
      _ -> IO.puts("unhandled response");
    end

    Task.start(fn -> client_block_loop(socket) end);
  end
end
