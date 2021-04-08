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

  def child_spec(port: port) do
    %{
      id: BitcoinStream.Bridge,
      start: {BitcoinStream.Bridge, :start_link, [port]}
    }
  end

  def start_link(port) do
    IO.puts("Starting Bitcoin bridge on port #{port}")
    connect_to_server(port);
    txsub(port);
    blocksub(port);
    GenServer.start_link(__MODULE__, %{})
  end

  def init(arg) do
    {:ok, arg}
  end

  @doc """
    Create zmq client
  """
  def start_client(port) do
    IO.puts("Starting client on port #{port}");
    {:ok, socket} = :chumak.socket(:pair);
    IO.puts("Client socket paired");
    {:ok, pid} = :chumak.connect(socket, :tcp, 'localhost', port);
    IO.puts("Client socket connected");
    {socket, pid}
  end

  @doc """
    Send a demo message from the client
  """
  def client_send(socket, message) do
    :ok = :chumak.send(socket, message);
    {:ok, response} = :chumak.recv(socket);
    response
  end

  def sendTxn(txn) do
    # IO.puts("Forwarding transaction to websocket clients")
    Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
      for {pid, _} <- entries do
        # IO.puts("Forwarding to pid #{inspect pid}")
        case Jason.encode(%{type: "txn", txn: txn}) do
          {:ok, payload} -> Process.send(pid, payload, []);
          {:error, reason} -> IO.puts("Error json encoding transaction: #{reason}");
        end
      end
    end)
  end

  def incrementMempool() do
    Mempool.increment(:mempool)
  end

  def sendBlock(block) do
    IO.puts("Forwarding block to websocket clients")
    Registry.dispatch(Registry.BitcoinStream, "txs", fn(entries) ->
      for {pid, _} <- entries do
        IO.puts("Forwarding to pid #{inspect pid}")
        case Jason.encode(%{type: "block", block: block}) do
          {:ok, payload} -> Process.send(pid, payload, []);
          {:error, reason} -> IO.puts("Error json encoding block: #{reason}");
        end
      end
    end)
  end

  defp client_tx_loop(socket) do
    IO.puts("client tx loop");
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
          :ok <- File.write("block.dat", payload, [:binary]),
          {:ok, block} <- BitcoinBlock.decode(payload) do
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
  def connect_to_server(port) do
    IO.puts("Starting on #{port}");
    {client_socket, _client_pid} = start_client(port);
    IO.puts("Started client");
    client_socket
  end

  def txsub(port) do
    IO.puts("Subscribing to rawtx events")
    {:ok, socket} = :chumak.socket(:sub)
    :chumak.subscribe(socket, 'rawtx')
    case :chumak.connect(socket, :tcp, 'localhost', port) do
      {:ok, pid} -> IO.puts("Binding ok to pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding failed: #{reason}");
      _ -> IO.puts("unhandled response");
    end

    Task.start(fn -> client_tx_loop(socket) end);
  end

  def blocksub(port) do
    IO.puts("Subscribing to rawblock events")
    {:ok, socket} = :chumak.socket(:sub)
    :chumak.subscribe(socket, 'rawblock')
    case :chumak.connect(socket, :tcp, 'localhost', port) do
      {:ok, pid} -> IO.puts("Binding ok to pid #{inspect pid}");
      {:error, reason} -> IO.puts("Binding failed: #{reason}");
      _ -> IO.puts("unhandled response");
    end

    Task.start(fn -> client_block_loop(socket) end);
  end
end
