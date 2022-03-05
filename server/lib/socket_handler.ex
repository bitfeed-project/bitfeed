require Logger

defmodule BitcoinStream.SocketHandler do
  @behaviour :cowboy_websocket

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
    Logger.debug("getting block with id #{last_seen}")
    last_id = BlockData.get_block_id(:block_data)
    Logger.debug("last block id: #{last_id}")
    cond do
      (last_seen == nil) ->
        payload = BlockData.get_json_block(:block_data);
        {:ok, payload}
      (last_seen != last_id) ->
        payload = BlockData.get_json_block(:block_data);
        {:ok, payload}
      true ->
        {:ok, '{"type": "block", "block": {}}'}
    end
  end

  def get_mempool_count_msg() do
    count = Mempool.get(:mempool);
    "{ \"type\": \"count\", \"count\": #{count}}"
  end

  def get_block_id_msg() do
    last_id = BlockData.get_block_id(:block_data);
    "{ \"type\": \"block_id\", \"block_id\": \"#{last_id}\"}"
  end

  def websocket_handle({:text, msg}, state) do
    case msg do
      "hb" -> {:reply, {:text, msg}, state};

      "block" ->
        Logger.debug('block request');
        {:reply, {:text, "null"}, state}

      "count" ->
        count = get_mempool_count_msg();
        {:reply, {:text, count}, state}

      "block_id" ->
        last_id = get_block_id_msg();
        {:reply, {:text, last_id}, state}

      json ->
        with {:ok, result} <- Jason.decode(json) do
          case result do
            %{"last" => block_id, "method" => "get_block"} ->
              case get_block(block_id) do
                {:ok, block_msg} ->
                  {:reply, {:text, block_msg}, state};

                _ -> {:reply, {:text, "error"}, state}
              end
            _ -> {:reply, {:text, "??"}, state}
          end
        else
          {:error, reason} ->
            Logger.error("Failed to parse websocket message");
            Logger.error("#{inspect(reason)}")
          reason ->
            Logger.error("other response");
            Logger.error("#{inspect(reason)}")
          _ -> {:reply, {:text, "?"}, state}
        end
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
