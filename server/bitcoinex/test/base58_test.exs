defmodule Bitcoinex.Base58Test do
  use ExUnit.Case
  use ExUnitProperties
  doctest Bitcoinex.Base58

  alias Bitcoinex.Base58

  # From
  @base58_encode_decode [
    ["", ""],
    ["61", "2g"],
    ["626262", "a3gV"],
    ["636363", "aPEr"],
    ["73696d706c792061206c6f6e6720737472696e67", "2cFupjhnEsSn59qHXstmK2ffpLv2"],
    ["00eb15231dfceb60925886b67d065299925915aeb172c06647", "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"],
    ["516b6fcd0f", "ABnLTmg"],
    ["bf4f89001e670274dd", "3SEo3LWLoPntC"],
    ["572e4794", "3EFU7m"],
    ["ecac89cad93923c02321", "EJDM8drfXA6uyA"],
    ["10c8511e", "Rt5zm"],
    ["00000000000000000000", "1111111111"],
    [
      "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
      "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    ],
    [
      "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
      "1cWB5HCBdLjAuqGGReWE3R3CguuwSjw6RHn39s2yuDRTS5NsBgNiFpWgAnEx6VQi8csexkgYw3mdYrMHr8x9i7aEwP8kZ7vccXWqKDvGv3u1GxFKPuAkn8JCPPGDMf3vMMnbzm6Nh9zh1gcNsMvH3ZNLmP5fSG6DGbbi2tuwMWPthr4boWwCxf7ewSgNQeacyozhKDDQQ1qL5fQFUW52QKUZDZ5fw3KXNQJMcNTcaB723LchjeKun7MuGW5qyCBZYzA1KjofN1gYBV3NqyhQJ3Ns746GNuf9N2pQPmHz4xpnSrrfCvy6TVVz5d4PdrjeshsWQwpZsZGzvbdAdN8MKV5QsBDY"
    ]
  ]

  # From https://github.com/bitcoinjs/bs58check/blob/master/test/fixtures.json
  @valid_base58_strings [
    ["1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62i", "0065a16059864a2fdbc7c99a4723a8395bc6f188eb"],
    ["3CMNFxN1oHBc4R1EpboAL5yzHGgE611Xou", "0574f209f6ea907e2ea48f74fae05782ae8a665257"],
    ["mo9ncXisMeAoXwqcV5EWuyncbmCcQN4rVs", "6f53c0307d6851aa0ce7825ba883c6bd9ad242b486"],
    ["2N2JD6wb56AfK4tfmM6PwdVmoYk2dCKf4Br", "c46349a418fc4578d10a372b54b45c280cc8c4382f"],
    [
      "5Kd3NBUAdUnhyzenEwVLy9pBKxSwXvE9FMPyR4UKZvpe6E3AgLr",
      "80eddbdc1168f1daeadbd3e44c1e3f8f5a284c2029f78ad26af98583a499de5b19"
    ],
    [
      "Kz6UJmQACJmLtaQj5A3JAge4kVTNQ8gbvXuwbmCj7bsaabudb3RD",
      "8055c9bccb9ed68446d1b75273bbce89d7fe013a8acd1625514420fb2aca1a21c401"
    ],
    [
      "9213qJab2HNEpMpYNBa7wHGFKKbkDn24jpANDs2huN3yi4J11ko",
      "ef36cb93b9ab1bdabf7fb9f2c04f1b9cc879933530ae7842398eef5a63a56800c2"
    ],
    [
      "cTpB4YiyKiBcPxnefsDpbnDxFDffjqJob8wGCEDXxgQ7zQoMXJdH",
      "efb9f4892c9e8282028fea1d2667c4dc5213564d41fc5783896a0d843fc15089f301"
    ],
    ["1Ax4gZtb7gAit2TivwejZHYtNNLT18PUXJ", "006d23156cbbdcc82a5a47eee4c2c7c583c18b6bf4"],
    ["3QjYXhTkvuj8qPaXHTTWb5wjXhdsLAAWVy", "05fcc5460dd6e2487c7d75b1963625da0e8f4c5975"],
    ["n3ZddxzLvAY9o7184TB4c6FJasAybsw4HZ", "6ff1d470f9b02370fdec2e6b708b08ac431bf7a5f7"],
    ["2NBFNJTktNa7GZusGbDbGKRZTxdK9VVez3n", "c4c579342c2c4c9220205e2cdc285617040c924a0a"],
    [
      "5K494XZwps2bGyeL71pWid4noiSNA2cfCibrvRWqcHSptoFn7rc",
      "80a326b95ebae30164217d7a7f57d72ab2b54e3be64928a19da0210b9568d4015e"
    ],
    [
      "L1RrrnXkcKut5DEMwtDthjwRcTTwED36thyL1DebVrKuwvohjMNi",
      "807d998b45c219a1e38e99e7cbd312ef67f77a455a9b50c730c27f02c6f730dfb401"
    ],
    [
      "93DVKyFYwSN6wEo3E2fCrFPUp17FtrtNi2Lf7n4G3garFb16CRj",
      "efd6bca256b5abc5602ec2e1c121a08b0da2556587430bcf7e1898af2224885203"
    ],
    [
      "cTDVKtMGVYWTHCb1AFjmVbEbWjvKpKqKgMaR3QJxToMSQAhmCeTN",
      "efa81ca4e8f90181ec4b61b6a7eb998af17b2cb04de8a03b504b9e34c4c61db7d901"
    ],
    ["1C5bSj1iEGUgSTbziymG7Cn18ENQuT36vv", "007987ccaa53d02c8873487ef919677cd3db7a6912"],
    ["3AnNxabYGoTxYiTEZwFEnerUoeFXK2Zoks", "0563bcc565f9e68ee0189dd5cc67f1b0e5f02f45cb"],
    ["n3LnJXCqbPjghuVs8ph9CYsAe4Sh4j97wk", "6fef66444b5b17f14e8fae6e7e19b045a78c54fd79"],
    ["2NB72XtkjpnATMggui83aEtPawyyKvnbX2o", "c4c3e55fceceaa4391ed2a9677f4a4d34eacd021a0"],
    [
      "5KaBW9vNtWNhc3ZEDyNCiXLPdVPHCikRxSBWwV9NrpLLa4LsXi9",
      "80e75d936d56377f432f404aabb406601f892fd49da90eb6ac558a733c93b47252"
    ],
    [
      "L1axzbSyynNYA8mCAhzxkipKkfHtAXYF4YQnhSKcLV8YXA874fgT",
      "808248bd0375f2f75d7e274ae544fb920f51784480866b102384190b1addfbaa5c01"
    ],
    [
      "927CnUkUbasYtDwYwVn2j8GdTuACNnKkjZ1rpZd2yBB1CLcnXpo",
      "ef44c4f6a096eac5238291a94cc24c01e3b19b8d8cef72874a079e00a242237a52"
    ],
    [
      "cUcfCMRjiQf85YMzzQEk9d1s5A4K7xL5SmBCLrezqXFuTVefyhY7",
      "efd1de707020a9059d6d3abaf85e17967c6555151143db13dbb06db78df0f15c6901"
    ],
    ["1Gqk4Tv79P91Cc1STQtU3s1W6277M2CVWu", "00adc1cc2081a27206fae25792f28bbc55b831549d"],
    ["33vt8ViH5jsr115AGkW6cEmEz9MpvJSwDk", "05188f91a931947eddd7432d6e614387e32b244709"],
    ["mhaMcBxNh5cqXm4aTQ6EcVbKtfL6LGyK2H", "6f1694f5bc1a7295b600f40018a618a6ea48eeb498"],
    ["2MxgPqX1iThW3oZVk9KoFcE5M4JpiETssVN", "c43b9b3fd7a50d4f08d1a5b0f62f644fa7115ae2f3"],
    [
      "5HtH6GdcwCJA4ggWEL1B3jzBBUB8HPiBi9SBc5h9i4Wk4PSeApR",
      "80091035445ef105fa1bb125eccfb1882f3fe69592265956ade751fd095033d8d0"
    ],
    [
      "L2xSYmMeVo3Zek3ZTsv9xUrXVAmrWxJ8Ua4cw8pkfbQhcEFhkXT8",
      "80ab2b4bcdfc91d34dee0ae2a8c6b6668dadaeb3a88b9859743156f462325187af01"
    ],
    [
      "92xFEve1Z9N8Z641KQQS7ByCSb8kGjsDzw6fAmjHN1LZGKQXyMq",
      "efb4204389cef18bbe2b353623cbf93e8678fbc92a475b664ae98ed594e6cf0856"
    ],
    [
      "cVM65tdYu1YK37tNoAyGoJTR13VBYFva1vg9FLuPAsJijGvG6NEA",
      "efe7b230133f1b5489843260236b06edca25f66adb1be455fbd38d4010d48faeef01"
    ],
    ["1JwMWBVLtiqtscbaRHai4pqHokhFCbtoB4", "00c4c1b72491ede1eedaca00618407ee0b772cad0d"],
    ["3QCzvfL4ZRvmJFiWWBVwxfdaNBT8EtxB5y", "05f6fe69bcb548a829cce4c57bf6fff8af3a5981f9"],
    ["mizXiucXRCsEriQCHUkCqef9ph9qtPbZZ6", "6f261f83568a098a8638844bd7aeca039d5f2352c0"],
    ["2NEWDzHWwY5ZZp8CQWbB7ouNMLqCia6YRda", "c4e930e1834a4d234702773951d627cce82fbb5d2e"],
    [
      "5KQmDryMNDcisTzRp3zEq9e4awRmJrEVU1j5vFRTKpRNYPqYrMg",
      "80d1fab7ab7385ad26872237f1eb9789aa25cc986bacc695e07ac571d6cdac8bc0"
    ],
    [
      "L39Fy7AC2Hhj95gh3Yb2AU5YHh1mQSAHgpNixvm27poizcJyLtUi",
      "80b0bbede33ef254e8376aceb1510253fc3550efd0fcf84dcd0c9998b288f166b301"
    ],
    [
      "91cTVUcgydqyZLgaANpf1fvL55FH53QMm4BsnCADVNYuWuqdVys",
      "ef037f4192c630f399d9271e26c575269b1d15be553ea1a7217f0cb8513cef41cb"
    ],
    [
      "cQspfSzsgLeiJGB2u8vrAiWpCU4MxUT6JseWo2SjXy4Qbzn2fwDw",
      "ef6251e205e8ad508bab5596bee086ef16cd4b239e0cc0c5d7c4e6035441e7d5de01"
    ],
    ["19dcawoKcZdQz365WpXWMhX6QCUpR9SY4r", "005eadaf9bb7121f0f192561a5a62f5e5f54210292"],
    ["37Sp6Rv3y4kVd1nQ1JV5pfqXccHNyZm1x3", "053f210e7277c899c3a155cc1c90f4106cbddeec6e"],
    ["myoqcgYiehufrsnnkqdqbp69dddVDMopJu", "6fc8a3c2a09a298592c3e180f02487cd91ba3400b5"],
    ["2N7FuwuUuoTBrDFdrAZ9KxBmtqMLxce9i1C", "c499b31df7c9068d1481b596578ddbb4d3bd90baeb"],
    [
      "5KL6zEaMtPRXZKo1bbMq7JDjjo1bJuQcsgL33je3oY8uSJCR5b4",
      "80c7666842503db6dc6ea061f092cfb9c388448629a6fe868d068c42a488b478ae"
    ],
    [
      "KwV9KAfwbwt51veZWNscRTeZs9CKpojyu1MsPnaKTF5kz69H1UN2",
      "8007f0803fc5399e773555ab1e8939907e9badacc17ca129e67a2f5f2ff84351dd01"
    ],
    [
      "93N87D6uxSBzwXvpokpzg8FFmfQPmvX4xHoWQe3pLdYpbiwT5YV",
      "efea577acfb5d1d14d3b7b195c321566f12f87d2b77ea3a53f68df7ebf8604a801"
    ],
    [
      "cMxXusSihaX58wpJ3tNuuUcZEQGt6DKJ1wEpxys88FFaQCYjku9h",
      "ef0b3b34f0958d8a268193a9814da92c3e8b58b4a4378a542863e34ac289cd830c01"
    ],
    ["13p1ijLwsnrcuyqcTvJXkq2ASdXqcnEBLE", "001ed467017f043e91ed4c44b4e8dd674db211c4e6"],
    ["3ALJH9Y951VCGcVZYAdpA3KchoP9McEj1G", "055ece0cadddc415b1980f001785947120acdb36fc"]
  ]

  @invalid_base58_strings [
    ["Z9inZq4e2HGQRZQezDjFMmqgUE8NwMRok", "Invalid checksum"],
    ["3HK7MezAm6qEZQUMPRf8jX7wDv6zig6Ky8", "Invalid checksum"],
    ["3AW8j12DUk8mgA7kkfZ1BrrzCVFuH1LsXS", "Invalid checksum"]
    # ["#####", "Non-base58 character"] # TODO: handle gracefully
  ]

  describe "decode_base!/1" do
    test "decode_base! properly decodes base58 encoded strings" do
      for pair <- @base58_encode_decode do
        [base16_str, base58_str] = pair
        base16_bin = Base.decode16!(base16_str, case: :lower)
        assert base16_bin == Base58.decode_base!(base58_str)
      end
    end
  end

  describe "encode_base!/1" do
    test "properly encodes to base58" do
      for pair <- @base58_encode_decode do
        [base16_str, base58_str] = pair
        base16_bin = Base.decode16!(base16_str, case: :lower)
        assert base58_str == Base58.encode_base(base16_bin)
      end
    end
  end

  describe "encode/1" do
    test "properly encodes Base58" do
      for pair <- @valid_base58_strings do
        [base58_str, base16_str] = pair

        base16_bin = Base.decode16!(base16_str, case: :lower)
        assert base58_str == Base58.encode(base16_bin)

        # double check
        {:ok, _decoded} = Base58.decode(base58_str)
      end
    end
  end

  describe "decode/1" do
    test "properly decodes Base58" do
      for pair <- @valid_base58_strings do
        [base58_str, base16_str] = pair
        base16_bin = Base.decode16!(base16_str, case: :lower)
        {:ok, decoded} = Base58.decode(base58_str)
        assert base16_bin == decoded
      end
    end

    test "catches invalid checksums" do
      for pair <- @invalid_base58_strings do
        [base58_str, _base16_str] = pair
        assert {:error, :invalid_checksum} = Base58.decode(base58_str)
      end
    end
  end
end
