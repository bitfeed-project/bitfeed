defmodule Bitcoinex.Transaction do
  @moduledoc """
  Bitcoin on-chain transaction structure.
  Supports serialization of transactions.
  """
  alias Bitcoinex.Transaction
  alias Bitcoinex.Transaction.In
  alias Bitcoinex.Transaction.Out
  alias Bitcoinex.Transaction.Witness
  alias Bitcoinex.Utils
  alias Bitcoinex.Transaction.Utils, as: TxUtils

  defstruct [
    :version,
    :vbytes,
    :inputs,
    :outputs,
    :witnesses,
    :lock_time
  ]

  @doc """
    Returns the TxID of the given transaction.

    TxID is sha256(sha256(nVersion | txins | txouts | nLockTime))
  """
  def transaction_id(txn) do
    legacy_txn = TxUtils.serialize_legacy(txn)
    {:ok, legacy_txn} = Base.decode16(legacy_txn, case: :lower)

    Base.encode16(
      <<:binary.decode_unsigned(
          Utils.double_sha256(legacy_txn),
          :big
        )::little-size(256)>>,
      case: :lower
    )
  end

  @doc """
    Decodes a transaction in a hex encoded string into binary.
  """
  def decode(tx_hex) when is_binary(tx_hex) do
    case Base.decode16(tx_hex, case: :lower) do
      {:ok, tx_bytes} ->
        case parse(tx_bytes) do
          {:ok, txn} ->
            {:ok, txn}

          :error ->
            {:error, :parse_error}
        end

      :error ->
        {:error, :decode_error}
    end
  end

  # Extracts and parses a transaction from the head of a binary
  defp parse_one(tx_bytes) do
    <<version::little-size(32), remaining::binary>> = tx_bytes

    {is_segwit, remaining} =
      case remaining do
        <<1::size(16), segwit_remaining::binary>> ->
          {:segwit, segwit_remaining}

        _ ->
          {:not_segwit, remaining}
      end

    # Inputs.
    {in_counter, remaining} = TxUtils.get_counter(remaining)
    {inputs, remaining} = In.parse_inputs(in_counter, remaining)

    # Outputs.
    {out_counter, remaining} = TxUtils.get_counter(remaining)
    {outputs, remaining} = Out.parse_outputs(out_counter, remaining)

    before_witness_bytes = byte_size(remaining)

    # If flag 0001 is present, this indicates an attached segregated witness structure.
    {witnesses, remaining} =
      if is_segwit == :segwit do
        Witness.parse_witness(in_counter, remaining)
      else
        {nil, remaining}
      end

    # discounted witness bytes = all of the witness segment
    # plus segwit marker & segwit flag bytes
    witness_byte_size = 2 + before_witness_bytes - byte_size(remaining)

    <<lock_time::little-size(32), remaining::binary>> = remaining

    initial_byte_size = byte_size(tx_bytes)
    remaining_byte_size = byte_size(remaining)
    total_byte_size = initial_byte_size - remaining_byte_size

    # calculate size in vbytes
    vbytes =
      if is_segwit == :segwit do
        non_witness_byte_size = total_byte_size - witness_byte_size
        non_witness_byte_size + (witness_byte_size / 4)
      else
        total_byte_size
      end

    txn = %Transaction{
      version: version,
      vbytes: vbytes,
      inputs: inputs,
      outputs: outputs,
      witnesses: witnesses,
      lock_time: lock_time
    }

    cond do
      byte_size(remaining) < 0 ->
        :error

      byte_size(remaining) > 0 ->
        {:ok, txn, remaining}

      true ->
        {:ok, txn}
    end
  end

  # returns transaction
  defp parse(tx_bytes) do
    case (parse_one(tx_bytes)) do
      {:ok, txn} ->
          {:ok, txn}

      {:ok, _txn, _remaining} ->
          :error

      :error ->
          :error
    end
  end

  def parse_list(counter, txns), do: do_parse_list(txns, [], counter)

  defp do_parse_list(remaining, txns, 0), do: {Enum.reverse(txns), remaining}

  defp do_parse_list(remaining, txns, count) do
    case parse_one(remaining) do
      {:ok, txn} ->
        do_parse_list(<<>>, [txn | txns], count - 1)

      {:ok, txn, remaining} ->
        do_parse_list(remaining, [txn | txns], count - 1)
    end
  end
