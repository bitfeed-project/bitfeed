defmodule BitcoinStream.SocketHandler do
  @behaviour :cowboy_websocket

  use Elixometer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
  alias BitcoinStream.Mempool, as: Mempool

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.BitcoinStream
    |> Registry.register("txs", {})

    {:ok, state}
  end

  def load_block() do
    {:ok, "null"}
    # with  {:ok, block_data} <- File.read("block.dat"),
    #       {:ok, block} <- BitcoinBlock.decode(block_data),
    #       {:ok, payload} <- Jason.encode(%{type: "block", block: block})
    #       do
    #   {:ok, payload}
    # else
    #   {:error, reason} ->
    #     IO.puts("Block decoding failed: #{reason}");
    #     :error
    #   _ ->
    #     IO.puts("Block decoding failed: (unknown reason)");
    #     :error
    # end
  end

  def get_mempool_count_msg() do
    count = Mempool.get(:mempool);
    IO.puts("Count: #{count}");
    "{ \"type\": \"count\", \"count\": #{count}}"
  end

  @timed(key: "timed.function")
  def websocket_handle({:text, msg}, state) do
    # IO.puts("message received: #{msg} | #{inspect self()}");
    case msg do
      "hb" -> {:reply, {:text, msg}, state};

      "block" ->
        IO.puts('block request')
        case load_block() do
          {:ok, block_msg} ->
            {:reply, {:text, block_msg}, state};

          _ -> {:reply, {:text, "error"}, state}
        end

      "count" ->
        count = get_mempool_count_msg();
        {:reply, {:text, count}, state};

      _ ->
        {:reply, {:text, "?"}, state}
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
