defmodule Bitcoinex.Base58 do
  @moduledoc """
    Includes Base58 serialization and validation.

    Some code is inspired by:
    https://github.com/comboy/bitcoin-elixir/blob/develop/lib/bitcoin/base58_check.ex
  """
  alias Bitcoinex.Utils

  @typedoc """
    Base58 encoding is only supported for p2sh and p2pkh address types.  
  """
  @type address_type :: :p2sh | :p2pkh
  @base58_encode_list ~c(123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz)
  @base58_decode_map @base58_encode_list |> Enum.with_index() |> Enum.into(%{})

  @base58_0 <<?1>>
  @type byte_list :: list(byte())

  @doc """
    Decodes a Base58 encoded string into a byte array and validates checksum.
  """
  @spec decode(binary) :: {:ok, binary} | {:error, atom}
  def decode(binary)

  def decode(""), do: {:ok, ""}

  def decode(<<body_and_checksum::binary>>) do
    if valid_charset?(body_and_checksum) do
      body_and_checksum
      |> decode_base!()
      |> validate_checksum()
    else
      {:error, :invalid_characters}
    end
  end

  @doc """
    Decodes a Base58 encoded string into a byte array.
  """
  @spec decode_base!(binary) :: binary
  def decode_base!(binary)

  def decode_base!(@base58_0), do: <<0>>

  def decode_base!(@base58_0 <> body) when byte_size(body) > 0 do
    decode_base!(@base58_0) <> decode_base!(body)
  end

  def decode_base!(""), do: ""

  def decode_base!(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.map(&Map.fetch!(@base58_decode_map, &1))
    |> Integer.undigits(58)
    |> :binary.encode_unsigned()
  end

  @doc """
    Validates a Base58 checksum.
  """
  @spec validate_checksum(binary) :: {:ok, binary} | {:error, atom}
  def validate_checksum(data) do
    [decoded_body, checksum] =
      data
      |> :binary.bin_to_list()
      |> Enum.split(-4)
      |> Tuple.to_list()
      |> Enum.map(&:binary.list_to_bin(&1))

    case checksum == my_binary_slice(Utils.double_sha256(decoded_body), 0..3) do
      false -> {:error, :invalid_checksum}
      true -> {:ok, decoded_body}
    end
  end

  defp valid_charset?(""), do: true

  defp valid_charset?(<<char>> <> string),
    do: char in @base58_encode_list && valid_charset?(string)

  @doc """
    Encodes binary into a Base58 encoded string.
  """
  @spec encode(binary) :: String.t()
  def encode(bin) do
    bin
    |> append_checksum()
    |> encode_base()
  end

  @spec encode_base(binary) :: String.t()
  def encode_base(binary)

  def encode_base(""), do: ""

  def encode_base(<<0>> <> tail) do
    @base58_0 <> encode_base(tail)
  end

  @doc """
    Encodes a binary into a Base58 encoded string.
  """
  def encode_base(bin) do
    bin
    |> :binary.decode_unsigned()
    |> Integer.digits(58)
    |> Enum.map(&Enum.fetch!(@base58_encode_list, &1))
    |> List.to_string()
  end

  @spec append_checksum(binary) :: binary
  defp append_checksum(body) do
    body <> checksum(body)
  end

  @spec checksum(binary) :: binary
  defp checksum(body) do
    body
    |> Utils.double_sha256()
    |> my_binary_slice(0..3)
  end

  @spec my_binary_slice(binary, Range.t()) :: binary
  defp my_binary_slice(data, range) do
    data
    |> :binary.bin_to_list()
    |> Enum.slice(range)
    |> :binary.list_to_bin()
  end
end
