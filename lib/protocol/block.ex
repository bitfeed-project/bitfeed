defmodule BitcoinStream.Protocol.Block do
@moduledoc """
  Summarised bitcoin block.

  Extends Bitcoinex.Block by computing total block value
  and condensing transactions into only id, value and version
"""

alias BitcoinStream.Protocol.Block
alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
alias BitcoinStream.Protocol.Transaction.Summary, as: TxSummary

@derive Jason.Encoder
defstruct [
  :version,
  :prev_block,
  :merkle_root,
  :timestamp,
  :bits,
  :nonce,
  :txn_count,
  :txns,
  :value,
  :id
]

def decode(block_binary) do
  hex = Base.encode16(block_binary, case: :lower);
  {:ok, raw_block} = Bitcoinex.Block.decode(hex)
  id = Bitcoinex.Block.block_id(block_binary)

  {summarised_txns, total_value} = summarise_txns(raw_block.txns)

  {:ok, %__MODULE__{
    version: raw_block.version,
    prev_block: raw_block.prev_block,
    merkle_root: raw_block.merkle_root,
    timestamp: raw_block.timestamp,
    bits: raw_block.bits,
    txn_count: raw_block.txn_count,
    txns: summarised_txns,
    value: total_value,
    id: id
  }}
end

defp summarise_txns(txns) do
  summarise_txns(txns, [], 0)
end

defp summarise_txns([], summarised, total) do
  {Enum.reverse(summarised), total}
end

defp summarise_txns([next | rest], summarised, total) do
  extended_txn = BitcoinTx.extend(next)
  summary = summarise_txn(extended_txn)

  summarise_txns(rest, [summary | summarised], total + summary.value)
end

defp summarise_txn(txn) do
  total_value = count_value(txn.outputs, 0)

  %TxSummary{
    version: txn.version,
    id: txn.id,
    value: total_value
  }
end

defp count_value([], total) do
  total
end

defp count_value([next_output | rest], total) do
  count_value(rest, total + next_output.value)
end

def test() do
  raw_block = File.read!("block.dat")
  {:ok, block} = Block.decode(raw_block)

  block
end

end
