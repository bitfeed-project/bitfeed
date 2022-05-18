Application.ensure_all_started(BitcoinStream.RPC)

require Logger

defmodule BitcoinStream.Protocol.Transaction do
  @moduledoc """
    Extended bitcoin transaction struct
  """

  require Protocol
  Protocol.derive(Jason.Encoder, Bitcoinex.Transaction)
  Protocol.derive(Jason.Encoder, Bitcoinex.Transaction.In)
  Protocol.derive(Jason.Encoder, Bitcoinex.Transaction.Out)
  Protocol.derive(Jason.Encoder, Bitcoinex.Transaction.Witness)

  BitcoinStream.Protocol.Transaction

  alias BitcoinStream.RPC, as: RPC

  @derive Jason.Encoder
  defstruct [
    :version,
    :inflated,
    :vbytes,
    :inputs,
    :outputs,
    :value,
    :fee,
    # :witnesses,
    :lock_time,
    :id,
    :time
  ]

  def decode(tx_binary) do
    hex = Base.encode16(tx_binary, case: :lower);
    {:ok, raw_tx} = Bitcoinex.Transaction.decode(hex)
    id = Bitcoinex.Transaction.transaction_id(raw_tx)
    now = System.os_time(:millisecond)
    total_value = count_value(raw_tx.outputs, 0)

    {:ok, %__MODULE__{
      version: raw_tx.version,
      inflated: false,
      vbytes: raw_tx.vbytes,
      inputs: raw_tx.inputs,
      outputs: raw_tx.outputs,
      value: total_value,
      fee: 0,
      # witnesses: raw_tx.witnesses,
      lock_time: raw_tx.lock_time,
      id: id,
      time: now
    }}
  end

  @doc """
      Converts a Bitcoinex.Transaction to an extended BitcoinTx
    """
  def extend(txn) do
    id = Bitcoinex.Transaction.transaction_id(txn)
    now = System.os_time(:millisecond)

    total_value = count_value(txn.outputs, 0)

    %__MODULE__{
      version: txn.version,
      inflated: false,
      vbytes: txn.vbytes,
      inputs: txn.inputs,
      outputs: txn.outputs,
      value: total_value,
      fee: 0,
      # witnesses: txn.witnesses,
      lock_time: txn.lock_time,
      id: id,
      time: now
    }
  end

  def inflate(txn, fail_fast) do
    case inflate_inputs(txn.id, txn.inputs, fail_fast) do
      {:ok, inputs, in_value} ->
        %__MODULE__{
          version: txn.version,
          inflated: true,
          vbytes: txn.vbytes,
          inputs: inputs,
          outputs: txn.outputs,
          value: txn.value,
          fee: (in_value - txn.value),
          # witnesses: txn.witnesses,
          lock_time: txn.lock_time,
          id: txn.id,
          time: txn.time
        }

      {:failed, inputs, _in_value} ->
        %__MODULE__{
          version: txn.version,
          inflated: false,
          vbytes: txn.vbytes,
          inputs: inputs,
          outputs: txn.outputs,
          value: txn.value,
          fee: 0,
          # witnesses: txn.witnesses,
          lock_time: txn.lock_time,
          id: txn.id,
          time: txn.time
        }

      catchall ->
        Logger.error("unexpected inflate result: #{inspect(catchall)}");
        :ok
    end
  end

  defp count_value([], total) do
    total
  end

  defp count_value([next_output | rest], total) do
    count_value(rest, total + next_output.value)
  end

  defp inflate_batch(batch, fail_fast) do
    with  batch_params <- Enum.map(batch, fn input -> [[input.prev_txid], input.prev_txid <> "#{input.prev_vout}"] end),
          batch_map <- Enum.into(batch, %{}, fn p -> {p.prev_txid <> "#{p.prev_vout}", p} end),
          {:ok, 200, txs} <- RPC.batch_request(:rpc, "getrawtransaction", batch_params, fail_fast),
          successes <- Enum.filter(txs, fn %{"error" => error} -> error == nil end),
          rawtxs <- Enum.map(successes, fn tx -> %{"error" => nil, "id" => input_id, "result" => hextx} = tx; rawtx = Base.decode16!(hextx, case: :lower); [input_id, rawtx] end),
          decoded <- Enum.map(rawtxs, fn [input_id, rawtx] -> {:ok, txn} = decode(rawtx); [input_id, txn] end),
          outputs <- Enum.map(decoded,
            fn [input_id, txn] ->
              input = Map.get(batch_map, input_id);
              output = Enum.at(txn.outputs, input.prev_vout);
              %{
                prev_txid: input.prev_txid,
                prev_vout: input.prev_vout,
                script_sig: input.script_sig,
                sequence_no: input.sequence_no,
                value: output.value,
                script_pub_key: output.script_pub_key,
              }
            end
          ),
          total <- Enum.reduce(outputs, 0, fn output, acc -> acc + output.value end ) do
      if length(batch) == length(outputs) do
        {:ok, outputs, total}
      else
        {:failed, outputs, total}
      end
    else
      _ ->
        :error
    end

  catch
    err ->
      Logger.error("unexpected error inflating batch");
      IO.inspect(err);
      :error
  end

  defp inflate_inputs([], inflated, total, _fail_fast) do
    {:ok, inflated, total}
  end

  defp inflate_inputs([next_chunk | rest], inflated, total, fail_fast) do
    case inflate_batch(next_chunk, fail_fast) do
      {:ok, inflated_chunk, chunk_total} ->
        inflate_inputs(rest, inflated ++ inflated_chunk, total + chunk_total, fail_fast)
      _ ->
        {:failed, inflated ++ next_chunk ++ rest, 0}
    end
  end

  def inflate_inputs([], nil, _fail_fast) do
    { :failed, nil, 0 }
  end

  # Retrieves cached inputs if available,
  # otherwise inflates inputs in batches of up to 100
  def inflate_inputs(_txid, inputs, fail_fast) do
    inflate_inputs(Enum.chunk_every(inputs, 100), [], 0, fail_fast)
  end

end

# defmodule BitcoinStream.Protocol.Transaction.Summary do
#   @derive Jason.Encoder
#   defstruct [
#     :version,
#     :id,
#     :value
#   ]
# end
