export default class BitcoinBlock {
  constructor ({ version, id, value, prev_block, merkle_root, timestamp, bits, txn_count, txns }) {
    this.version = version
    this.id = id
    this.value = value
    this.prev_block = prev_block
    this.merkle_root = merkle_root
    this.time = timestamp
    this.bits = bits
    this.txns = txns
  }
}
