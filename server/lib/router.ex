require Logger

defmodule BitcoinStream.Router do
  use Plug.Router

  alias BitcoinStream.BlockData, as: BlockData
  alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
  alias BitcoinStream.BlockData, as: BlockData
  alias BitcoinStream.RPC, as: RPC

  plug Corsica, origins: "*", allow_headers: :all
  plug Plug.Static,
    at: "data",
    from: :bitcoin_stream
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json", "text/plain"],
    json_decoder: Jason
  plug :dispatch

  match "api/block/height/:height" do
    case get_block_by_height(height) do
      {:ok, hash} ->
        put_resp_header(conn, "cache-control", "public, max-age=3600, immutable")
        |> send_resp(200, hash)
      _ ->
        Logger.debug("Error getting blockhash at height #{height}");
        send_resp(conn, 404, "Block not found")
    end
  end

  match "/api/block/:hash" do
    case get_block(hash) do
      {:ok, block} ->
        put_resp_header(conn, "cache-control", "public, max-age=31536000, immutable")
        |> send_resp(200, block)
      _ ->
        Logger.debug("Error getting block with hash #{hash}");
        send_resp(conn, 404, "Block not found")
    end
  end

  match "/api/tx/:hash" do
    case get_tx(hash) do
      {:ok, tx} ->
        put_resp_header(conn, "cache-control", "public, max-age=60, immutable")
        |> send_resp(200, tx)
      _ ->
        Logger.debug("Error getting tx hash");
        send_resp(conn, 404, "Transaction not found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp get_block_by_height(height_str) do
    with {height, _} <- Integer.parse(height_str),
         {:ok, 200, blockhash} <- RPC.request(:rpc, "getblockhash", [height]),
         {:ok, payload} <- Jason.encode(blockhash) do
      {:ok, payload}
    else
      err ->
        IO.inspect(err)
        :err
    end
  end

  defp get_block(hash) do
    last_id = BlockData.get_block_id(:block_data);
    if hash == last_id do
      payload = BlockData.get_json_block(:block_data);
      {:ok, payload}
    else
      with  {:ok, 200, block} <- RPC.request(:rpc, "getblock", [hash, 2]),
            {:ok, cleaned} <- BlockData.clean_block(block),
            {:ok, payload} <- Jason.encode(cleaned) do
        {:ok, payload}
      else
        err ->
          IO.inspect(err);
          :err
      end
    end
  end

  defp get_tx(txid) do
    with  {:ok, 200, verbosetx} <- RPC.request(:rpc, "getrawtransaction", [txid, true]),
          %{"hex" => hex, "blockhash" => blockhash} <- Map.merge(%{"blockhash" => nil}, verbosetx),
          {:ok, 200, %{"height" => height, "time" => time}} <- (if blockhash != nil do RPC.request(:rpc, "getblockheader", [blockhash, true]) else {:ok, 200, %{"height" => nil, "time" => nil}} end),
          rawtx <- Base.decode16!(hex, case: :lower),
          {:ok, txn } <- BitcoinTx.decode(rawtx),
          inflated_txn <- BitcoinTx.inflate(txn, false),
          {:ok, payload} <- Jason.encode(%{tx: inflated_txn, blockheight: height, blockhash: blockhash, time: time}) do
      {:ok, payload}
    else
      err ->
        IO.inspect(err);
        :err
    end
  end
end
