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
    with  {:ok, blockData} <- File.read("block.dat"),
          {:ok, block} <- BitcoinBlock.decode(blockData),
          {:ok, payload} <- Jason.encode(%{type: "block", block: block})
          do
      {:ok, payload}
    else
      {:error, reason} ->
        IO.puts("Block decoding failed: #{reason}");
        :error
      _ ->
        IO.puts("Block decoding failed: (unknown reason)");
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

          _ -> {:reply, {:text, "error"}, state}
        end
      _ ->
        {:reply, {:text, "?"}, state}
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
