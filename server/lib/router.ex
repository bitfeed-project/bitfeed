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

  match _ do
    send_resp(conn, 404, "404")
  end
end
