defmodule Bitcoinex.TransactionTest do
  use ExUnit.Case
  doctest Bitcoinex.Transaction

  alias Bitcoinex.Transaction

  @txn_serialization_1 %{
    tx_hex:
      "01000000010470c3139dc0f0882f98d75ae5bf957e68dadd32c5f81261c0b13e85f592ff7b0000000000ffffffff02b286a61e000000001976a9140f39a0043cf7bdbe429c17e8b514599e9ec53dea88ac01000000000000001976a9148a8c9fd79173f90cf76410615d2a52d12d27d21288ac00000000"
  }

  @txn_segwit_serialization_1 %{
    tx_hex:
      "01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f00000000494830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc22ede944ccf4ecbab4cc618ef3ed01eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee0121025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee635711000000"
  }

  @txn_segwit_serialization_2 %{
    tx_hex:
      "01000000000102fe3dc9208094f3ffd12645477b3dc56f60ec4fa8e6f5d67c565d1c6b9216b36e000000004847304402200af4e47c9b9629dbecc21f73af989bdaa911f7e6f6c2e9394588a3aa68f81e9902204f3fcf6ade7e5abb1295b6774c8e0abd94ae62217367096bc02ee5e435b67da201ffffffff0815cf020f013ed6cf91d29f4202e8a58726b1ac6c79da47c23d1bee0a6925f80000000000ffffffff0100f2052a010000001976a914a30741f8145e5acadf23f751864167f32e0963f788ac000347304402200de66acf4527789bfda55fc5459e214fa6083f936b430a762c629656216805ac0220396f550692cd347171cbc1ef1f51e15282e837bb2b30860dc77c8f78bc8501e503473044022027dc95ad6b740fe5129e7e62a75dd00f291a2aeb1200b84b09d9e3789406b6c002201a9ecd315dd6a0e632ab20bbb98948bc0c6fb204f2c286963bb48517a7058e27034721026dccc749adc2a9d0d89497ac511f760f45c47dc5ed9cf352a58ac706453880aeadab210255a9626aebf5e29c0e6538428ba0d1dcf6ca98ffdf086aa8ced5e0d0215ea465ac00000000"
  }

  @txn_segwit_serialization_3 %{
    tx_hex:
      "01000000000101db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d3ceb1a5477010000001716001479091972186c449eb1ded22b78e40d009bdf0089feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac02473044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f8288e5d794d12d482f0220217f36a485cae903c713331d877c1f64677e3622ad4010726870540656fe9dcb012103ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a2687392040000"
  }

  @txn_segwit_serialization_4 %{
    tx_hex:
      "0100000000010136641869ca081e70f394c6948e8af409e18b619df2ed74aa106c1ca29787b96e0100000023220020a16b5755f7f6f96dbd65f5f0d6ab9418b89af4b1f14a1bb8a09062c35f0dcb54ffffffff0200e9a435000000001976a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688acc0832f05000000001976a9147480a33f950689af511e6e84c138dbbd3c3ee41588ac080047304402206ac44d672dac41f9b00e28f4df20c52eeb087207e8d758d76d92c6fab3b73e2b0220367750dbbe19290069cba53d096f44530e4f98acaa594810388cf7409a1870ce01473044022068c7946a43232757cbdf9176f009a928e1cd9a1a8c212f15c1e11ac9f2925d9002205b75f937ff2f9f3c1246e547e54f62e027f64eefa2695578cc6432cdabce271502473044022059ebf56d98010a932cf8ecfec54c48e6139ed6adb0728c09cbe1e4fa0915302e022007cd986c8fa870ff5d2b3a89139c9fe7e499259875357e20fcbb15571c76795403483045022100fbefd94bd0a488d50b79102b5dad4ab6ced30c4069f1eaa69a4b5a763414067e02203156c6a5c9cf88f91265f5a942e96213afae16d83321c8b31bb342142a14d16381483045022100a5263ea0553ba89221984bd7f0b13613db16e7a70c549a86de0cc0444141a407022005c360ef0ae5a5d4f9f2f87a56c1546cc8268cab08c73501d6b3be2e1e1a8a08824730440220525406a1482936d5a21888260dc165497a90a15669636d8edca6b9fe490d309c022032af0c646a34a44d1f4576bf6a4a74b67940f8faa84c7df9abe12a01a11e2b4783cf56210307b8ae49ac90a048e9b53357a2354b3334e9c8bee813ecb98e99a7e07e8c3ba32103b28f0c28bfab54554ae8c658ac5c3e0ce6e79ad336331f78c428dd43eea8449b21034b8113d703413d57761b8b9781957b8c0ac1dfe69f492580ca4195f50376ba4a21033400f6afecb833092a9a21cfdf1ed1376e58c5d1f47de74683123987e967a8f42103a6d48b1131e94ba04d9737d61acdaa1322008af9602b3b14862c07a1789aac162102d8b661b0b3302ee2f162b09e07a55ad5dfbe673a9f01d9f0c19617681024306b56ae00000000"
  }

  describe "decode/1" do
    test "decodes legacy bitcoin transaction" do
      txn_test = @txn_serialization_1
      {:ok, txn} = Transaction.decode(txn_test.tx_hex)
      assert 1 == length(txn.inputs)
      assert 2 == length(txn.outputs)
      assert 1 == txn.version
      assert nil == txn.witnesses
      assert 0 == txn.lock_time

      assert "b020bdec4e92cb69db93557dcbbfcc73076fc01f6828e41eb3ef5f628414ee62" ==
               Transaction.transaction_id(txn)

      in_1 = Enum.at(txn.inputs, 0)

      assert "7bff92f5853eb1c06112f8c532ddda687e95bfe55ad7982f88f0c09d13c37004" == in_1.prev_txid
      assert 0 == in_1.prev_vout
      assert "" == in_1.script_sig
      assert 4_294_967_295 == in_1.sequence_no

      out_0 = Enum.at(txn.outputs, 0)
      assert 514_229_938 == out_0.value
      assert "76a9140f39a0043cf7bdbe429c17e8b514599e9ec53dea88ac" == out_0.script_pub_key

      out_1 = Enum.at(txn.outputs, 1)
      assert 1 == out_1.value
      assert "76a9148a8c9fd79173f90cf76410615d2a52d12d27d21288ac" == out_1.script_pub_key
    end

    test "decodes native segwit p2wpkh bitcoin transaction" do
      txn_test = @txn_segwit_serialization_1
      {:ok, txn} = Transaction.decode(txn_test.tx_hex)
      assert 2 == length(txn.inputs)
      assert 2 == length(txn.outputs)
      assert 1 == txn.version
      assert 2 == length(txn.witnesses)
      assert 17 == txn.lock_time

      assert "e8151a2af31c368a35053ddd4bdb285a8595c769a3ad83e0fa02314a602d4609" ==
               Transaction.transaction_id(txn)

      in_1 = Enum.at(txn.inputs, 0)

      assert "9f96ade4b41d5433f4eda31e1738ec2b36f6e7d1420d94a6af99801a88f7f7ff" == in_1.prev_txid
      assert 0 == in_1.prev_vout

      assert "4830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc22ede944ccf4ecbab4cc618ef3ed01" ==
               in_1.script_sig

      assert 4_294_967_278 == in_1.sequence_no

      in_2 = Enum.at(txn.inputs, 1)

      assert "8ac60eb9575db5b2d987e29f301b5b819ea83a5c6579d282d189cc04b8e151ef" == in_2.prev_txid
      assert 1 == in_2.prev_vout
      assert "" == in_2.script_sig
      assert 4_294_967_295 == in_2.sequence_no

      witness_in_0 = Enum.at(txn.witnesses, 0)
      assert 0 == witness_in_0.txinwitness

      witness_in_1 = Enum.at(txn.witnesses, 1)

      assert [
               "304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee01",
               "025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357"
             ] == witness_in_1.txinwitness

      out_0 = Enum.at(txn.outputs, 0)
      assert 112_340_000 == out_0.value
      assert "76a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac" == out_0.script_pub_key

      out_1 = Enum.at(txn.outputs, 1)
      assert 223_450_000 == out_1.value
      assert "76a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac" == out_1.script_pub_key
    end

    test "decodes native segwit p2wsh bitcoin transaction" do
      txn_test = @txn_segwit_serialization_2
      {:ok, txn} = Transaction.decode(txn_test.tx_hex)
      assert 2 == length(txn.inputs)
      assert 1 == length(txn.outputs)
      assert 1 == txn.version
      assert 2 == length(txn.witnesses)
      assert 0 == txn.lock_time

      assert "570e3730deeea7bd8bc92c836ccdeb4dd4556f2c33f2a1f7b889a4cb4e48d3ab" ==
               Transaction.transaction_id(txn)

      in_0 = Enum.at(txn.inputs, 0)

      assert "6eb316926b1c5d567cd6f5e6a84fec606fc53d7b474526d1fff3948020c93dfe" == in_0.prev_txid
      assert 0 == in_0.prev_vout

      assert "47304402200af4e47c9b9629dbecc21f73af989bdaa911f7e6f6c2e9394588a3aa68f81e9902204f3fcf6ade7e5abb1295b6774c8e0abd94ae62217367096bc02ee5e435b67da201" ==
               in_0.script_sig

      assert 4_294_967_295 == in_0.sequence_no

      in_1 = Enum.at(txn.inputs, 1)

      assert "f825690aee1b3dc247da796cacb12687a5e802429fd291cfd63e010f02cf1508" == in_1.prev_txid
      assert 0 == in_1.prev_vout
      assert "" == in_1.script_sig
      assert 4_294_967_295 == in_1.sequence_no

      witness_in_0 = Enum.at(txn.witnesses, 0)
      assert 0 == witness_in_0.txinwitness

      witness_in_1 = Enum.at(txn.witnesses, 1)

      assert [
               "304402200de66acf4527789bfda55fc5459e214fa6083f936b430a762c629656216805ac0220396f550692cd347171cbc1ef1f51e15282e837bb2b30860dc77c8f78bc8501e503",
               "3044022027dc95ad6b740fe5129e7e62a75dd00f291a2aeb1200b84b09d9e3789406b6c002201a9ecd315dd6a0e632ab20bbb98948bc0c6fb204f2c286963bb48517a7058e2703",
               "21026dccc749adc2a9d0d89497ac511f760f45c47dc5ed9cf352a58ac706453880aeadab210255a9626aebf5e29c0e6538428ba0d1dcf6ca98ffdf086aa8ced5e0d0215ea465ac"
             ] == witness_in_1.txinwitness

      out_1 = Enum.at(txn.outputs, 0)
      assert 5_000_000_000 == out_1.value
      assert "76a914a30741f8145e5acadf23f751864167f32e0963f788ac" == out_1.script_pub_key
    end

    test "decodes segwit p2sh-pw2pkh bitcoin transaction" do
      txn_test = @txn_segwit_serialization_3
      {:ok, txn} = Transaction.decode(txn_test.tx_hex)
      assert 1 == length(txn.inputs)
      assert 2 == length(txn.outputs)
      assert 1 == txn.version
      assert 1 == length(txn.witnesses)
      assert 1170 == txn.lock_time

      assert "ef48d9d0f595052e0f8cdcf825f7a5e50b6a388a81f206f3f4846e5ecd7a0c23" ==
               Transaction.transaction_id(txn)

      in_0 = Enum.at(txn.inputs, 0)

      assert "77541aeb3c4dac9260b68f74f44c973081a9d4cb2ebe8038b2d70faa201b6bdb" == in_0.prev_txid
      assert 1 == in_0.prev_vout

      assert "16001479091972186c449eb1ded22b78e40d009bdf0089" ==
               in_0.script_sig

      assert 4_294_967_294 == in_0.sequence_no

      witness_in_0 = Enum.at(txn.witnesses, 0)

      assert [
               "3044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f8288e5d794d12d482f0220217f36a485cae903c713331d877c1f64677e3622ad4010726870540656fe9dcb01",
               "03ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a26873"
             ] == witness_in_0.txinwitness

      out_0 = Enum.at(txn.outputs, 0)
      assert 199_996_600 == out_0.value
      assert "76a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac" == out_0.script_pub_key

      out_1 = Enum.at(txn.outputs, 1)
      assert 800_000_000 == out_1.value
      assert "76a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac" == out_1.script_pub_key
    end

    test "decodes segwit p2sh-p2wsh bitcoin transaction" do
      txn_test = @txn_segwit_serialization_4
      {:ok, txn} = Transaction.decode(txn_test.tx_hex)
      assert 1 == length(txn.inputs)
      assert 2 == length(txn.outputs)
      assert 1 == txn.version
      assert 1 == length(txn.witnesses)
      assert 0 == txn.lock_time

      assert "27eae69aff1dd4388c0fa05cbbfe9a3983d1b0b5811ebcd4199b86f299370aac" ==
               Transaction.transaction_id(txn)

      in_0 = Enum.at(txn.inputs, 0)

      assert "6eb98797a21c6c10aa74edf29d618be109f48a8e94c694f3701e08ca69186436" == in_0.prev_txid
      assert 1 == in_0.prev_vout

      assert "220020a16b5755f7f6f96dbd65f5f0d6ab9418b89af4b1f14a1bb8a09062c35f0dcb54" ==
               in_0.script_sig

      assert 4_294_967_295 == in_0.sequence_no

      witness_in_0 = Enum.at(txn.witnesses, 0)

      assert [
               "",
               "304402206ac44d672dac41f9b00e28f4df20c52eeb087207e8d758d76d92c6fab3b73e2b0220367750dbbe19290069cba53d096f44530e4f98acaa594810388cf7409a1870ce01",
               "3044022068c7946a43232757cbdf9176f009a928e1cd9a1a8c212f15c1e11ac9f2925d9002205b75f937ff2f9f3c1246e547e54f62e027f64eefa2695578cc6432cdabce271502",
               "3044022059ebf56d98010a932cf8ecfec54c48e6139ed6adb0728c09cbe1e4fa0915302e022007cd986c8fa870ff5d2b3a89139c9fe7e499259875357e20fcbb15571c76795403",
               "3045022100fbefd94bd0a488d50b79102b5dad4ab6ced30c4069f1eaa69a4b5a763414067e02203156c6a5c9cf88f91265f5a942e96213afae16d83321c8b31bb342142a14d16381",
               "3045022100a5263ea0553ba89221984bd7f0b13613db16e7a70c549a86de0cc0444141a407022005c360ef0ae5a5d4f9f2f87a56c1546cc8268cab08c73501d6b3be2e1e1a8a0882",
               "30440220525406a1482936d5a21888260dc165497a90a15669636d8edca6b9fe490d309c022032af0c646a34a44d1f4576bf6a4a74b67940f8faa84c7df9abe12a01a11e2b4783",
               "56210307b8ae49ac90a048e9b53357a2354b3334e9c8bee813ecb98e99a7e07e8c3ba32103b28f0c28bfab54554ae8c658ac5c3e0ce6e79ad336331f78c428dd43eea8449b21034b8113d703413d57761b8b9781957b8c0ac1dfe69f492580ca4195f50376ba4a21033400f6afecb833092a9a21cfdf1ed1376e58c5d1f47de74683123987e967a8f42103a6d48b1131e94ba04d9737d61acdaa1322008af9602b3b14862c07a1789aac162102d8b661b0b3302ee2f162b09e07a55ad5dfbe673a9f01d9f0c19617681024306b56ae"
             ] == witness_in_0.txinwitness

      out_0 = Enum.at(txn.outputs, 0)
      assert 900_000_000 == out_0.value
      assert "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac" == out_0.script_pub_key

      out_1 = Enum.at(txn.outputs, 1)
      assert 87_000_000 == out_1.value
      assert "76a9147480a33f950689af511e6e84c138dbbd3c3ee41588ac" == out_1.script_pub_key
    end
  end
end
