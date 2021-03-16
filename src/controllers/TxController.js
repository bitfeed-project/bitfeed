import TxPoolScene from '../models/TxPoolScene.js'
import TxBlockScene from '../models/TxBlockScene.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import { txQueueLength } from '../stores.js'

export default class TxController {
  constructor ({ width, height }) {
    this.txs = {}
    this.expiredTxs = {}
    this.pool = new TxPoolScene({ width, height, layer: 0.0 })
    this.blocks = {}
    this.clearBlockTimeout = null

    this.pendingTxs = []
    this.queueTimeout = null
    this.queueLength = 0

    this.scheduleQueue(1000)
  }

  getScenes () {
    return [this.pool, ...Object.values(this.blocks)]
  }

  resize ({ width, height }) {
    this.getScenes().forEach(scene => {
      scene.resize({ width, height })
      scene.layoutAll()
    })
  }

  addTx (tx) {
    if (!this.txs[tx.id] && !this.expiredTxs[tx.id]) {
      this.pendingTxs.push([tx, Date.now()])
      txQueueLength.increment()
    }
  }

  // Dual-strategy queue processing:
  // - ensure transactions are queued for at least 2s
  // - while queue is small, use jittered timeouts to smooth arrivals
  // - when queue length exceeds 100, process iteratively to avoid unbounded growth
  processQueue () {
    let done
    let delay
    while (!done) {
      if (this.pendingTxs && this.pendingTxs.length) {
        if (this.txs[this.pendingTxs[0][0].id] || this.expiredTxs[this.pendingTxs[0][0].id]) {
          // duplicate transaction, skip without delay
          const tx = this.pendingTxs.shift()[0]
          txQueueLength.decrement()
        } else {
          const timeSince = Date.now() - this.pendingTxs[0][1]
          if (timeSince > 2000) {
            const tx = this.pendingTxs.shift()[0]
            txQueueLength.decrement()
            this.txs[tx.id] = tx
            this.pool.insert(this.txs[tx.id])
          } else {
            done = true
            delay = 2001 - timeSince
          }
          if (!done && this.pendingTxs.length < 100) {
            done = true
          }
        }
      } else done = true
    }
    this.scheduleQueue(delay || (Math.random() * Math.max(1, (250 - this.pendingTxs.length))))
  }

  scheduleQueue (delay) {
    if (this.queueTimeout) clearTimeout(this.queueTimeout)
    this.queueTimeout = setTimeout(() => {
      this.processQueue()
    }, delay)
  }

  addBlock (block) {
    if (this.clearBlockTimeout) clearTimeout(this.clearBlockTimeout)

    this.expiredTxs = {}

    Object.keys(this.blocks).forEach(blockId => {
      if (!this.blocks[blockId].expired) this.clearBlock(blockId)
    })

    this.blocks[block.id] = new TxBlockScene({ width: 500, height: 500, layer: 1.0 })
    let knownCount = 0
    let unknownCount = 0
    for (let i = 0; i < block.txns.length; i++) {
      if (this.pool.remove(block.txns[i].id)) {
        knownCount++
        this.txs[block.txns[i].id].setBlock(block.id)
        this.blocks[block.id].insert(this.txs[block.txns[i].id], false)
      } else {
        unknownCount++
        const tx = new BitcoinTx({
          ...block.txns[i],
          block: block.id
        })
        this.txs[tx.id] = tx
        this.blocks[block.id].insert(this.txs[tx.id], false)
      }
      this.expiredTxs[block.txns[i].id] = true
    }
    console.log(`New block with ${knownCount} known transactions and ${unknownCount} unknown transactions`)
    this.blocks[block.id].layoutAll()
    setTimeout(() => { this.pool.layoutAll() }, 2000)

    this.clearBlockTimeout = setTimeout(() => { this.clearBlock(block.id) }, 10000)
  }

  simulateBlock () {
    // for (var i = 0; i < 1000; i++) {
    //   this.addTx(new BitcoinTx({
    //     version: 'simulated',
    //     time: Date.now(),
    //     id: `simulated_${i}_${Math.random()}`,
    //     value: Math.floor(Math.random() * 100000)
    //   }))
    // }
    // const simulatedTxns = this.pendingTxs.map(pending => {
    //   return {
    //     version: pending[0].version,
    //     id: pending[0].id,
    //     time: pending[0].time
    //   }
    // })
    const simulatedTxns = []
    Object.values(this.txs).forEach(tx => {
      if (Math.random() < 0.5) {
        simulatedTxns.push({
          version: tx.version,
          id: tx.id,
          time: tx.time
        })
      }
    })
    setTimeout(() => {
      this.addBlock(new BitcoinBlock({
        version: 'fake',
        id: Math.random(),
        value: 10000,
        prev_block: 'also_fake',
        merkle_root: 'merkle',
        timestamp: Date.now(),
        bits: 'none',
        txn_count: 20,
        txns: simulatedTxns
      }))
    }, 2500)
  }

  simulateDumpTx (n) {
    for (var i = 0; i < n; i++) {
      this.addTx(new BitcoinTx({
        version: 'simulated',
        time: Date.now(),
        id: `simulated_${i}_${Math.random()}`,
        value: Math.floor(Math.random() * 100000)
      }))
    }
  }

  clearBlock (id) {
    if (this.blocks[id]) {
      this.blocks[id].expire()
      setTimeout(() => {
        const txs = this.blocks[id].getTxList()
        for (let i = 0; i < txs.length; i++) {
          if (this.blocks[id].remove(txs[i])) {
            delete this.txs[txs[i]]
          }
        }
        delete this.blocks[id]
      }, 3000)
    }
  }
}
