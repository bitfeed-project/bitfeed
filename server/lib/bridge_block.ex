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

  def child_spec(host: host, port: port) do
    %{
      id: BitcoinStream.Bridge.Block,
      start: {BitcoinStream.Bridge.Block, :start_link, [host, port]}
    }
  end

  def start_link(host, port) do
    IO.puts("Starting Bitcoin Block bridge on #{host} port #{port}")
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
    loop(socket, 0)
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      {:ok, %{"initialblockdownload" => false}} -> true

      _ ->
        RPC.notify_on_ready(:rpc)
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

  defp loop(socket, seq) do
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
      BlockData.set_json_block(:block_data, block.id, json);
      send_block(block, count);
      loop(socket, sequence)
    else
      _ -> loop(socket, seq)
    end
  end

end
