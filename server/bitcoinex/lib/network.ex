defmodule Bitcoinex.Network do
  @moduledoc """
    Includes network-specific paramater options.

    Supported networks include mainnet, testnet3, and regtest.
  """

  @enforce_keys [
    :name,
    :hrp_segwit_prefix,
    :p2pkh_version_decimal_prefix,
    :p2sh_version_decimal_prefix
  ]
  defstruct [
    :name,
    :hrp_segwit_prefix,
    :p2pkh_version_decimal_prefix,
    :p2sh_version_decimal_prefix
  ]

  @type t() :: %__MODULE__{
          name: atom,
          hrp_segwit_prefix: String.t(),
          p2pkh_version_decimal_prefix: integer(),
          p2sh_version_decimal_prefix: integer()
        }

  @type network_name :: :mainnet | :testnet | :regtest

  @doc """
    Returns a list of supported networks.
  """
  def supported_networks() do
    [
      mainnet(),
      testnet(),
      regtest()
    ]
  end

  def mainnet do
    %__MODULE__{
      name: :mainnet,
      hrp_segwit_prefix: "bc",
      p2pkh_version_decimal_prefix: 0,
      p2sh_version_decimal_prefix: 5
    }
  end

  def testnet do
    %__MODULE__{
      name: :testnet,
      hrp_segwit_prefix: "tb",
      p2pkh_version_decimal_prefix: 111,
      p2sh_version_decimal_prefix: 196
    }
  end

  def regtest do
    %__MODULE__{
      name: :regtest,
      hrp_segwit_prefix: "bcrt",
      p2pkh_version_decimal_prefix: 111,
      p2sh_version_decimal_prefix: 196
    }
  end

  @spec get_network(network_name) :: t()
  def get_network(:mainnet) do
    mainnet()
  end

  def get_network(:testnet) do
    testnet()
  end

  def get_network(:regtest) do
    regtest()
  end
end
