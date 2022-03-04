Application.ensure_all_started(BitcoinStream.RPC)

require Logger

defmodule BitcoinStream.Protocol.Block do
@moduledoc """
  Summarised bitcoin block.

  Extends Bitcoinex.Block by computing total block value & size
  and condensing transactions into only id, value and version
"""

alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
alias BitcoinStream.Mempool, as: Mempool

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
  :fees,
  :value,
  :id
]

def decode(block_binary) do
  with  bytes <- byte_size(block_binary),
        hex <- Base.encode16(block_binary, case: :lower),
        {:ok, raw_block} <- Bitcoinex.Block.decode(hex),
        id <- Bitcoinex.Block.block_id(block_binary),
        {summarised_txns, total_value, total_fees} <- summarise_txns(raw_block.txns)
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
      fees: total_fees,
      value: total_value,
      id: id
    }}
  else
    {:error, reason} ->
      Logger.error("Error decoding data for BitcoinBlock: #{reason}")
      :error
    _ ->
      Logger.error("Error decoding data for BitcoinBlock: (unknown reason)")
      :error
  end
end

defp summarise_txns([coinbase | txns]) do
  # Mempool.is_done returns false while the mempool is still syncing
  with extended_coinbase <- BitcoinTx.extend(coinbase),
       {summarised, total, fees} <- summarise_txns(txns, [], 0, 0, Mempool.is_done(:mempool)) do
    {[extended_coinbase | summarised], total, fees}
  else
    err ->
      Logger.error("Failed to inflate block");
      Logger.error(err);
      :error
  end
end

defp summarise_txns([], summarised, total, fees, do_inflate) do
  if do_inflate do
    {Enum.reverse(summarised), total, fees}
  else
    {Enum.reverse(summarised), total, nil}
  end
end

defp summarise_txns([next | rest], summarised, total, fees, do_inflate) do
  extended_txn = BitcoinTx.extend(next)

  # if the mempool is still syncing, inflating txs will take too long, so skip it
  if do_inflate do
    inflated_txn = BitcoinTx.inflate(extended_txn)
    if (inflated_txn.inflated) do
      Logger.debug("Processing block tx #{length(summarised)}/#{length(summarised) + length(rest) + 1} | #{extended_txn.id}");
      summarise_txns(rest, [inflated_txn | summarised], total + inflated_txn.value, fees + inflated_txn.fee, true)
    else
      summarise_txns(rest, [inflated_txn | summarised], total + inflated_txn.value, nil, false)
    end
  else
    summarise_txns(rest, [extended_txn | summarised], total + extended_txn.value, nil, false)
  end
end

end
