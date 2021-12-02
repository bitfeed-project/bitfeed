defmodule Bitcoinex.Secp256k1.PointTest do
  use ExUnit.Case
  doctest Bitcoinex.Secp256k1.Point

  alias Bitcoinex.Secp256k1.Point

  describe "serialize_public_key/1" do
    test "successfully pad public key" do
      assert "020003b94aecea4d0a57a6c87cf43c50c8b3736f33ab7fd34f02441b6e94477689" ==
               Point.serialize_public_key(%Point{
                 x:
                   6_579_384_254_631_425_969_190_483_614_785_133_746_155_874_651_439_631_590_927_590_192_220_436_105,
                 y:
                   71_870_263_570_581_286_056_939_190_487_148_011_225_641_308_782_404_760_504_903_461_107_415_970_265_024
               })
    end
  end
end
