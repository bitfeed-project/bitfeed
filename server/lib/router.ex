defmodule BitcoinStream.Router do
  use Plug.Router

  alias BitcoinStream.BlockData, as: BlockData

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

  match "/api/block/:hash" do
    case get_block(hash) do
      {:ok, block} ->
        put_resp_header(conn, "cache-control", "public, max-age=604800, immutable")
        |> send_resp(200, block)
      _ ->
        IO.puts("Error getting block hash");
        send_resp(conn, 404, "Block not available")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp get_block(last_seen) do
    last_id = BlockData.get_block_id(:block_data);
    cond do
      (last_seen == last_id) ->
        payload = BlockData.get_json_block(:block_data);
        {:ok, payload}
      true -> :err
    end
  end
end
