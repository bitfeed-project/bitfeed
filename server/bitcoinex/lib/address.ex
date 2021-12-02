defmodule Bitcoinex.Address do
  @moduledoc """
  Bitcoinex.Address supports Base58 and Bech32 address encoding and validation.
  """

  alias Bitcoinex.{Segwit, Base58, Network}

  @typedoc """
    The address_type describes the address type to use.

    Four address types are supported:
    * p2pkh: Pay-to-Public-Key-Hash
    * p2sh: Pay-to-Script-Hash
    * p2wpkh: Pay-to-Witness-Public-Key-Hash
    * p2wsh: Pay-To-Witness-Script-Hash
  """
  @type address_type :: :p2pkh | :p2sh | :p2wpkh | :p2wsh
  @address_types ~w(p2pkh p2sh p2wpkh p2wsh)a

  @doc """
  Accepts a public key hash, network, and address_type and returns its address.
  """
  @spec encode(binary, Bitcoinex.Network.network_name(), address_type) :: String.t()
  def encode(pubkey_hash, network_name, :p2pkh) do
    network = Network.get_network(network_name)
    decimal_prefix = network.p2pkh_version_decimal_prefix

    Base58.encode(<<decimal_prefix>> <> pubkey_hash)
  end

  def encode(script_hash, network_name, :p2sh) do
    network = Network.get_network(network_name)
    decimal_prefix = network.p2sh_version_decimal_prefix
    Base58.encode(<<decimal_prefix>> <> script_hash)
  end

  @doc """
  Checks if the address is valid.
  Both encoding and network is checked.
  """
  @spec is_valid?(String.t(), Bitcoinex.Network.network_name()) :: boolean
  def is_valid?(address, network_name) do
    Enum.any?(@address_types, &is_valid?(address, network_name, &1))
  end

  @doc """
  Checks if the address is valid and matches the given address_type.
  Both encoding and network is checked.
  """
  @spec is_valid?(String.t(), Bitcoinex.Network.network_name(), address_type) :: boolean
  def is_valid?(address, network_name, :p2pkh) do
    network = apply(Bitcoinex.Network, network_name, [])
    is_valid_base58_check_address?(address, network.p2pkh_version_decimal_prefix)
  end

  def is_valid?(address, network_name, :p2sh) do
    network = apply(Bitcoinex.Network, network_name, [])
    is_valid_base58_check_address?(address, network.p2sh_version_decimal_prefix)
  end

  def is_valid?(address, network_name, :p2wpkh) do
    case Segwit.decode_address(address) do
      {:ok, {^network_name, witness_version, witness_program}}
      when witness_version == 0 and length(witness_program) == 20 ->
        true

      # network is not same as network set in config
      {:ok, {_network_name, _, _}} ->
        false

      {:error, _error} ->
        false
    end
  end

  def is_valid?(address, network_name, :p2wsh) do
    case Segwit.decode_address(address) do
      {:ok, {^network_name, witness_version, witness_program}}
      when witness_version == 0 and length(witness_program) == 32 ->
        true

      # network is not same as network set in config
      {:ok, {_network_name, _, _}} ->
        false

      {:error, _error} ->
        false
    end
  end

  @doc """
  Returns a list of supported address types.
  """
  def supported_address_types() do
    @address_types
  end

  defp is_valid_base58_check_address?(address, valid_prefix) do
    case Base58.decode(address) do
      {:ok, <<^valid_prefix::8, _::binary>>} ->
        true

      _ ->
        false
    end
  end

  @doc """
  Decodes an address and returns the address_type.
  """
  @spec decode_type(String.t(), Bitcoinex.Network.network_name()) ::
          {:ok, address_type} | {:error, :decode_error}
  def decode_type(address, network_name) do
    case Enum.find(@address_types, &is_valid?(address, network_name, &1)) do
      nil -> {:error, :decode_error}
      type -> {:ok, type}
    end
  end
end
