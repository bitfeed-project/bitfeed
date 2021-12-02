defmodule Bitcoinex.Secp256k1.Secp256k1Test do
  use ExUnit.Case
  doctest Bitcoinex.Secp256k1

  alias Bitcoinex.Secp256k1

  @valid_signatures_for_public_key_recovery [
    %{
      message_hash:
        Base.decode16!(
          "CE0677BB30BAA8CF067C88DB9811F4333D131BF8BCF12FE7065D211DCE971008",
          case: :upper
        ),
      signature:
        Base.decode16!(
          "90F27B8B488DB00B00606796D2987F6A5F59AE62EA05EFFE84FEF5B8B0E549984A691139AD57A3F0B906637673AA2F63D1F55CB1A69199D4009EEA23CEADDC93",
          case: :upper
        ),
      recovery_id: 1,
      pubkey: "02e32df42865e97135acfb65f3bae71bdc86f4d49150ad6a440b6f15878109880a"
    },
    %{
      message_hash:
        Base.decode16!(
          "5555555555555555555555555555555555555555555555555555555555555555",
          case: :upper
        ),
      signature:
        Base.decode16!(
          "01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101",
          case: :upper
        ),
      recovery_id: 0,
      pubkey: "02c1ab1d7b32c1adcdab9d378c2ae75ee27822541c6875beed3255f981f0dea378"
    }
  ]

  @invalid_signatures_for_public_key_recovery [
    %{
      # invalid curve point
      message_hash:
        Base.decode16!(
          "00C547E4F7B0F325AD1E56F57E26C745B09A3E503D86E00E5255FF7F715D3D1C",
          case: :upper
        ),
      signature:
        Base.decode16!(
          "00B1693892219D736CABA55BDB67216E485557EA6B6AF75F37096C9AA6A5A75F00B940B1D03B21E36B0E47E79769F095FE2AB855BD91E3A38756B7D75A9C4549",
          case: :upper
        ),
      recovery_id: 0
    },
    %{
      # Low r and s.
      message_hash:
        Base.decode16!(
          "BA09EDC1275A285FB27BFE82C4EEA240A907A0DBAF9E55764B8F318C37D5974F",
          case: :upper
        ),
      signature:
        Base.decode16!(
          "00000000000000000000000000000000000000000000000000000000000000002C0000000000000000000000000000000000000000000000000000000000000004",
          case: :upper
        ),
      recovery_id: 1
    },
    %{
      # invalid signature
      message_hash:
        Base.decode16!(
          "5555555555555555555555555555555555555555555555555555555555555555",
          case: :upper
        ),
      signature:
        Base.decode16!(
          "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          case: :upper
        ),
      recovery_id: 0
    }
  ]

  describe "ecdsa_recover_compact/3" do
    test "successfully recover a public key from a signature" do
      for t <- @valid_signatures_for_public_key_recovery do
        assert {:ok, recovered_pubkey} =
                 Secp256k1.ecdsa_recover_compact(t.message_hash, t.signature, t.recovery_id)

        assert recovered_pubkey == t.pubkey
      end
    end

    test "unsuccessfully recover a public key from a signature" do
      for t <- @invalid_signatures_for_public_key_recovery do
        assert {:error, _error} =
                 Secp256k1.ecdsa_recover_compact(t.message_hash, t.signature, t.recovery_id)
      end
    end
  end
end
