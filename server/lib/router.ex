defmodule BitcoinStream.Router do
  use Plug.Router

  alias BitcoinStream.Donations.Lightning, as: Lightning

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

  match "/api/lightning/invoice/:id", via: :get do
    with {:ok, result} <- Lightning.get_invoice(id) do
      send_resp(conn, 200, result)
    else
      {:error, reason} ->
        IO.puts("Invoice retrieval failed");
        IO.inspect(reason)
        send_resp(conn, 500, "?!?")
      _ ->
        IO.puts("Invoice retrieval failed: (unknown reason)");
        send_resp(conn, 500, "!?!")
    end
  end

  post "/api/lightning/invoice" do
    with  %{"amount" => amount} <- conn.body_params,
          {:ok, result} <- Lightning.create_invoice(amount) do
      send_resp(conn, 200, result)
    else
      {:error, reason} ->
        IO.puts("Invoice creation failed");
        IO.inspect(reason)
        send_resp(conn, 500, "?!?")
      _ ->
        IO.puts("Invoice creation failed: (unknown reason)");
        send_resp(conn, 500, "!?!")
    end
  end

  match _ do
    send_resp(conn, 404, "404")
  end
end
