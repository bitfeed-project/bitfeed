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

  @derive Jason.Encoder
  defstruct [
    :version,
    :inputs,
    :outputs,
    :value,
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
      inputs: txn.inputs,
      outputs: txn.outputs,
      value: total_value,
      # witnesses: txn.witnesses,
      lock_time: txn.lock_time,
      id: id,
      time: now
    }
  end

  defp count_value([], total) do
    total
  end

  defp count_value([next_output | rest], total) do
    count_value(rest, total + next_output.value)
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
