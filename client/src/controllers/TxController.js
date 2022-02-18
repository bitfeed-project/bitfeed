import TxPoolScene from '../models/TxPoolScene.js'
import TxMondrianPoolScene from '../models/TxMondrianPoolScene.js'
import TxBlockScene from '../models/TxBlockScene.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import TxSprite from '../models/TxSprite.js'
import { FastVertexArray } from '../utils/memory.js'
import { txQueueLength, txCount, mempoolCount, mempoolScreenHeight, blockVisible, currentBlock, selectedTx, blockAreaSize, highlight, colorMode } from '../stores.js'
import config from "../config.js"

export default class TxController {
  constructor ({ width, height }) {
    this.vertexArray = new FastVertexArray(2048, TxSprite.dataSize, txCount)
    this.debugVertexArray = new FastVertexArray(1024, TxSprite.dataSize)
    this.txs = {}
    this.expiredTxs = {}
    this.poolScene = new TxMondrianPoolScene({ width, height, controller: this, heightStore: mempoolScreenHeight })
    this.blockAreaSize = Math.min(window.innerWidth * 0.75, window.innerHeight / 2.5)
    blockAreaSize.set(this.blockAreaSize)
    this.blockScene = null
    this.clearBlockTimeout = null
    this.txDelay = 0 //config.txDelay
    this.maxTxDelay = config.txDelay
    this.knownBlocks = {}

    this.selectedTx = null
    this.selectionLocked = false

    this.pendingTxs = []
    this.pendingMap = {}
    this.queueTimeout = null
    this.queueLength = 0

    highlight.subscribe(criteria => {
      this.highlightCriteria = criteria
      this.applyHighlighting()
    })

    this.scheduleQueue(1000)
    colorMode.subscribe(mode => {
      console.log('color mode changed: ', mode)
      this.setColorMode(mode)
    })
  }

  getVertexData () {
    return this.vertexArray.getVertexData()
  }

  getDebugVertexData () {
    return this.debugVertexArray.getVertexData()
  }

  getScenes () {
    if (this.blockScene) return [this.poolScene, this.blockScene]
    else return [this.poolScene]
  }

  redoLayout ({ width, height }) {
    this.poolScene.layoutAll({ width, height })
    if (this.blockScene) {
      this.blockScene.layoutAll({ width: this.blockAreaSize, height: this.blockAreaSize })
    }
  }

  resize ({ width, height }) {
    this.blockAreaSize = Math.min(window.innerWidth * 0.75, window.innerHeight / 2.5)
    blockAreaSize.set(this.blockAreaSize)
    this.redoLayout({ width, height })
  }

  setColorMode (mode) {
    this.colorMode = mode
    this.poolScene.setColorMode(mode)
    if (this.blockScene) {
      this.blockScene.setColorMode(mode)
    }
  }

  applyHighlighting () {
    this.poolScene.applyHighlighting(this.highlightCriteria)
    if (this.blockScene) {
      this.blockScene.applyHighlighting(this.highlightCriteria)
    }
  }

  addTx (txData) {
    const tx = new BitcoinTx(txData, this.vertexArray)
    tx.applyHighlighting(this.highlightCriteria)
    if (!this.txs[tx.id] && !this.expiredTxs[tx.id]) {
      this.pendingTxs.push([tx, performance.now()])
      this.pendingTxs[tx.id] = tx
      txQueueLength.increment()
    }
  }

