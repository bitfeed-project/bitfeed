require Logger

defmodule BitcoinStream.Index.Spend do

  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
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
      {:ok, [dbref, indexed, false]}
    else
      {:ok, nil}
    end
  end

  @impl true
  def terminate(_reason, [dbref, indexed, _done]) do
    if (indexed != nil) do
      :rocksdb.close(dbref)
    end
  end

  @impl true
  def handle_info(:sync, [dbref, indexed, done]) do
    if (indexed != nil) do
      case sync(dbref) do
        true ->
          {:noreply, [dbref, indexed, true]}

        _ ->
          {:noreply, [dbref, indexed, false]}
      end
    else
      {:noreply, [dbref, indexed, done]}
    end
  end

  @impl true
  def handle_info(_event, state) do
    # if RPC responds after the calling process already timed out, garbled messages get dumped to handle_info
    # quietly discard
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_tx_spends, txid}, _from, [dbref, indexed, done]) do
    case get_transaction_spends(dbref, txid) do
      {:ok, spends} ->
        {:reply, {:ok, spends}, [dbref, indexed, done]}

      err ->
        Logger.error("failed to fetch tx spends");
        {:reply, err, [dbref, indexed, done]}
    end
  end

  @impl true
  def handle_cast(:new_block, [dbref, indexed, done]) do
    if (indexed != nil and done) do
      case sync(dbref) do
        true ->
          {:noreply, [dbref, indexed, true]}

        _ ->
          {:noreply, [dbref, indexed, false]}
      end
    else
      Logger.info("Already building spend index");
      {:noreply, [dbref, indexed, false]}
    end
  end

  @impl true
  def handle_cast({:block_disconnected, hash}, [dbref, indexed, done]) do
    if (indexed != nil and done) do
      block_disconnected(dbref, hash)
    end
    {:noreply, [dbref, indexed, done]}
  end

  def get_tx_spends(pid, txid) do
    GenServer.call(pid, {:get_tx_spends, txid}, 60000)
  catch
    :exit, reason ->
      case reason do
        {:timeout, _} -> {:error, :timeout}

        _ -> {:error, reason}
      end

    error -> {:error, error}
  end

  def notify_block(pid, _hash) do
    GenServer.cast(pid, :new_block)
  end

  def notify_block_disconnect(pid, hash) do
    GenServer.cast(pid, {:block_disconnected, hash})
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

      _ ->
        Logger.error("unexpected leveldb response")
    end
  end

  defp get_chain_height() do
    case RPC.request(:rpc, "getblockcount", []) do
      {:ok, 200, height} ->
        height

      _ ->
        Logger.error("unexpected RPC response");
        :err
    end
  end

  defp get_block(height) do
    with {:ok, 200, blockhash} <- RPC.request(:rpc, "getblockhash", [height]),
         {:ok, 200, blockdata} <- RPC.request(:rpc, "getblock", [blockhash, 0]),
         {:ok, block} <- BitcoinBlock.parse(blockdata) do
      block
    end
  end

  defp get_block_by_hash(hash) do
    with {:ok, 200, blockdata} <- RPC.request(:rpc, "getblock", [hash, 0]),
         {:ok, block} <- BitcoinBlock.parse(blockdata) do
      block
    end
  end

  defp index_input(spendkey, input, spends) do
    case input do
      # coinbase (skip)
      %{prev_txid: "0000000000000000000000000000000000000000000000000000000000000000"} ->
        spends

      %{prev_txid: txid, prev_vout: vout} ->
        binid = Base.decode16!(txid, [case: :lower])
        case spends[binid] do
          nil ->
            Map.put(spends, binid, [[vout, spendkey]])

          a ->
            Map.put(spends, binid, [[vout, spendkey] | a])
        end

      # unexpected input format (should never happen)
      _ ->
        spends
    end
  end

  defp index_inputs(_binid, [], _vout, spends) do
    spends
  end
  defp index_inputs(binid, [vin | rest], vout, spends) do
    spends = index_input(binid <> <<vout::integer-size(24)>>, vin, spends);
    index_inputs(binid, rest, vout+1, spends)
  end

  defp index_tx(%{id: txid, inputs: inputs}, spends) do
    binid = Base.decode16!(txid, [case: :lower]);
    index_inputs(binid, inputs, 0, spends)
  end

  defp index_txs([], spends) do
    spends
  end
  defp index_txs([tx | rest], spends) do
    spends = index_tx(tx, spends);
    index_txs(rest, spends)
  end

  defp index_block_inputs(dbref, batch, txns) do
    spends = index_txs(txns, %{});
    Enum.each(spends, fn {binid, outputs} ->
      case get_spends(dbref, binid) do
        false ->
          Logger.error("uninitialised tx in input index: #{Base.encode16(binid, [case: :lower])}")
          :ok

        prev ->
          :rocksdb.batch_put(batch, binid, fillBinarySpends(prev, outputs))
      end
    end)
  end

  defp init_block_txs(batch, txns) do
    Enum.each(txns, fn tx ->
      size = length(tx.outputs) * 35 * 8;
      binary_txid = Base.decode16!(tx.id, [case: :lower]);
      :rocksdb.batch_put(batch, binary_txid, <<0::integer-size(size)>>)
    end)
  end

  defp index_block(dbref, height) do
    with block <- get_block(height),
         {:ok, batch} <- :rocksdb.batch(),
         :ok <- init_block_txs(batch, block.txns),
         :ok <- :rocksdb.write_batch(dbref, batch, []),
         {:ok, batch} <- :rocksdb.batch(),
         :ok <- index_block_inputs(dbref, batch, block.txns),
         :ok <- :rocksdb.write_batch(dbref, batch, []) do
      :ok
    else
      err ->
        Logger.error("error indexing block");
        IO.inspect(err);
        :err
    end
  end

  # insert a 35-byte spend key into a binary spend index
  # (not sure how efficient this method is?)
  defp fillBinarySpend(bin, index, spendkey) do
    a_size = 35 * index;
    <<a::binary-size(a_size), _b::binary-size(35), c::binary>> = bin;
    <<a::binary, spendkey::binary, c::binary>>
  end
  defp fillBinarySpends(bin, []) do
    bin
  end
  defp fillBinarySpends(bin, [[index, spendkey] | rest]) do
    bin = fillBinarySpend(bin, index, spendkey);
    fillBinarySpends(bin, rest)
  end

  # "erase" a spend by zeroing out the spend key
  defp clearBinarySpend(bin, index, _spendkey) do
    a_size = 35 * index;
    b_size = 35 * 8;
    <<a::binary-size(a_size), _b::binary-size(35), c::binary>> = bin;
    <<a::binary, <<0::integer-size(b_size)>>, c::binary>>
  end
  defp clearBinarySpends(bin, []) do
    bin
  end
  defp clearBinarySpends(bin, [[index, spendkey] | rest]) do
    bin = clearBinarySpend(bin, index, spendkey);
    clearBinarySpends(bin, rest)
  end

  # On start up, check index height (load from leveldb) vs latest block height (load via rpc)
  # Until index height = block height, process next block
  defp sync(dbref) do
    wait_for_ibd();
    with index_height <- get_index_height(dbref),
         chain_height <- get_chain_height() do
      if index_height < chain_height do
        with :ok <- index_block(dbref, index_height + 1),
             :ok <- :rocksdb.put(dbref, "height", <<(index_height + 1)::integer-size(32)>>, []) do
          Logger.info("Built spend index for block #{index_height + 1}");
          Process.send_after(self(), :sync, 0);
        else
          _ ->
            Logger.error("Failed to build spend index");
            false
        end
      else
        Logger.info("Spend index fully synced to height #{index_height}");
        true
      end
    end
  end

  defp get_spends(dbref, binary_txid) do
    case :rocksdb.get(dbref, binary_txid, []) do
      {:ok, spends} ->
        spends

      :not_found ->
        false

      _ ->
        Logger.error("unexpected leveldb response");
        false
    end
  end

  defp unpack_spends(<<>>, spend_array) do
    Enum.reverse(spend_array)
  end
  # unspent outputs are zeroed out
  defp unpack_spends(<<0::integer-size(280), rest::binary>>, spend_array) do
    unpack_spends(rest, [false | spend_array])
  end
  defp unpack_spends(<<binary_txid::binary-size(32), index::integer-size(24), rest::binary>>, spend_array) do
    txid = Base.encode16(binary_txid, [case: :lower]);
    unpack_spends(rest, [[txid, index] | spend_array])
  end
  defp unpack_spends(bin) do
    unpack_spends(bin, [])
  end

  defp get_transaction_spends(dbref, txid) do
    binary_txid = Base.decode16!(txid, [case: :lower]);
    case get_spends(dbref, binary_txid) do
      false ->
        {:ok, nil}

      spends ->
        spend_array = unpack_spends(spends);
        {:ok, spend_array}
    end
  end

  defp stack_dropped_blocks(dbref, hash, undo_stack, min_height) do
    # while we're below the latest processed height
    # keep adding blocks to the undo stack until we find an ancestor in the main chain
    with {:ok, 200, blockdata} <- RPC.request(:rpc, "getblock", [hash, 1]),
         index_height <- get_index_height(dbref),
         true <- (blockdata["height"] <= index_height),
         true <- (blockdata["confirmations"] < 0) do
      stack_dropped_blocks(dbref, blockdata["previousblockhash"], [hash | undo_stack], blockdata["height"])
    else
      _ -> [undo_stack, min_height]
    end
  end

  defp drop_block_inputs(dbref, batch, txns) do
    spends = index_txs(txns, %{});
    Enum.each(spends, fn {binid, outputs} ->
      case get_spends(dbref, binid) do
        false ->
          Logger.error("uninitialised tx in input index: #{Base.encode16(binid, [case: :lower])}")
          :ok

        prev ->
          :rocksdb.batch_put(batch, binid, clearBinarySpends(prev, outputs))
      end
    end)
  end

  defp drop_block(dbref, hash) do
    with block <- get_block_by_hash(hash),
         {:ok, batch} <- :rocksdb.batch(),
         :ok <- drop_block_inputs(dbref, batch, block.txns),
         :ok <- :rocksdb.write_batch(dbref, batch, []) do
      :ok
    else
      err ->
        Logger.error("error indexing block");
        IO.inspect(err);
        :err
    end
  end

  defp drop_blocks(_dbref, []) do
    :ok
  end
  defp drop_blocks(dbref, [hash | rest]) do
    drop_block(dbref, hash);
    drop_blocks(dbref, rest)
  end
  defp block_disconnected(dbref, hash) do
    [undo_stack, min_height] = stack_dropped_blocks(dbref, hash, [], nil);
    drop_blocks(dbref, undo_stack);
    if (min_height != nil) do
      :rocksdb.put(dbref, "height", <<(min_height - 1)::integer-size(32)>>, [])
    else
      :ok
    end
  end
end
