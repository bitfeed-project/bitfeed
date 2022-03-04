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
      # witnesses: txn.witnesses,
      lock_time: txn.lock_time,
      id: id,
      time: now
    }
  end

  def inflate(txn) do
    case inflate_inputs(txn.id, txn.inputs) do
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
    end
  end

  defp count_value([], total) do
    total
  end

  defp count_value([next_output | rest], total) do
    count_value(rest, total + next_output.value)
  end

  defp inflate_input(input) do
    case input.prev_txid do
      "0000000000000000000000000000000000000000000000000000000000000000" ->
        {:ok, %{
          prev_txid: input.prev_txid,
          prev_vout: input.prev_vout,
          script_sig: input.script_sig,
          sequence_no: input.sequence_no,
          value: 0,
          script_pub_key: nil,
        } }
      _prev_txid ->
        with  {:ok, 200, hextx} <- RPC.request(:rpc, "getrawtransaction", [input.prev_txid]),
              rawtx <- Base.decode16!(hextx, case: :lower),
              {:ok, txn } <- decode(rawtx),
              output <- Enum.at(txn.outputs, input.prev_vout) do
          {:ok, %{
            prev_txid: input.prev_txid,
            prev_vout: input.prev_vout,
            script_sig: input.script_sig,
            sequence_no: input.sequence_no,
            value: output.value,
            script_pub_key: output.script_pub_key,
          } }
        else
          {:ok, 500, reason} ->
            Logger.error("transaction not found #{input.prev_txid}");
            Logger.error("#{inspect(reason)}")
          {:error, reason} ->
            Logger.error("Failed to inflate input:");
            Logger.error("#{inspect(reason)}")
            :error
          err ->
            Logger.error("Failed to inflate input: (unknown reason)");
            Logger.error("#{inspect(err)}")
            :error
        end
    end
  end

  defp inflate_inputs([], inflated, total) do
    {:ok, Enum.reverse(inflated), total}
  end
  defp inflate_inputs([next_input | rest], inflated, total) do
    case inflate_input(next_input) do
      {:ok, inflated_txn} ->
        inflate_inputs(rest, [inflated_txn | inflated], total + inflated_txn.value)
      _ ->
        {:failed, Enum.reverse(inflated) ++ [next_input | rest], 0}
    end
  end
  def inflate_inputs([], nil) do
    { :failed, nil, 0 }
  end
  def inflate_inputs(txid, inputs) do
    case :ets.lookup(:mempool_cache, txid) do
      # cache miss, actually inflate
      [] ->
        inflate_inputs(inputs, [], 0)

      # cache hit, but processed inputs not available
      [{_, nil, _}] ->
        inflate_inputs(inputs, [], 0)

      # cache hit, just return the cached values
      [{_, {inputs, total}, _}] ->
        {:ok, inputs, total}

      other ->
        Logger.error("#{inspect(other)}");
        inflate_inputs(inputs, [], 0)
    end
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
