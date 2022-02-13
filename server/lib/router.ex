defmodule BitcoinStream.Router do
  use Plug.Router

  plug Corsica, origins: "*", allow_headers: :all
  plug Plug.Static,
    at: "/",
    from: :bitcoin_stream
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json", "text/plain"],
    json_decoder: Jason
  plug :dispatch

  match "/block/:hash" do
    case get_block(hash) do
      {:ok, block} ->
        put_resp_header(conn, "cache-control", "public, max-age=604800, immutable")
        |> send_resp(200, block)
      _ ->
        IO.puts("Error getting block hash")
    end
  end

  match _ do
    send_resp(conn, 404, "404")
  end

  defp get_block(last_seen) do
    IO.puts("getting block with id #{last_seen}")
    last_id = GenServer.call(:block_data, :block_id)
    IO.puts("last block id: #{last_id}")
    cond do
      (last_seen == last_id) ->
        payload = GenServer.call(:block_data, :json_block);
        {:ok, payload}
      true ->
        {:err, "requested old block"}
    end
  end
end
