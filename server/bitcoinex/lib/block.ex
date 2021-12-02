defmodule Bitcoinex.Block do
  @moduledoc """
  Bitcoin on-chain transaction structure.
  Supports serialization of transactions.
  """
  alias Bitcoinex.Block
  alias Bitcoinex.Transaction
  alias Bitcoinex.Utils
  alias Bitcoinex.Transaction.Utils, as: ProtocolUtils

  defstruct [
  :version,
  :prev_block,
  :merkle_root,
  :timestamp,
  :bits,
  :nonce,
  :txn_count,
  :txns
]

  @doc """
    Returns the BlockID of the given block.
    defined as the bitcoin hash of the block header (first 80 bytes):

    BlockID is sha256(sha256(nVersion | prev_block | merkle_root | timestamp | bits | nonce))
  """
  def block_id(raw_block) do
    <<header::binary-size(80), _rest::binary>> = raw_block

    Base.encode16(
      <<:binary.decode_unsigned(
          Utils.double_sha256(header),
          :big
        )::little-size(256)>>,
      case: :lower
    )
  end

  @doc """
    Decodes a transaction in a hex encoded string into binary.
  """
  def decode(block_hex) when is_binary(block_hex) do
    case Base.decode16(block_hex, case: :lower) do
      {:ok, block_bytes} ->
        case parse(block_bytes) do
          {:ok, block} ->
            {:ok, block}

          :error ->
            {:error, :parse_error}
        end

      :error ->
        {:error, :decode_error}
    end
  end

  # returns block
  defp parse(block_bytes) do
    <<version::little-size(32), remaining::binary>> = block_bytes

    # Previous block
    <<prev_block::binary-size(32), remaining::binary>> = remaining

    # Merkle root
    <<merkle_root::binary-size(32), remaining::binary>> = remaining

    # Timestamp, difficulty target bits, nonce
    <<timestamp::little-size(32), bits::little-size(32), nonce::little-size(32), remaining::binary>> = remaining

    # Transactions
    {txn_count, remaining} = ProtocolUtils.get_counter(remaining)
    {txns, remaining} = Transaction.parse_list(txn_count, remaining)

    if byte_size(remaining) != 0 do
      :error
    else
      {:ok,
       %Block{
         version: version,
         prev_block: Base.encode16(<<:binary.decode_unsigned(prev_block, :big)::little-size(256)>>, case: :lower),
         merkle_root: Base.encode16(<<:binary.decode_unsigned(merkle_root, :big)::little-size(256)>>, case: :lower),
         timestamp: timestamp,
         bits: bits,
         nonce: nonce,
         txn_count: length(txns),
         txns: txns
       }}
    end
  end
end
