defmodule Bitcoinex.SegwitTest do
  use ExUnit.Case
  doctest Bitcoinex.Segwit

  alias Bitcoinex.Segwit
  import Bitcoinex.Utils, only: [replicate: 2]

  @valid_segwit_address_hexscript_pairs_mainnet [
    {"BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4",
     "0014751e76e8199196d454941c45d1b3a323f1433bd6"},
    {"bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kt5nd6y",
     "5128751e76e8199196d454941c45d1b3a323f1433bd6751e76e8199196d454941c45d1b3a323f1433bd6"},
    {"BC1SW50QGDZ25J", "6002751e"},
    {"bc1zw508d6qejxtdg4y5r3zarvaryvaxxpcs", "5210751e76e8199196d454941c45d1b3a323"},
    {"bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0",
     "512079be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"}
  ]

  @valid_segwit_address_hexscript_pairs_testnet [
    {"tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7",
     "00201863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262"},
    {"tb1pqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesf3hn0c",
     "5120000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433"},
    {"tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy",
     "0020000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433"}
  ]

  @valid_segwit_address_hexscript_pairs_regtest [
    {"bcrt1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qzf4jry",
     "00201863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262"},
    {"bcrt1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvseswlauz7",
     "0020000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433"}
  ]

  @invalid_segwit_addresses [
    "tc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vq5zuyut",
    "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqh2y7hd",
    "tb1z0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqglt7rf",
    "BC1S0XLXVLHEMJA6C4DQV22UAPCTQUPFHLXM9H8Z3K2E72Q4K9HCZ7VQ54WELL",
    "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kemeawh",
    "tb1q0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vq24jc47",
    "bc1p38j9r5y49hruaue7wxjce0updqjuyyx0kh56v8s25huc6995vvpql3jow4",
    "BC130XLXVLHEMJA6C4DQV22UAPCTQUPFHLXM9H8Z3K2E72Q4K9HCZ7VQ7ZWS8R",
    "bc1pw5dgrnzv",
    "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7v8n0nx0muaewav253zgeav",
    "tc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty",
    "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5",
    "BC13W508D6QEJXTDG4Y5R3ZARVARY0C5XW7KN40WF2",
    "tb1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vq47Zagq",
    "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7v07qwwzcrf",
    "tb1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vpggkg4j",
    "bc1rw5uspcuh",
    "bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90",
    "BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P",
    "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7",
    "bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du",
    "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv",
    "bc1gmk9yu"
  ]

  describe "decode/1" do
    test "successfully decode with valid segwit addresses in mainnet" do
      for {address, hexscript} <- @valid_segwit_address_hexscript_pairs_mainnet do
        assert_valid_segwit_address(address, hexscript, :mainnet)
      end
    end

    test "successfully decode with valid segwit addresses in testnet" do
      for {address, hexscript} <- @valid_segwit_address_hexscript_pairs_testnet do
        assert_valid_segwit_address(address, hexscript, :testnet)
      end
    end

    test "successfully decode with valid segwit addresses in regtest" do
      for {address, hexscript} <- @valid_segwit_address_hexscript_pairs_regtest do
        assert_valid_segwit_address(address, hexscript, :regtest)
      end
    end

    test "fail to decode with invalid address" do
      for address <- @invalid_segwit_addresses do
        assert {:error, _error} = Segwit.decode_address(address)
      end
    end
  end

  describe "encode_address/1" do
    test "successfully encode with valid netwrok, version and program " do
      version = 1
      program = replicate(1, 10)
      assert {:ok, mainnet_address} = Segwit.encode_address(:mainnet, version, program)
      assert {:ok, testnet_address} = Segwit.encode_address(:testnet, version, program)
      assert {:ok, regtest_address} = Segwit.encode_address(:regtest, version, program)
      all_addresses = [mainnet_address, testnet_address, regtest_address]
      # make sure they are different
      assert Enum.uniq(all_addresses) == all_addresses
    end

    test "fail to encode with program length > 40 " do
      assert {:error, _error} = Segwit.encode_address(:mainnet, 1, replicate(1, 41))
    end

    test "fail to encode with version 0 but program length not equalt to 20 or 32 " do
      assert {:ok, _address} = Segwit.encode_address(:mainnet, 0, replicate(1, 20))
      assert {:ok, _address} = Segwit.encode_address(:mainnet, 0, replicate(1, 32))
      assert {:error, _error} = Segwit.encode_address(:mainnet, 0, replicate(1, 21))
      assert {:error, _error} = Segwit.encode_address(:mainnet, 0, replicate(1, 33))
    end
  end

  describe "is_valid_segswit_address?/1" do
    test "return true given valid address" do
      for {address, _hexscript} <-
            @valid_segwit_address_hexscript_pairs_mainnet ++
              @valid_segwit_address_hexscript_pairs_testnet ++
              @valid_segwit_address_hexscript_pairs_regtest do
        assert Segwit.is_valid_segswit_address?(address)
      end
    end

    test "return false given invalid address" do
      for address <- @invalid_segwit_addresses do
        refute Segwit.is_valid_segswit_address?(address)
      end
    end
  end

  # local private test helper
  defp assert_valid_segwit_address(address, hexscript, network) do
    assert {:ok, {hrp, version, program}} = Segwit.decode_address(address)
    assert hrp == network
    assert version in 0..16
    assert Segwit.get_segwit_script_pubkey(version, program) == hexscript

    # encode after decode should be the same(after downcase) as before
    {:ok, new_address} = Segwit.encode_address(hrp, version, program)
    assert new_address == String.downcase(address)
  end
end
