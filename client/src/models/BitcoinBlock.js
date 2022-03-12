import BitcoinTx from '../models/BitcoinTx.js'

export default class BitcoinBlock {
  constructor ({ version, id, value, prev_block, merkle_root, timestamp, bits, bytes, txn_count, txns, fees }) {
    this.isBlock = true
    this.version = version
    this.id = id
    this.value = value
    this.prev_block = prev_block
    this.merkle_root = merkle_root
    this.time = timestamp * 1000 // btc protocol gives times in seconds, js needs milliseconds
    this.bits = bits // difficulty target (i.e. number of 0 bits required for hash)
    this.bytes = bytes // OTW size of this block in bytes
    this.txnCount = txn_count
    this.txns = txns
    this.coinbase = new BitcoinTx(this.txns[0], true)
    if (fees) {
      this.fees = fees
    } else {
      this.fees = null
    }
    this.coinbase.setBlock(this)
    this.height = this.coinbase.coinbase.height
    this.miner_sig = this.coinbase.coinbase.sigAscii

    this.total_vbytes = 0

    if (this.fees != null) {
      this.maxFeerate = 0
      this.minFeerate = this.txnCount > 1 ? Infinity : 0
      this.avgFeerate = 0
      this.txns.forEach(txn => {
        if (txn.id !== this.coinbase.id) {
          const txFeerate = txn.fee / txn.vbytes
          this.maxFeerate = Math.max(this.maxFeerate, txFeerate)
          this.minFeerate = Math.min(this.minFeerate, txFeerate)
          this.avgFeerate += (txn.feerate / this.txnCount)
        }
        this.total_vbytes += txn.vbytes
      })
      this.avgFeerate = this.fees / this.total_vbytes
    }
  }
}