end

defmodule Bitcoinex.Transaction.Utils do
  @moduledoc """
  Utilities for when dealing with transaction objects.
  """
  alias Bitcoinex.Transaction.In
  alias Bitcoinex.Transaction.Out

  @doc """
    Returns the Variable Length Integer used in serialization.

    Reference: https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer
  """
  @spec get_counter(binary) :: {non_neg_integer(), binary()}
  def get_counter(<<counter::little-size(8), vec::binary>>) do
    case counter do
      # 0xFD followed by the length as uint16_t
      0xFD ->
        <<len::little-size(16), vec::binary>> = vec
        {len, vec}

      # 0xFE followed by the length as uint32_t
      0xFE ->
        <<len::little-size(32), vec::binary>> = vec
        {len, vec}

      # 0xFF followed by the length as uint64_t
      0xFF ->
        <<len::little-size(64), vec::binary>> = vec
        {len, vec}

      _ ->
        {counter, vec}
    end
  end

  @doc """
    Serializes a transaction without the witness structure.
  """
  def serialize_legacy(txn) do
    version = <<txn.version::little-size(32)>>
    tx_in_count = serialize_compact_size_unsigned_int(length(txn.inputs))
    inputs = In.serialize_inputs(txn.inputs)
    tx_out_count = serialize_compact_size_unsigned_int(length(txn.outputs))
    outputs = Out.serialize_outputs(txn.outputs)
    lock_time = <<txn.lock_time::little-size(32)>>

    Base.encode16(
      version <>
        tx_in_count <>
        inputs <>
        tx_out_count <>
        outputs <>
        lock_time,
      case: :lower
    )
  end

  @doc """
    Returns the serialized variable length integer.
  """
  def serialize_compact_size_unsigned_int(compact_size) do
    cond do
      compact_size >= 0 and compact_size <= 0xFC ->
        <<compact_size::little-size(8)>>

      compact_size <= 0xFFFF ->
        <<0xFD>> <> <<compact_size::little-size(16)>>

      compact_size <= 0xFFFFFFFF ->
        <<0xFE>> <> <<compact_size::little-size(32)>>

      compact_size <= 0xFF ->
        <<0xFF>> <> <<compact_size::little-size(64)>>
    end
  end
end

defmodule Bitcoinex.Transaction.Witness do
  @moduledoc """
  Witness structure part of an on-chain transaction.
  """
  alias Bitcoinex.Transaction.Witness
  alias Bitcoinex.Transaction.Utils, as: TxUtils

  defstruct [
    :txinwitness
  ]

  @doc """
    Wtiness accepts a binary and deserializes it.
  """
  @spec witness(binary) :: %Bitcoinex.Transaction.Witness{
          :txinwitness => [any()] | 0
        }
  def witness(witness_bytes) do
    {stack_size, witness_bytes} = TxUtils.get_counter(witness_bytes)

    {witness, _} =
      if stack_size == 0 do
        {%Witness{txinwitness: 0}, witness_bytes}
      else
        {stack_items, witness_bytes} = parse_stack(witness_bytes, [], stack_size)
        {%Witness{txinwitness: stack_items}, witness_bytes}
      end

    witness
  end

  def parse_witness(0, remaining), do: {nil, remaining}

  def parse_witness(counter, witnesses) do
    parse(witnesses, [], counter)
  end

  defp parse(remaining, witnesses, 0), do: {Enum.reverse(witnesses), remaining}

  defp parse(remaining, witnesses, count) do
    {stack_size, remaining} = TxUtils.get_counter(remaining)

    {witness, remaining} =
      if stack_size == 0 do
        {%Witness{txinwitness: 0}, remaining}
      else
        {stack_items, remaining} = parse_stack(remaining, [], stack_size)
        {%Witness{txinwitness: stack_items}, remaining}
      end

    parse(remaining, [witness | witnesses], count - 1)
  end

  defp parse_stack(remaining, stack_items, 0), do: {Enum.reverse(stack_items), remaining}

  defp parse_stack(remaining, stack_items, stack_size) do
    {item_size, remaining} = TxUtils.get_counter(remaining)

    <<stack_item::binary-size(item_size), remaining::binary>> = remaining

    parse_stack(
      remaining,
      [Base.encode16(stack_item, case: :lower) | stack_items],
      stack_size - 1
    )
  end
