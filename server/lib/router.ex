require Logger

defmodule BitcoinStream.Router do
  use Plug.Router

  alias BitcoinStream.BlockData, as: BlockData
  alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
  alias BitcoinStream.BlockData, as: BlockData
  alias BitcoinStream.RPC, as: RPC
  alias BitcoinStream.Index.Spend, as: SpendIndex

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
      {:ok, block, true} ->
        put_resp_header(conn, "cache-control", "public, max-age=1200, immutable")
        |> send_resp(200, block)

        {:ok, block, false} ->
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
        put_resp_header(conn, "cache-control", "public, max-age=300, immutable")
        |> send_resp(200, tx)
      _ ->
        Logger.debug("Error getting tx hash");
        send_resp(conn, 404, "Transaction not found")
    end
  end

  match "/api/spends/:txid" do
    case get_tx_spends(txid) do
      {:ok, spends} ->
        put_resp_header(conn, "cache-control", "public, max-age=10, immutable")
        |> send_resp(200, spends)
      _ ->
        Logger.debug("Error getting tx spends");
        send_resp(conn, 200, "[]")
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
      {:ok, payload, true}
    else
      with  {:ok, 200, block} <- RPC.request(:rpc, "getblock", [hash, 2]),
            {:ok, cleaned} <- BlockData.clean_block(block),
            {:ok, payload} <- Jason.encode(cleaned) do
        {:ok, payload, false}
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
      {:ok, 500, nil} ->
        # specially handle the genesis coinbase transaction
        with true <- (txid == "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"),
             rawtx <- Base.decode16!("01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000", [case: :lower]),
             {:ok, txn } <- BitcoinTx.decode(rawtx),
             inflated_txn <- BitcoinTx.inflate(txn, false),
             {:ok, payload} <- Jason.encode(%{tx: inflated_txn, blockheight: 0, blockhash: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f", time: 1231006505}) do
          {:ok, payload}
        else
          _ -> :err
        end

      err ->
        IO.inspect(err);
        :err
    end
  end

  defp get_tx_spends(txid) do
    with {:ok, spends} <- SpendIndex.get_tx_spends(:spends, txid),
         {:ok, payload} <- Jason.encode(spends) do
      {:ok, payload}
    else
      err ->
        IO.inspect(err)
        :err
    end
  end
end
