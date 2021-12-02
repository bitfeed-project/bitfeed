defmodule Bitcoinex.Network do
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
end
