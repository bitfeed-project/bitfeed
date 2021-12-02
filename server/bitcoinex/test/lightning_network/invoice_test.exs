defmodule Bitcoinex.LightningNetwork.InvoiceTest do
  use ExUnit.Case
  doctest Bitcoinex.Segwit

  alias Bitcoinex.LightningNetwork.{Invoice, HopHint}

  setup_all do
    test_payment_hash = "0001020304050607080900010203040506070809000102030405060708090102"

    test_description_hash_slice =
      Bitcoinex.Utils.sha256(
        "One piece of chocolate cake, one icecream cone, one pickle, one slice of swiss cheese, one slice of salami, one lollypop, one piece of cherry pie, one sausage, one cupcake, and one slice of watermelon"
      )
      |> Base.encode16(case: :lower)

    test_description_coffee = "1 cup coffee"
    test_description_coffee_japanese = "ナンセンス 1杯"

    test_description_blockstream_ledger =
      "Blockstream Store: 88.85 USD for Blockstream Ledger Nano S x 1, \"Back In My Day\" Sticker x 2, \"I Got Lightning Working\" Sticker x 2 and 1 more items"

    # testHopHintPubkeyBytes1 = Base.decode64!("")
    testHopHintPubkey1 = "029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255"
    testHopHintPubkey2 = "039e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255"
    testHopHintPubkey3 = "03d06758583bb5154774a6eb221b1276c9e82d65bbaceca806d90e20c108f4b1c7"

    testSingleHop = [
      %HopHint{
        node_id: testHopHintPubkey1,
        channel_id: 0x0102030405060708,
        fee_base_m_sat: 0,
        fee_proportional_millionths: 20,
        cltv_expiry_delta: 3
      }
    ]

    testDoubleHop = [
      %HopHint{
        node_id: testHopHintPubkey1,
        channel_id: 0x0102030405060708,
        fee_base_m_sat: 1,
        fee_proportional_millionths: 20,
        cltv_expiry_delta: 3
      },
      %HopHint{
        node_id: testHopHintPubkey2,
        channel_id: 0x030405060708090A,
        fee_base_m_sat: 2,
        fee_proportional_millionths: 30,
        cltv_expiry_delta: 4
      }
    ]

    test_address_testnet_P2PKH = "mk2QpYatsKicvFVuTAQLBryyccRXMUaGHP"
    test_address_mainnet_P2PKH = "1RustyRX2oai4EYYDpQGWvEL62BBGqN9T"
    test_address_mainnet_P2SH = "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"
    test_address_mainnet_P2WPKH = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
    test_address_mainnet_P2WSH = "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3"

    test_pubkey = "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad"

    valid_encoded_invoices = [
      # Please send $3 for a cup of coffee to the same peer, within one minute
      {
        "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 250_000_000,
          timestamp: 1_496_314_658,
          description: test_description_coffee,
          expiry: 60,
          min_final_cltv_expiry: 18
        }
      },
      # pubkey set in 'n' field.
      {
        "lnbc241pveeq09pp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdqqnp4q0n326hr8v9zprg8gsvezcch06gfaqqhde2aj730yg0durunfhv66jd3m5klcwhq68vdsmx2rjgxeay5v0tkt2v5sjaky4eqahe4fx3k9sqavvce3capfuwv8rvjng57jrtfajn5dkpqv8yelsewtljwmmycq62k443",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_400_000_000_000,
          timestamp: 1_503_429_093,
          description: "",
          min_final_cltv_expiry: 18
        }
      },
      # Please make a donation of any amount using payment_hash 0001020304050607080900010203040506070809000102030405060708090102 to me @03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad
      {
        "lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq8rkx3yf5tcsyz3d73gafnh3cax9rn449d9p5uxz9ezhhypd0elx87sjle52x86fux2ypatgddc6k63n7erqz25le42c4u4ecky03ylcqca784w",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          description: "Please consider supporting this project",
          payment_hash: test_payment_hash,
          timestamp: 1_496_314_658,
          min_final_cltv_expiry: 18
        }
      },
      # Has a few unknown fields, should just be ignored.
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaqtq2v93xxer9vczq8v93xxeqv72xr42ca60022jqu6fu73n453tmnr0ukc0pl0t23w7eavtensjz0j2wcu7nkxhfdgp9y37welajh5kw34mq7m4xuay0a72cwec8qwgqt5vqht",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          description: "Please consider supporting this project",
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          min_final_cltv_expiry: 18
        }
      },
      # Please send 0.0025 BTC for a cup of nonsense (ナンセンス 1杯) to the same peer, within one minute
      {
        "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrny",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 250_000_000,
          timestamp: 1_496_314_658,
          description: test_description_coffee_japanese,
          expiry: 60,
          min_final_cltv_expiry: 18
        }
      },
      # Now send $24 for an entire list of things (hashed)
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqscc6gd6ql3jrc5yzme8v4ntcewwz5cnw92tz0pc8qcuufvq7khhr8wpald05e92xw006sq94mg8v2ndf4sefvf9sygkshp5zfem29trqq2yxxz7",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          min_final_cltv_expiry: 18
        }
      },
      # The same, on testnet, with a fallback address mk2QpYatsKicvFVuTAQLBryyccRXMUaGHP
      {
        "lntb20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfpp3x9et2e20v6pu37c5d9vax37wxq72un98kmzzhznpurw9sgl2v0nklu2g4d0keph5t7tj9tcqd8rexnd07ux4uv2cjvcqwaxgj7v4uwn5wmypjd5n69z2xm3xgksg28nwht7f6zspwp3f9t",
        %Invoice{
          network: :testnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_testnet_P2PKH,
          min_final_cltv_expiry: 18
        }
      },
      # 1 sat with chinese description in testnet
      {
        "lntb10n1pwt8uswpp5r7j8v60vnevkhxls93x2zp3xyu7z65a4368wh0en8fl70vpypa2sdpzfehjqstdda6kuapqwa5hg6pquju2me5ksucqzys5qzh8dzpqjz7k7pdlal68ew2vx0y9rwaqth758mu0yu0v367kuc8typ08g7tnhh3a7v53svay2efvn7fwah8pesjsgvwrdpjjj795gqp0g4utq",
        %Invoice{
          network: :testnet,
          destination: "0260d9119979caedc570ada883ff614c6efb93f7f7382e25d73ecbeba0b62df2d7",
          description: "No Amount with 中文",
          payment_hash: "1fa47669ec9e596b9bf02c4ca10626273c2d53b58e8eebbf333a7fe7b0240f55",
          amount_msat: 1000,
          timestamp: 1_555_296_782,
          min_final_cltv_expiry: 144
        }
      },
      # 1 hophint
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85frzjq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqqqqqqq9qqqvncsk57n4v9ehw86wq8fzvjejhv9z3w3q5zh6qkql005x9xl240ch23jk79ujzvr4hsmmafyxghpqe79psktnjl668ntaf4ne7ucs5csqh5mnnk",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_mainnet_P2PKH,
          route_hints: testSingleHop,
          min_final_cltv_expiry: 18
        }
      },
      # two hophint
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85fr9yq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqpqqqqq9qqqvpeuqafqxu92d8lr6fvg0r5gv0heeeqgcrqlnm6jhphu9y00rrhy4grqszsvpcgpy9qqqqqqgqqqqq7qqzqj9n4evl6mr5aj9f58zp6fyjzup6ywn3x6sk8akg5v4tgn2q8g4fhx05wf6juaxu9760yp46454gpg5mtzgerlzezqcqvjnhjh8z3g2qqdhhwkj",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_mainnet_P2PKH,
          route_hints: testDoubleHop,
          min_final_cltv_expiry: 18
        }
      },
      # On mainnet, with fallback (p2sh) address 3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfppj3a24vwu6r8ejrss3axul8rxldph2q7z9kk822r8plup77n9yq5ep2dfpcydrjwzxs0la84v3tfw43t3vqhek7f05m6uf8lmfkjn7zv7enn76sq65d8u9lxav2pl6x3xnc2ww3lqpagnh0u",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_mainnet_P2SH,
          min_final_cltv_expiry: 18
        }
      },
      # # On mainnet, with fallback (p2wpkh) address bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfppqw508d6qejxtdg4y5r3zarvary0c5xw7kknt6zz5vxa8yh8jrnlkl63dah48yh6eupakk87fjdcnwqfcyt7snnpuz7vp83txauq4c60sys3xyucesxjf46yqnpplj0saq36a554cp9wt865",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_mainnet_P2WPKH,
          min_final_cltv_expiry: 18
        }
      },
      # On mainnet, with fallback (p2wsh) address bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfp4qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qvnjha2auylmwrltv2pkp2t22uy8ura2xsdwhq5nm7s574xva47djmnj2xeycsu7u5v8929mvuux43j0cqhhf32wfyn2th0sv4t9x55sppz5we8",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          fallback_address: test_address_mainnet_P2WSH,
          min_final_cltv_expiry: 18
        }
      },
      # Ignore unknown witness version in fallback address.
      {
        "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpppw508d6qejxtdg4y5r3zarvary0c5xw7k8txqv6x0a75xuzp0zsdzk5hq6tmfgweltvs6jk5nhtyd9uqksvr48zga9mw08667w8264gkspluu66jhtcmct36nx363km6cquhhv2cpc6q43r",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: test_description_hash_slice,
          min_final_cltv_expiry: 18
        }
      },
      # Ignore fields with unknown lengths.
      {
        "lnbc241pveeq09pp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqpp3qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqshp38yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahnp4q0n326hr8v9zprg8gsvezcch06gfaqqhde2aj730yg0durunfhv66np3q0n326hr8v9zprg8gsvezcch06gfaqqhde2aj730yg0durunfy8huflvs2zwkymx47cszugvzn5v64ahemzzlmm62rpn9l9rm05h35aceq00tkt296289wepws9jh4499wq2l0vk6xcxffd90dpuqchqqztyayq",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 2_400_000_000_000,
          timestamp: 1_503_429_093,
          description_hash: test_description_hash_slice,
          min_final_cltv_expiry: 18
        }
      },
      # # Send 2500uBTC for a cup of coffee with a custom CLTV expiry value.
      {
        "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jscqzysnp4q0n326hr8v9zprg8gsvezcch06gfaqqhde2aj730yg0durunfhv66ysxkvnxhcvhz48sn72lp77h4fxcur27z0he48u5qvk3sxse9mr9jhkltt962s8arjnzk8rk59yj5nw4p495747gksj30gza0crhzwjcpgxzy00",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: test_payment_hash,
          amount_msat: 250_000_000,
          timestamp: 1_496_314_658,
          description: test_description_coffee,
          min_final_cltv_expiry: 144
        }
      },
      {
        "lnbc9678785340p1pwmna7lpp5gc3xfm08u9qy06djf8dfflhugl6p7lgza6dsjxq454gxhj9t7a0sd8dgfkx7cmtwd68yetpd5s9xar0wfjn5gpc8qhrsdfq24f5ggrxdaezqsnvda3kkum5wfjkzmfqf3jkgem9wgsyuctwdus9xgrcyqcjcgpzgfskx6eqf9hzqnteypzxz7fzypfhg6trddjhygrcyqezcgpzfysywmm5ypxxjemgw3hxjmn8yptk7untd9hxwg3q2d6xjcmtv4ezq7pqxgsxzmnyyqcjqmt0wfjjq6t5v4khxxqyjw5qcqp2rzjq0gxwkzc8w6323m55m4jyxcjwmy7stt9hwkwe2qxmy8zpsgg7jcuwz87fcqqeuqqqyqqqqlgqqqqn3qq9qn07ytgrxxzad9hc4xt3mawjjt8znfv8xzscs7007v9gh9j569lencxa8xeujzkxs0uamak9aln6ez02uunw6rd2ht2sqe4hz8thcdagpleym0j",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: "462264ede7e14047e9b249da94fefc47f41f7d02ee9b091815a5506bc8abf75f",
          amount_msat: 967_878_534,
          timestamp: 1_572_468_703,
          description: test_description_blockstream_ledger,
          min_final_cltv_expiry: 10,
          expiry: 604_800,
          route_hints: [
            %HopHint{
              node_id: testHopHintPubkey3,
              channel_id: 0x08FE4E000CF00001,
              fee_base_m_sat: 1000,
              fee_proportional_millionths: 2500,
              cltv_expiry_delta: 40
            }
          ]
        }
      },
      # TODO parsing payment secret
      {
        "lnbc25m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5vdhkven9v5sxyetpdeessp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9q5sqqqqqqqqqqqqqqqpqsq67gye39hfg3zd8rgc80k32tvy9xk2xunwm5lzexnvpx6fd77en8qaq424dxgt56cag2dpt359k3ssyhetktkpqh24jqnjyw6uqd08sgptq44qu",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_500_000_000,
          timestamp: 1_496_314_658,
          description: "coffee beans",
          min_final_cltv_expiry: 18
        }
      },
      # Same, but all upper case
      {
        "LNBC25M1PVJLUEZPP5QQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQYPQDQ5VDHKVEN9V5SXYETPDEESSP5ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYGS9Q5SQQQQQQQQQQQQQQQPQSQ67GYE39HFG3ZD8RGC80K32TVY9XK2XUNWM5LZEXNVPX6FD77EN8QAQ424DXGT56CAG2DPT359K3SSYHETKTKPQH24JQNJYW6UQD08SGPTQ44QU",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_500_000_000,
          timestamp: 1_496_314_658,
          description: "coffee beans",
          min_final_cltv_expiry: 18
        }
      },
      # Same, but including fields which must be ignored.
      {
        "lnbc25m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5vdhkven9v5sxyetpdeessp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9q5sqqqqqqqqqqqqqqqpqsq2qrqqqfppnqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqppnqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpp4qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqhpnqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqhp4qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqspnqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsp4qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqnp5qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqnpkqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq2jxxfsnucm4jf4zwtznpaxphce606fvhvje5x7d4gw7n73994hgs7nteqvenq8a4ml8aqtchv5d9pf7l558889hp4yyrqv6a7zpq9fgpskqhza",
        %Invoice{
          network: :mainnet,
          destination: test_pubkey,
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_500_000_000,
          timestamp: 1_496_314_658,
          description: "coffee beans",
          min_final_cltv_expiry: 18
        }
      },
      {
        "lnbcrt320u1pwt8mp3pp57xs8x6cs28zedru0r0hurkz6932e86dvlrzhwvm09azv57qcekxsdqlv9k8gmeqw3jhxarfdenjqumfd4cxcegcqzpgctyyv3qkvr6khzlnd7de95hrxkw8ewfhmyzuu9dh4sgauukpk5mryaex2qs39ksupm8sxj5jsh3hw3fa0gwdjchh7ga8cx7l652g5dgqzp2ddj",
        %Invoice{
          network: :regtest,
          destination: "03f54387039a2932bca652e9fca1d0eb141a7f9c570979a2c469469a8083c73b47",
          payment_hash: "f1a0736b1051c5968f8f1befc1d85a2c5593e9acf8c577336f2f44ca7818cd8d",
          amount_msat: 32_000_000,
          timestamp: 1_555_295_281,
          description: "alto testing simple",
          min_final_cltv_expiry: 40,
          expiry: 3600
        }
      },
      {
        "lnbc20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfppj3a24vwu6r8ejrss3axul8rxldph2q7z9kmrgvr7xlaqm47apw3d48zm203kzcq357a4ls9al2ea73r8jcceyjtya6fu5wzzpe50zrge6ulk4nvjcpxlekvmxl6qcs9j3tz0469gq5g658y",
        %Invoice{
          network: :mainnet,
          destination: "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad",
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: "3925b6f67e2c340036ed12093dd44e0368df1b6ea26c53dbe4811f58fd5db8c1",
          min_final_cltv_expiry: 18,
          fallback_address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"
        }
      },
      {
        "lnbc20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfppqw508d6qejxtdg4y5r3zarvary0c5xw7kepvrhrm9s57hejg0p662ur5j5cr03890fa7k2pypgttmh4897d3raaq85a293e9jpuqwl0rnfuwzam7yr8e690nd2ypcq9hlkdwdvycqa0qza8",
        %Invoice{
          network: :mainnet,
          destination: "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad",
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: "3925b6f67e2c340036ed12093dd44e0368df1b6ea26c53dbe4811f58fd5db8c1",
          min_final_cltv_expiry: 18,
          fallback_address: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
        }
      },
      {
        "lnbc20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfp4qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q28j0v3rwgy9pvjnd48ee2pl8xrpxysd5g44td63g6xcjcu003j3qe8878hluqlvl3km8rm92f5stamd3jw763n3hck0ct7p8wwj463cql26ava",
        %Invoice{
          network: :mainnet,
          destination: "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad",
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 2_000_000_000,
          timestamp: 1_496_314_658,
          description_hash: "3925b6f67e2c340036ed12093dd44e0368df1b6ea26c53dbe4811f58fd5db8c1",
          min_final_cltv_expiry: 18,
          fallback_address: "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3"
        }
      },
      {
        "lnbc1230p1pwpw4vhpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq8w3jhxaqxqrrsscqpfmmcvd29nucsnyapspmkpqqf65uedt4zvhqkstelrgyk4nfvwka38c3nlq06agjmazs9nr3uupxp6r0v0gzw4n26redc36urkqwxamqqqu7esys",
        %Invoice{
          network: :mainnet,
          destination: "03e7156ae33b0a208d0744199163177e909e80176e55d97a2f221ede0f934dd9ad",
          payment_hash: "0001020304050607080900010203040506070809000102030405060708090102",
          amount_msat: 123,
          timestamp: 1_545_033_111,
          description: "test",
          min_final_cltv_expiry: 9,
          expiry: 3600
        }
      },
      {
        "lnbcrt1230n1pwt8m44pp56zkej4pmwp273agvad0ljscuq4gsc072xlttlgrzrzpmlwzzhzksdq2wd5k6urvv5cqzpgym4nl5gt8xqy69t4cuwf025xnv968xpgvv30h387whfur5y9hq9h5sd8hkumauluj4dn9kqche8glswdpvc2lu4yua3atkyaefuzuqqp27dfsw",
        %Invoice{
          network: :regtest,
          destination: "03f54387039a2932bca652e9fca1d0eb141a7f9c570979a2c469469a8083c73b47",
          payment_hash: "d0ad99543b7055e8f50ceb5ff9431c05510c3fca37d6bfa0621883bfb842b8ad",
          amount_msat: 123_000,
          timestamp: 1_555_295_925,
          description: "simple",
          min_final_cltv_expiry: 40
        }
      }
    ]

    invalid_encoded_invoices = [
      # no hrp,
      "asdsaddnasdnas",
      # too short
      "lnbc1abcde",
      # empty hrp
      "1asdsaddnv4wudz",
      # hrp too short
      "ln1asdsaddnv4wudz",
      # no "ln" prefix
      "llts1dasdajtkfl6",
      # invalid segwit prefix
      "lnts1dasdapukz0w",
      # invalid amount
      "lnbcm1aaamcu25m",
      # invalid amount
      "lnbc1000000000m1",
      # empty fallback address field
      "lnbc20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfqqepvrhrm9s57hejg0p662ur5j5cr03890fa7k2pypgttmh4897d3raaq85a293e9jpuqwl0rnfuwzam7yr8e690nd2ypcq9hlkdwdvycqjhlqg5",
      # invalid routing info length: not a multiple of 51
      "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85frqg00000000j9n4evl6mr5aj9f58zp6fyjzup6ywn3x6sk8akg5v4tgn2q8g4fhx05wf6juaxu9760yp46454gpg5mtzgerlzezqcqvjnhjh8z3g2qqsj5cgu",
      # no payment hash set
      "lnbc20m1pvjluezhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsjv38luh6p6s2xrv3mzvlmzaya43376h0twal5ax0k6p47498hp3hnaymzhsn424rxqjs0q7apn26yrhaxltq3vzwpqj9nc2r3kzwccsplnq470",
      # Both Description and DescriptionHash set.
      "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs03vghs8y0kuj4ulrzls8ln7fnm9dk7sjsnqmghql6hd6jut36clkqpyuq0s5m6fhureyz0szx2qjc8hkgf4xc2hpw8jpu26jfeyvf4cpga36gt",
      # Neither Description nor DescriptionHash set.
      "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqn2rne0kagfl4e0xag0w6hqeg2dwgc54hrm9m0auw52dhwhwcu559qav309h598pyzn69wh2nqauneyyesnpmaax0g6acr8lh9559jmcquyq5a9",
      # mixed case
      "lnbc2500u1PvJlUeZpP5QqQsYqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp",
      # Lightning Payment Request signature pubkey does not match payee pubkey
      "lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaqnp4q0n326hr8v9zprg8gsvezcch06gfaqqhde2aj730yg0durllllll72gy6kphxuhh4a2ffwf9344ytfw98tyhvslsp9y5vt2uxdfhpucph83eqms28dyde9yxgu5ehln4zkwv04nvurxhst77vnng5s0ar9mqpm3cg0l",
      # Bech32 checksum is invalid
      "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrnt",
      # Malformed bech32 string (no 1)
      "pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrny",
      # Malformed bech32 string (mixed case)
      "LNBC2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrny",
      # Signature is not recoverable.
      "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaxtrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2awhz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspk28uwq",
      # String is too short.
      "lnbc1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6na6hlh",
      # Invalid multiplier
      "lnbc2500x1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpujr6jxr9gq9pv6g46y7d20jfkegkg4gljz2ea2a3m9lmvvr95tq2s0kvu70u3axgelz3kyvtp2ywwt0y8hkx2869zq5dll9nelr83zzqqpgl2zg",
      # Invalid sub-millisatoshi precision.
      "lnbc2500000001p1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu7hqtk93pkf7sw55rdv4k9z2vj050rxdr6za9ekfs3nlt5lr89jqpdmxsmlj9urqumg0h9wzpqecw7th56tdms40p2ny9q4ddvjsedzcplva53s"
    ]

    [
      test_pubkey: test_pubkey,
      valid_encoded_invoices: valid_encoded_invoices,
      invalid_encoded_invoices: invalid_encoded_invoices
    ]
  end

  describe "decode/1" do
    test "successfully decode with valid segwit addresses in mainnet", %{
      valid_encoded_invoices: valid_encoded_invoices
    } do
      for {valid_encoded_invoice, invoice} <- valid_encoded_invoices do
        assert {:ok, decoded_invoice} = Invoice.decode(valid_encoded_invoice)
        assert decoded_invoice == invoice
      end
    end

    test "fail to decode with invalid segwit addresses in mainnet", %{
      invalid_encoded_invoices: invalid_encoded_invoices
    } do
      for invalid_encoded_invoice <- invalid_encoded_invoices do
        assert {:error, error} = Invoice.decode(invalid_encoded_invoice)
      end
    end
  end

  describe "expires_at/1" do
    test "calculates expires at time correctly for diff invoice types", %{
      valid_encoded_invoices: invoices
    } do
      for {_valid_encoded_invoice, invoice} <- invoices do
        expires_at = Invoice.expires_at(invoice)
        assert Timex.to_unix(expires_at) - (invoice.expiry || 3600) == invoice.timestamp
      end
    end
  end
end
