defmodule BitcoinStream.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.BitcoinStream
    |> Registry.register("txs", {})

    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    IO.puts("message received: #{msg}");
    {:reply, {:text, msg}, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