  // Dual-strategy queue processing:
  // - ensure transactions are queued for at least txDelay
  // - when queue length exceeds 500, process iteratively to avoid unbounded growth
  // - while queue is small, use jittered timeouts to evenly distribute arrivals
  //
  // transactions tend to arrive in groups, so for smoothest
  // animation the queue should stay short but never empty.
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
          const timeSince = performance.now() - this.pendingTxs[0][1]
          if (timeSince > this.txDelay) {
            //process the next tx in the queue, if it arrived longer ago than txDelay
            if (this.txDelay < this.maxTxDelay) {
              // slowly ramp up from 0 to maxTxDelay on start, so there's no wait for the first txs on page load
              this.txDelay += 50
            }
            const tx = this.pendingTxs.shift()[0]
            delete this.pendingMap[tx.id]
            txQueueLength.decrement()
            this.txs[tx.id] = tx
            this.poolScene.insert(this.txs[tx.id])
            mempoolCount.increment()
          } else {
            // end the loop when the head of the queue arrived more recently than txDelay
            done = true
            // schedule to continue processing when head of queue matures
            delay = this.txDelay - timeSince
          }
          if (this.pendingTxs.length < 500) {
            // or the queue is under 500
            done = true
          }
          // otherwise keep processing the queue
        }
      } else done = true
    }
    // randomly jitter arrival times so that txs enter more naturally
    // with jittered delay inversely proportional to size of queue
    let jitter = Math.random() * Math.max(1, (500 - this.pendingTxs.length))
    this.scheduleQueue(delay || jitter)
  }

  scheduleQueue (delay) {
    if (this.queueTimeout) clearTimeout(this.queueTimeout)
    this.queueTimeout = setTimeout(() => {
      this.processQueue()
    }, delay)
  }

  addBlock (blockData, realtime=true) {
    // discard duplicate blocks
    if (!blockData || !blockData.id || this.knownBlocks[blockData.id]) {
      return
    }

    this.poolScene.scrollLock = true

    const block = new BitcoinBlock(blockData)
    this.knownBlocks[block.id] = true
    if (this.clearBlockTimeout) clearTimeout(this.clearBlockTimeout)

    this.expiredTxs = {}

    this.clearBlock()

    this.blockScene = new TxBlockScene({ width: this.blockAreaSize, height: this.blockAreaSize, blockId: block.id, controller: this, colorMode: this.colorMode })
    let knownCount = 0
    let unknownCount = 0
    for (let i = 0; i < block.txns.length; i++) {
      if (this.poolScene.remove(block.txns[i].id)) {
        poolCount++
        knownCount++
        this.txs[block.txns[i].id].setBlock(block.id)
        this.blockScene.insert(this.txs[block.txns[i].id], false)
      } else if (this.pendingMap[block.txns[i].id]) {
        knownCount++
        const tx = this.pendingMap[tx.id]
        const pendingIndex = this.pendingTxs.indexOf(tx)
        if (pendingIndex >= 0) this.pendingTxs.splice(pendingIndex, 1)
        delete this.pendingMap[tx.id]
        tx.setBlock(block.id)
        this.txs[tx.id] = tx
        this.blockScene.insert(tx, false)
      } else {
        unknownCount++
        const tx = new BitcoinTx({
          ...block.txns[i],
          block: block.id
        }, this.vertexArray)
        this.txs[tx.id] = tx
        this.txs[tx.id].applyHighlighting(this.highlightCriteria)
        this.blockScene.insert(tx, 0, false)
      }
      this.expiredTxs[block.txns[i].id] = true
    }
    console.log(`New block with ${knownCount} known transactions and ${unknownCount} unknown transactions`)
    mempoolCount.subtract(poolCount)
    this.blockScene.initialLayout()
    setTimeout(() => { this.poolScene.scrollLock = false; this.poolScene.layoutAll() }, 4000)

    currentBlock.set(block)
    blockVisible.set(true)

    return block
  }

  hideBlock () {
    if (this.blockScene) {
      this.blockScene.hide()
    }
  }

  showBlock () {
    if (this.blockScene) {
      this.blockScene.show()
    }
  }

  clearBlock () {
    if (this.blockScene) {
      this.blockScene.expire()
    }
    currentBlock.set(null)
    if (this.blockVisibleUnsub) this.blockVisibleUnsub()
  }

  destroyTx (id) {
    this.getScenes().forEach(scene => {
      scene.remove(id)
    })
    if (this.txs[id]) this.txs[id].destroy()
    delete this.txs[id]
  }

  mouseMove (position) {
    if (this.poolScene && !this.selectionLocked) {
      let selected = this.poolScene.selectAt(position)
      if (!selected && this.blockScene && !this.blockScene.hidden) selected = this.blockScene.selectAt(position)

      if (selected !== this.selectedTx) {
        if (this.selectedTx) this.selectedTx.hoverOff()
        if (selected) selected.hoverOn()
      }
      this.selectedTx = selected
      selectedTx.set(this.selectedTx)
    }
  }

  mouseClick (position) {
    if (this.poolScene) {
      let selected = this.poolScene.selectAt(position)
      if (!selected && this.blockScene && !this.blockScene.hidden) selected = this.blockScene.selectAt(position)

      let sameTx = true
      if (selected !== this.selectedTx) {
        sameTx = false
        if (this.selectedTx) this.selectedTx.hoverOff()
        if (selected) selected.hoverOn()
      }
      this.selectedTx = selected
      selectedTx.set(this.selectedTx)
      this.selectionLocked = !!this.selectedTx && !(this.selectionLocked && sameTx)
    }
  }
}
