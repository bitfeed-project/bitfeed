Application.ensure_all_started(BitcoinStream.RPC)

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
    {inputs, in_value } = inflate_inputs(txn.inputs);
    %__MODULE__{
      version: txn.version,
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
      prev_txid ->
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
            IO.puts("transaction not found #{input.prev_txid}");
            IO.inspect(reason)
          {:error, reason} ->
            IO.puts("Failed to inflate input:");
            IO.inspect(reason)
            :error
          err ->
            IO.puts("Failed to inflate input: (unknown reason)");
            IO.inspect(err);
            :error
        end
    end
  end

  defp inflate_inputs([], inflated, total) do
    {inflated, total}
  end
  defp inflate_inputs([next_input | rest], inflated, total) do
    case inflate_input(next_input) do
      {:ok, inflated_txn} ->
        inflate_inputs(rest, [inflated_txn | inflated], total + inflated_txn.value)
      _ ->
        inflate_inputs(rest, [inflated], total)
    end
  end
  defp inflate_inputs(inputs) do
    inflate_inputs(inputs, [], 0)
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
