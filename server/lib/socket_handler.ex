defmodule BitcoinStream.SocketHandler do
  @behaviour :cowboy_websocket

  use Elixometer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
  alias BitcoinStream.Mempool, as: Mempool
  alias BitcoinStream.BlockData, as: BlockData

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.BitcoinStream
    |> Registry.register("txs", {})

    {:ok, state}
  end

  def get_block(last_seen) do
    IO.puts("getting block with id #{last_seen}")
    last_id = GenServer.call(:block_data, :block_id)
    IO.puts("last block id: #{last_id}")
    cond do
      (last_seen == nil) ->
        payload = GenServer.call(:block_data, :json_block);
        {:ok, payload}
      (last_seen != last_id) ->
        payload = GenServer.call(:block_data, :json_block);
        {:ok, payload}
      true ->
        {:ok, '{"type": "block", "block": {}}'}
    end
  end

  def get_mempool_count_msg() do
    count = Mempool.get(:mempool);
    IO.puts("Count: #{count}");
    "{ \"type\": \"count\", \"count\": #{count}}"
  end

  def get_block_id_msg() do
    last_id = GenServer.call(:block_data, :block_id);
    "{ \"type\": \"block_id\", \"block_id\": \"#{last_id}\"}"
  end

  @timed(key: "timed.function")
  def websocket_handle({:text, msg}, state) do
    # IO.puts("message received: #{msg} | #{inspect self()}");
    case msg do
      "hb" -> {:reply, {:text, msg}, state};

      "block" ->
        IO.puts('block request');
        {:reply, {:text, "null"}, state}

      "count" ->
        count = get_mempool_count_msg();
        {:reply, {:text, count}, state}

      "block_id" ->
        last_id = get_block_id_msg();
        {:reply, {:text, last_id}, state}

      json ->
        IO.puts("attempting to decode msg as json");
        with {:ok, result} <- Jason.decode(json) do
          IO.puts("decoded ok");
          IO.inspect(result);
          case result do
            %{"last" => block_id, "method" => "get_block"} ->
              IO.puts('block request')
              case get_block(block_id) do
                {:ok, block_msg} ->
                  {:reply, {:text, block_msg}, state};

                _ -> {:reply, {:text, "error"}, state}
              end
            _ -> {:reply, {:text, "??"}, state}
          end
        else
          {:error, reason} ->
            IO.puts("Failed to parse websocket message");
            IO.inspect(reason)
          reason ->
            IO.puts("other response");
            IO.inspect(reason)
          _ -> {:reply, {:text, "?"}, state}
        end
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
