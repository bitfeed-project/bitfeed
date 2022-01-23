defmodule BitcoinStream.Protocol.Block do
@moduledoc """
  Summarised bitcoin block.

  Extends Bitcoinex.Block by computing total block value & size
  and condensing transactions into only id, value and version
"""

alias BitcoinStream.Protocol.Block
alias BitcoinStream.Protocol.Transaction, as: BitcoinTx

@derive Jason.Encoder
defstruct [
  :version,
  :prev_block,
  :merkle_root,
  :timestamp,
  :bits,
  :bytes,
  :nonce,
  :txn_count,
  :txns,
  :value,
  :id
]

def decode(block_binary) do
  with  bytes <- byte_size(block_binary),
        hex <- Base.encode16(block_binary, case: :lower),
        {:ok, raw_block} <- Bitcoinex.Block.decode(hex),
        id <- Bitcoinex.Block.block_id(block_binary),
        {summarised_txns, total_value} <- summarise_txns(raw_block.txns)
  do
    {:ok, %__MODULE__{
      version: raw_block.version,
      prev_block: raw_block.prev_block,
      merkle_root: raw_block.merkle_root,
      timestamp: raw_block.timestamp,
      bits: raw_block.bits,
      bytes: bytes,
      txn_count: raw_block.txn_count,
      txns: summarised_txns,
      value: total_value,
      id: id
    }}
  else
    {:error, reason} ->
      IO.puts("Error decoding data for BitcoinBlock: #{reason}")
      :error
    _ ->
      IO.puts("Error decoding data for BitcoinBlock: (unknown reason)")
      :error
  end
end

defp summarise_txns(txns) do
  summarise_txns(txns, [], 0)
end

defp summarise_txns([], summarised, total) do
  {Enum.reverse(summarised), total}
end

defp summarise_txns([next | rest], summarised, total) do
  extended_txn = BitcoinTx.extend(next)

  summarise_txns(rest, [extended_txn | summarised], total + extended_txn.value)
end

def test() do
  raw_block = File.read!("data/block.dat")
  {:ok, block} = Block.decode(raw_block)

  block
end

end
