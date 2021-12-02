defmodule BitcoinStream.Metrics.SocketHandler do
  @behaviour :cowboy_websocket

  use Elixometer

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.BitcoinStream
    |> Registry.register("metrics", {})

    {:ok, state}
  end

  @timed(key: "timed.function")
  def websocket_handle({:text, msg}, state) do
    IO.puts("Metric message received: #{msg} | #{inspect self()}");
    case msg do
      "hb" -> {:reply, {:text, msg}, state};
      "metric" -> {:reply, {:text, "{ \"type\": \"metric\", \"metric\": { \"key\": \"x\", \"val\": 3.14 }}"}, state}
      _ ->
        {:reply, {:text, "?"}, state}
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
