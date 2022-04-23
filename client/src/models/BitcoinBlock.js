import BitcoinTx from '../models/BitcoinTx.js'

export default class BitcoinBlock {
  constructor ({ version, id, height, value, prev_block, merkle_root, timestamp, bits, bytes, txn_count, txns, fees }) {
    this.isBlock = true
    this.version = version
    this.id = id
    this.height = height
    this.value = value
    this.prev_block = prev_block
    this.merkle_root = merkle_root
    this.time = timestamp * 1000 // btc protocol gives times in seconds, js needs milliseconds
    this.bits = bits // difficulty target (i.e. number of 0 bits required for hash)
    this.bytes = bytes // OTW size of this block in bytes
    this.txnCount = txn_count
    this.txns = txns
    this.coinbase = new BitcoinTx(this.txns[0], true)
    this.fees = fees
    this.coinbase.setBlock(this)
    this.height = this.height || this.coinbase.coinbase.height
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

  setVertexArray (vertexArray) {
    if (this.txns) {
      this.txns.forEach(txn => {
        txn.setVertexArray(vertexArray)
      })
    }
  }

  static fromRPCData (data) {
    const txns = data.tx.map((tx, index) => { return BitcoinTx.fromRPCData(tx, index == 0) })
    const value = txns.reduce((acc, tx) => { return acc + tx.fee + tx.value }, 0)
    const fees = txns.reduce((acc, tx) => { return acc + tx.fee }, 0)

    return {
      version: data.version,
      id: data.hash,
      height: data.height,
      value: value,
      prev_block: data.previousblockhash,
      merkle_root: data.merkleroot,
      timestamp: data.time,
      bits: data.bits,
      bytes: data.size,
      txn_count: txns.length,
      txns,
      fees
    }
  }

  static decompress (data) {
    return {
      version: data[0],
      id: data[1],
      height: data[2],
      value: data[3],
      prev_block: data[4],
      timestamp: data[5],
      bits: data[6],
      bytes: data[7],
      txn_count: data[8].length,
      txns: data[8].map(txData => BitcoinTx.decompress(txData)),
      fees: data[9]
    }
  }
}
