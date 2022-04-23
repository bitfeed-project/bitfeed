require Logger

defmodule BitcoinStream.Index.Spend do

  use GenServer

  alias BitcoinStream.RPC, as: RPC

  def start_link(opts) do
    Logger.info("Starting Spend Index");
    {indexed, opts} = Keyword.pop(opts, :indexed);
    GenServer.start_link(__MODULE__, [indexed], opts)
  end

  @impl true
  def init([indexed]) do
    if (indexed != nil) do
      {:ok, dbref} = :rocksdb.open(String.to_charlist("data/index/spend"), [create_if_missing: true]);
      Process.send_after(self(), :sync, 2000);
      {:ok, [dbref, indexed]}
    else
      {:ok, nil}
    end
  end

  @impl true
  def terminate(_reason, [dbref, indexed]) do
    if (indexed != nil) do
      :rocksdb.close(dbref)
    end
  end

  @impl true
  def handle_info(:sync, [dbref, indexed]) do
    if (indexed != nil) do
      sync(dbref);
    end
    {:noreply, [dbref, indexed]}
  end

  @impl true
  def handle_info(_event, state) do
    # if RPC responds after the calling process already timed out, garbled messages get dumped to handle_info
    # quietly discard
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_tx_spends, {txid, from, to}}, _from, [dbref, indexed]) do
    case get_transaction_spends(dbref, txid, from, to) do
      {:ok, spends} ->
        {:reply, {:ok, spends}, [dbref, indexed]}

      err ->
        Logger.error("failed to fetch tx spends");
        {:reply, err, [dbref, indexed]}
    end
  end

  def get_tx_spends(pid, {txid, from, to}) do
    Logger.info("GETTING TX OUTSPENDS FOR #{pid} #{txid} #{from} #{to}");
    GenServer.call(pid, {:get_tx_spends, {txid, from, to}}, 60000)
  catch
    :exit, reason ->
      case reason do
        {:timeout, _} -> {:error, :timeout}

        _ -> {:error, reason}
      end

    error -> {:error, error}
  end

  defp wait_for_ibd() do
    case RPC.get_node_status(:rpc) do
      :ok -> true

      _ ->
        Logger.info("Waiting for node to come online and fully sync before synchronizing spend index");
        RPC.notify_on_ready(:rpc)
    end
  end

  defp get_index_height(dbref) do
    case :rocksdb.get(dbref, "height", []) do
      {:ok, <<height::integer-size(32)>>} ->
        height

      :not_found ->
        -1

      err ->
        Logger.error("unexpected leveldb response")
    end
  end

  defp get_chain_height() do
    case RPC.request(:rpc, "getblockchaininfo", []) do
      {:ok, 200, %{"blocks" => height}} ->
        height

      err ->
        Logger.error("unexpected RPC response");
        :err
    end
  end

  defp get_block_data(height) do
    with {:ok, 200, blockhash} <- RPC.request(:rpc, "getblockhash", [height]),
         {:ok, 200, blockdata} <- RPC.request(:rpc, "getblock", [blockhash, 2]) do
      blockdata
    end
  end

  defp index_input(batch, spendkey, vin) do
    case vin do
      %{"txid" => txid, "vout" => vout} ->
        :rocksdb.batch_put(batch, "#{txid}:#{vout}", spendkey)

      _ -> # coinbase input
        :ok
    end
  end

  defp index_inputs(_batch, _txid, [], _vout) do
    :ok
  end
  defp index_inputs(batch, txid, [vin | rest], vout) do
    case index_input(batch, "#{txid}:#{vout}", vin) do
      :ok -> index_inputs(batch, txid, rest, vout+1)
      _ -> :err
    end
  end

  defp index_tx(batch, %{"txid" => txid, "vin" => inputs}) do
    index_inputs(batch, txid, inputs, 0)
  end

  defp index_txs(_batch, []) do
    :ok
  end
  defp index_txs(batch, [tx | rest]) do
    case index_tx(batch, tx) do
      :ok -> index_txs(batch, rest)

      _ -> :err
    end
  end

  defp index_block(batch, height) do
    with %{"tx" => txs} <- get_block_data(height),
         :ok <- index_txs(batch, txs) do
      :ok
    else
      _ -> :err
    end
  end

  # On start up, check index height (load from leveldb) vs latest block height (load via rpc)
  # Until index height = block height, process next block
  defp sync(dbref) do
    wait_for_ibd();
    with index_height <- get_index_height(dbref),
         chain_height <- get_chain_height() do
      if index_height < chain_height do
        # Logger.info("Building spend index for block #{index_height + 1}");
        with {:ok, batch} <- :rocksdb.batch(),
             :ok <- index_block(batch, index_height + 1),
             :ok <- :rocksdb.write_batch(dbref, batch, []),
             :ok <- :rocksdb.put(dbref, "height", <<(index_height + 1)::integer-size(32)>>, []) do
          Logger.info("Built spend index for block #{index_height + 1}");
          Process.send_after(self(), :sync, 0);
        else
          err ->
            Logger.error("Failed to build spend index");
            :err
        end
      else
        Logger.info("Spend index fully synced")
        :ok
      end
    end
  end

  defp get_spend(dbref, txid, vout) do
    case :rocksdb.get(dbref, "#{txid}:#{vout}", []) do
      {:ok, spend} ->
        spend

      :not_found ->
        false

      err ->
        Logger.error("unexpected leveldb response")
    end
  end

  defp get_transaction_spends(dbref, txid, limit, limit, spends) do
    spends
  end

  defp get_transaction_spends(dbref, txid, index, limit, spends) do
    [get_spend(dbref, txid, index) | get_transaction_spends(dbref, txid, index + 1, limit, spends)]
  end

  defp get_transaction_spends(dbref, txid, index, limit) do
    {:ok, get_transaction_spends(dbref, txid, index, limit, [])}
  end
end
