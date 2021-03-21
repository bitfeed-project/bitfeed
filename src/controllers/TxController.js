import TxPoolScene from '../models/TxPoolScene.js'
import TxMondrianPoolScene from '../models/TxMondrianPoolScene.js'
import TxBlockScene from '../models/TxBlockScene.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import TxSprite from '../models/TxSprite.js'
import { FastVertexArray } from '../utils/memory.js'
import { txQueueLength, txCount } from '../stores.js'
import config from "../config.js"

export default class TxController {
  constructor ({ width, height }) {
    this.vertexArray = new FastVertexArray(2048, TxSprite.dataSize, txCount)
    this.debugVertexArray = new FastVertexArray(1024, TxSprite.dataSize)
    this.txs = {}
    this.expiredTxs = {}
    this.pool = new TxMondrianPoolScene({ width, height, layer: 0.0, controller: this })
    this.blocks = {}
    this.clearBlockTimeout = null
    this.txDelay = 0 //config.txDelay
    this.maxTxDelay = config.txDelay

    this.pendingTxs = []
    this.pendingMap = {}
    this.queueTimeout = null
    this.queueLength = 0

    this.scheduleQueue(1000)
  }

  getVertexData () {
    return this.vertexArray.getVertexData()
  }

  getDebugVertexData () {
    return this.debugVertexArray.getVertexData()
  }

  getScenes () {
    return [this.pool, ...Object.values(this.blocks)]
  }

  resize ({ width, height }) {
    this.getScenes().forEach(scene => {
      scene.layoutAll({ width, height })
    })
  }

  addTx (txData) {
    const tx = new BitcoinTx(txData, this.vertexArray)
    if (!this.txs[tx.id] && !this.expiredTxs[tx.id]) {
      this.pendingTxs.push([tx, Date.now()])
      this.pendingTxs[tx.id] = tx
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
          delete this.pendingMap[tx.id]
          txQueueLength.decrement()
        } else {
          const timeSince = Date.now() - this.pendingTxs[0][1]
          if (timeSince > this.txDelay) {
            if (this.txDelay < this.maxTxDelay) this.txDelay += 10
            const tx = this.pendingTxs.shift()[0]
            delete this.pendingMap[tx.id]
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

  addBlock (blockData) {
    const block = (blockData && blockData.isBlock) ? blockData : new BitcoinBlock(blockData)
    if (this.clearBlockTimeout) clearTimeout(this.clearBlockTimeout)

    this.expiredTxs = {}

    Object.keys(this.blocks).forEach(blockId => {
      if (!this.blocks[blockId].expired) this.clearBlock(blockId)
    })

    const blockSize = Math.min(window.innerWidth * 0.75, window.innerHeight / 2)
    this.blocks[block.id] = new TxBlockScene({ width: blockSize, height: blockSize, layer: 1.0, blockId: block.id, controller: this })
    let knownCount = 0
    let unknownCount = 0
    for (let i = 0; i < block.txns.length; i++) {
      if (this.pool.remove(block.txns[i].id)) {
        knownCount++
        this.txs[block.txns[i].id].setBlock(block.id)
        this.blocks[block.id].insert(this.txs[block.txns[i].id], false)
      } else if (this.pendingMap[block.txns[i].id]) {
        knownCount++
        const tx = this.pendingMap[tx.id]
        const pendingIndex = this.pendingTxs.indexOf(tx)
        if (pendingIndex >= 0) this.pendingTxs.splice(pendingIndex, 1)
        delete this.pendingMap[tx.id]
        tx.setBlock(block.id)
        this.txs[tx.id] = tx
        this.blocks[block.id].insert(tx, false)
      } else {
        unknownCount++
        const tx = new BitcoinTx({
          ...block.txns[i],
          block: block.id
        }, this.vertexArray)
        this.txs[tx.id] = tx
        this.blocks[block.id].insert(tx, false)
      }
      this.expiredTxs[block.txns[i].id] = true
    }
    console.log(`New block with ${knownCount} known transactions and ${unknownCount} unknown transactions`)
    this.blocks[block.id].initialLayout()
    setTimeout(() => { this.pool.layoutAll() }, 4000)

    this.clearBlockTimeout = setTimeout(() => { this.clearBlock(block.id) }, config.blockTimeout)

    return block
  }

  simulateBlock () {
    for (var i = 0; i < 1000; i++) {
      this.addTx(new BitcoinTx({
        version: 'simulated',
        time: Date.now(),
        id: `simulated_${i}_${Math.random()}`,
        value: Math.floor(Math.pow(2,(0.1-(Math.log(1 - Math.random()))) * 8))
      }))
    }
    const simulatedTxns = this.pendingTxs.map(pending => {
      return {
        version: pending[0].version,
        id: pending[0].id,
        time: pending[0].time,
        value: pending[0].value
      }
    })
    // const simulatedTxns = []
    Object.values(this.pool.txs).forEach(tx => {
      if (Math.random() < 0.5) {
        simulatedTxns.push({
          version: tx.version,
          id: tx.id,
          time: tx.time,
          value: tx.value
        })
      }
    })
    const block = new BitcoinBlock({
      version: 'fake',
      id: 'fake_block' + Math.random(),
      value: 12345678900,
      prev_block: 'also_fake',
      merkle_root: 'merkle',
      timestamp: Date.now() / 1000,
      bits: 'none',
      bytes: 1379334,
      txn_count: simulatedTxns.length,
      txns: simulatedTxns
    })
    setTimeout(() => {
      this.addBlock(block)
    }, 2500)
    return block
  }

  simulateDumpTx (n, value) {
    for (var i = 0; i < n; i++) {
      this.addTx(new BitcoinTx({
        version: 'simulated',
        time: Date.now(),
        id: `simulated_${i}_${Math.random()}`,
        value: value || Math.floor(Math.pow(2,(0.1-(Math.log(1 - Math.random()))) * 8)) // horrible but plausible distribution of tx values
        // value: value || Math.pow(10,Math.floor(Math.random() * 5))
      }, this.vertexArray))
    }
  }

  clearBlock (id) {
    if (this.blocks[id]) {
      this.blocks[id].expire()
    }
  }

  destroyTx (id) {
    this.getScenes().forEach(scene => {
      scene.remove(id)
    })
    if (this.txs[id]) this.txs[id].destroy()
    delete this.txs[id]
  }

  destroyBlock (id) {
    if (this.blocks) delete this.blocks[id]
  }
}
