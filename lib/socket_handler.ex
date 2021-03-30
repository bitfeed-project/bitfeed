defmodule BitcoinStream.SocketHandler do
  @behaviour :cowboy_websocket

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.BitcoinStream
    |> Registry.register("txs", {})

    {:ok, state}
  end

  def load_block() do
    case File.read("block.dat") do
      {:ok, blockData } ->
        case BitcoinBlock.decode(blockData) do
          {:ok, block} ->
            IO.puts('file decoded ok')
            case Jason.encode(%{type: "block", block: block}) do
              {:ok, payload} ->
                IO.puts("block encoded ok");
                { :ok, payload };
              {:error, reason} ->
                IO.puts("Error json encoding block: #{reason}");
                :error
            end
          {:error, reason} ->
            IO.puts("Block decoding failed: #{reason}");
            :error
        end

      {:error, reason} ->
        IO.puts("Reading block file failed: #{reason}");
        :error
    end
  end

  def websocket_handle({:text, msg}, state) do
    IO.puts("message received: #{msg}");
    case msg do
      "hb" -> {:reply, {:text, msg}, state};
      "block" ->
        IO.puts('block request')
        case load_block() do
          {:ok, blockMsg} ->
            {:reply, {:text, blockMsg}, state};

          _ -> {:reply, {:text, 'error'}, state}
        end
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