end

defmodule Bitcoinex.Transaction.In do
  @moduledoc """
  Transaction Input part of an on-chain transaction.
  """
  alias Bitcoinex.Transaction.In
  alias Bitcoinex.Transaction.Utils, as: TxUtils

  defstruct [
    :prev_txid,
    :prev_vout,
    :script_sig,
    :sequence_no
  ]

  def serialize_inputs(inputs) do
    serialize_input(inputs, <<""::binary>>)
  end

  defp serialize_input([], serialized_inputs), do: serialized_inputs

  defp serialize_input(inputs, serialized_inputs) do
    [input | inputs] = inputs

    {:ok, prev_txid} = Base.decode16(input.prev_txid, case: :lower)

    prev_txid =
      prev_txid
      |> :binary.decode_unsigned(:big)
      |> :binary.encode_unsigned(:little)
      |> Bitcoinex.Utils.pad(32, :trailing)

    {:ok, script_sig} = Base.decode16(input.script_sig, case: :lower)

    script_len = TxUtils.serialize_compact_size_unsigned_int(byte_size(script_sig))

    serialized_input =
      prev_txid <>
        <<input.prev_vout::little-size(32)>> <>
        script_len <> script_sig <> <<input.sequence_no::little-size(32)>>

    serialize_input(inputs, <<serialized_inputs::binary>> <> serialized_input)
  end

  def parse_inputs(counter, inputs) do
    parse(inputs, [], counter)
  end

  defp parse(remaining, inputs, 0), do: {Enum.reverse(inputs), remaining}

  defp parse(
         <<prev_txid::binary-size(32), prev_vout::little-size(32), remaining::binary>>,
         inputs,
         count
       ) do
    {script_len, remaining} = TxUtils.get_counter(remaining)

    <<script_sig::binary-size(script_len), sequence_no::little-size(32), remaining::binary>> =
      remaining

    input = %In{
      prev_txid:
        Base.encode16(<<:binary.decode_unsigned(prev_txid, :big)::little-size(256)>>, case: :lower),
      prev_vout: prev_vout,
      script_sig: Base.encode16(script_sig, case: :lower),
      sequence_no: sequence_no
    }

    parse(remaining, [input | inputs], count - 1)
  end
end

defmodule Bitcoinex.Transaction.Out do
  @moduledoc """
  Transaction Output part of an on-chain transaction.
  """
  alias Bitcoinex.Transaction.Out
  alias Bitcoinex.Transaction.Utils, as: TxUtils

  defstruct [
    :value,
    :script_pub_key
  ]

  def serialize_outputs(outputs) do
    serialize_output(outputs, <<""::binary>>)
  end

  defp serialize_output([], serialized_outputs), do: serialized_outputs

  defp serialize_output(outputs, serialized_outputs) do
    [output | outputs] = outputs

    {:ok, script_pub_key} = Base.decode16(output.script_pub_key, case: :lower)

    script_len = TxUtils.serialize_compact_size_unsigned_int(byte_size(script_pub_key))

    serialized_output = <<output.value::little-size(64)>> <> script_len <> script_pub_key
    serialize_output(outputs, <<serialized_outputs::binary>> <> serialized_output)
  end

  def output(out_bytes) do
    <<value::little-size(64), out_bytes::binary>> = out_bytes
    {script_len, out_bytes} = TxUtils.get_counter(out_bytes)
    <<script_pub_key::binary-size(script_len), _::binary>> = out_bytes
    %Out{value: value, script_pub_key: Base.encode16(script_pub_key, case: :lower)}
  end

  def parse_outputs(counter, outputs) do
    parse(outputs, [], counter)
  end

  defp parse(remaining, outputs, 0), do: {Enum.reverse(outputs), remaining}

  defp parse(<<value::little-size(64), remaining::binary>>, outputs, count) do
    {script_len, remaining} = TxUtils.get_counter(remaining)

    <<script_pub_key::binary-size(script_len), remaining::binary>> = remaining

    output = %Out{
      value: value,
      script_pub_key: Base.encode16(script_pub_key, case: :lower)
    }

    parse(remaining, [output | outputs], count - 1)
  end
end
