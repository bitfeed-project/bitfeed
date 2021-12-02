Forked from RiverFinancial/bitcoinex
original README as follows:

![Bitcoinex](https://user-images.githubusercontent.com/8378656/102842648-4f671380-43bc-11eb-8e0d-72c2a107e5ed.png)
# Bitcoinex

Bitcoinex is striving to be the best and most up-to-date Bitcoin Library for Elixir.

## Documentation
Documentation is available on [hexdocs.pm](https://hexdocs.pm/bitcoinex/api-reference.html).

## Current Utilities
* Serialization and validation for Bech32 and Base58.
* Support for standard on-chain scripts (P2PKH..P2WPKH) and Bolt#11 Lightning Invoices.
* Transaction serialization.
* Basic PSBT (BIP174) parsing.

## Usage

With [Hex](https://hex.pm/packages/bitcoinex):

    {:bitcoinex, "~> 0.1.0"}

Local:

    $ mix deps.get
    $ mix compile

## Examples

Decode a Lightning Network invoice:

  ```elixir
  Bitcoinex.LightningNetwork.decode_invoice("lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp")

  {:ok,
    %Bitcoinex.LightningNetwork.Invoice{
      amount_msat: 250000000,
      description: "1 cup coffee",
      description_hash: nil,
      destination: "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad",
      expiry: 60,
      fallback_address: nil,
      min_final_cltv_expiry: 18,
      network: :mainnet,
      payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
      route_hints: [],
      timestamp: 1496314658
    }}
  ```

Parse a BIP-174 Partially Signed Bitcoin Transaction:

  ```elixir
  Bitcoinex.PSBT.decode("cHNidP8BAFUCAAAAASeaIyOl37UfxF8iD6WLD8E+HjNCeSqF1+Ns1jM7XLw5AAAAAAD/////AaBa6gsAAAAAGXapFP/pwAYQl8w7Y28ssEYPpPxCfStFiKwAAAAAAAEBIJVe6gsAAAAAF6kUY0UgD2jRieGtwN8cTRbqjxTA2+uHIgIDsTQcy6doO2r08SOM1ul+cWfVafrEfx5I1HVBhENVvUZGMEMCIAQktY7/qqaU4VWepck7v9SokGQiQFXN8HC2dxRpRC0HAh9cjrD+plFtYLisszrWTt5g6Hhb+zqpS5m9+GFR25qaAQEEIgAgdx/RitRZZm3Unz1WTj28QvTIR3TjYK2haBao7UiNVoEBBUdSIQOxNBzLp2g7avTxI4zW6X5xZ9Vp+sR/HkjUdUGEQ1W9RiED3lXR4drIBeP4pYwfv5uUwC89uq/hJ/78pJlfJvggg71SriIGA7E0HMunaDtq9PEjjNbpfnFn1Wn6xH8eSNR1QYRDVb1GELSmumcAAACAAAAAgAQAAIAiBgPeVdHh2sgF4/iljB+/m5TALz26r+En/vykmV8m+CCDvRC0prpnAAAAgAAAAIAFAACAAAA=")

  {:ok,
    %Bitcoinex.PSBT{
     global: %Bitcoinex.PSBT.Global{
       proprietary: nil,
       unsigned_tx: %Bitcoinex.Transaction{...},
     inputs: [
       %Bitcoinex.PSBT.In{
         bip32_derivation: [
           %{
             derivation: "b4a6ba67000000800000008004000080",
             public_key: "03b1341ccba7683b6af4f1238cd6e97e7167d569fac47f1e48d47541844355bd46"
           },
           %{
             derivation: "b4a6ba67000000800000008005000080",
             public_key: "03de55d1e1dac805e3f8a58c1fbf9b94c02f3dbaafe127fefca4995f26f82083bd"
           }
         ],
         final_scriptsig: nil,
         final_scriptwitness: nil,
         non_witness_utxo: nil,
         partial_sig: %{
           public_key: "03b1341ccba7683b6af4f1238cd6e97e7167d569fac47f1e48d47541844355bd46",
           signature: "304302200424b58effaaa694e1559ea5c93bbfd4a89064224055cdf070b6771469442d07021f5c8eb0fea6516d60b8acb33ad64ede60e8785bfb3aa94b99bdf86151db9a9a01"
         },
         por_commitment: nil,
         proprietary: nil,
         redeem_script: "0020771fd18ad459666dd49f3d564e3dbc42f4c84774e360ada16816a8ed488d5681",
         sighash_type: nil,
         witness_script: "522103b1341ccba7683b6af4f1238cd6e97e7167d569fac47f1e48d47541844355bd462103de55d1e1dac805e3f8a58c1fbf9b94c02f3dbaafe127fefca4995f26f82083bd52ae",
         witness_utxo: %Bitcoinex.Transaction.Out{
           script_pub_key: "a9146345200f68d189e1adc0df1c4d16ea8f14c0dbeb87",
           value: 199909013
         }
       }
     ],
     outputs: []
    }}
 ```


Handle bitcoin addresses:

  ```elixir
  {:ok, {:mainnet, witness_version, witness_program}} = Bitcoinex.Segwit.decode_address("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4")

  Bitcoinex.Segwit.encode_address(:mainnet, witness_version, witness_program)

  {:ok, "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"}
  ```

## Roadmap
Continued support for on-chain and off-chain functionality including:
* Full script support including validation.
* Block serialization.
* Transaction creation.
* Broader BIP support including BIP32.

## Contributing
We have big goals and this library is still in a very early stage. Contributions and comments are very much welcome.
