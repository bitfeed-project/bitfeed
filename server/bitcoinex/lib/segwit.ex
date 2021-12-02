defmodule Bitcoinex.Segwit do
  @moduledoc """
  SegWit address serialization.
  """

  alias Bitcoinex.Bech32

  use Bitwise

  @valid_witness_program_length_range 2..40
  @valid_witness_version 0..16
  @supported_network [:mainnet, :testnet, :regtest]

  @type hrp :: String.t()
  @type data :: list(integer)
  # seem no way to use list of atom module attribute in type spec
  @type network :: :testnet | :mainnet | :regtest

  @type witness_version :: 0..16
  @type witness_program :: list(integer)

  @type error :: atom()

  @doc """
    Decodes an address and returns its network, witness version, and witness program.
  """
  @spec decode_address(String.t()) ::
          {:ok, {network, witness_version, witness_program}} | {:error, error}
  def decode_address(address) when is_binary(address) do
    with {_, {:ok, {encoding_type, hrp, data}}} <- {:decode_bech32, Bech32.decode(address)},
         {_, {:ok, network}} <- {:parse_network, parse_network(hrp |> String.to_charlist())},
         {_, {:ok, {version, program}}} <- {:parse_segwit_data, parse_segwit_data(data)} do
      case witness_version_to_bech_encoding(version) do
        ^encoding_type ->
          {:ok, {network, version, program}}

        _ ->
          # encoding type derived from witness version (first byte of data) is different from the code derived from bech32 decoding
          {:error, :invalid_checksum}
      end
    else
      {_, {:error, error}} ->
        {:error, error}
    end
  end

  @doc """
    Encodes an address string.
  """
  @spec encode_address(network, witness_version, witness_program) ::
          {:ok, String.t()} | {:error, error}
  def encode_address(network, _, _) when not (network in @supported_network) do
    {:error, :invalid_network}
  end

  def encode_address(_, witness_version, _)
      when not (witness_version in @valid_witness_version) do
    {:error, :invalid_witness_version}
  end

  def encode_address(network, version, program) do
    with {:ok, converted_program} <- Bech32.convert_bits(program, 8, 5),
         {:is_program_length_valid, true} <-
           {:is_program_length_valid, is_program_length_valid?(version, program)} do
      hrp =
        case network do
          :mainnet ->
            "bc"

          :testnet ->
            "tb"

          :regtest ->
            "bcrt"
        end

      Bech32.encode(hrp, [version | converted_program], witness_version_to_bech_encoding(version))
    else
      {:is_program_length_valid, false} ->
        {:error, :invalid_program_length}

      error ->
        error
    end
  end

  @doc """
  Simpler Interface to check if address is valid
  """
  @spec is_valid_segswit_address?(String.t()) :: boolean
  def is_valid_segswit_address?(address) when is_binary(address) do
    case decode_address(address) do
      {:ok, _} ->
        true

      _ ->
        false
    end
  end

  @spec get_segwit_script_pubkey(witness_version, witness_program) :: String.t()
  def get_segwit_script_pubkey(version, program) do
    # OP_0 is encoded as 0x00, but OP_1 through OP_16 are encoded as 0x51 though 0x60
    wit_version_adjusted = if(version == 0, do: 0, else: version + 0x50)

    [
      wit_version_adjusted,
      Enum.count(program) | program
    ]
    |> :erlang.list_to_binary()
    # to hex and all lower case for better readability
    |> Base.encode16(case: :lower)
  end

  defp parse_segwit_data([]) do
    {:error, :empty_segwit_data}
  end

  defp parse_segwit_data([version | encoded]) when version in @valid_witness_version do
    case Bech32.convert_bits(encoded, 5, 8, false) do
      {:ok, program} ->
        if is_program_length_valid?(version, program) do
          {:ok, {version, program}}
        else
          {:error, :invalid_program_length}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_segwit_data(_), do: {:error, :invalid_witness_version}

  defp is_program_length_valid?(version, program)
       when length(program) in @valid_witness_program_length_range do
    case {version, length(program)} do
      # BIP141 specifies If the version byte is 0, but the witness program is neither 20 nor 32 bytes, the script must fail.
      {0, program_length} when program_length == 20 or program_length == 32 ->
        true

      {0, _} ->
        false

      _ ->
        true
    end
  end

  defp is_program_length_valid?(_, _), do: false

  defp parse_network('bc'), do: {:ok, :mainnet}
  defp parse_network('tb'), do: {:ok, :testnet}
  defp parse_network('bcrt'), do: {:ok, :regtest}
  defp parse_network(_), do: {:error, :invalid_network}

  defp witness_version_to_bech_encoding(0), do: :bech32
  defp witness_version_to_bech_encoding(witver) when witver in 1..16, do: :bech32m
end
