import TxPoolScene from '../models/TxPoolScene.js'
import TxMondrianPoolScene from '../models/TxMondrianPoolScene.js'
import TxBlockScene from '../models/TxBlockScene.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import TxSprite from '../models/TxSprite.js'
import { FastVertexArray } from '../utils/memory.js'
import { overlay, txCount, mempoolCount, mempoolScreenHeight, blockVisible, currentBlock, selectedTx, detailTx, blockAreaSize, highlight, colorMode } from '../stores.js'
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

    this.lastTxTime = 0
    this.txDelay = 0

    detailTx.subscribe(tx => {
      this.onDetailTxChanged(tx)
    })
    highlight.subscribe(criteria => {
      this.highlightCriteria = criteria
      this.applyHighlighting()
    })
    colorMode.subscribe(mode => {
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
      // smooth near-simultaneous arrivals over up to three seconds
      const dx = performance.now() - this.lastTxTime
      this.lastTxTime = performance.now()
      if (dx <= 250) {
        this.txDelay = Math.min(3000, this.txDelay + (Math.random() * 250))
      } else {
        this.txDelay = Math.max(0, this.txDelay - (dx-250))
      }
      this.txs[tx.id] = tx
      tx.onEnterScene()
      this.poolScene.insert(this.txs[tx.id], this.txDelay)
    }
  }

  dropTx (txid) {
    // don't actually need to do anything, just let the tx expire
  }

  addBlock (blockData, realtime=true) {
    // discard duplicate blocks
    if (!blockData || !blockData.id || this.knownBlocks[blockData.id]) {
      return
    }

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
        knownCount++
        this.txs[block.txns[i].id].setData(block.txns[i])
        this.txs[block.txns[i].id].setBlock(block)
        this.blockScene.insert(this.txs[block.txns[i].id], 0, false)
      } else {
        unknownCount++
        const tx = new BitcoinTx({
          ...block.txns[i],
          block: block
        }, this.vertexArray)
        this.txs[tx.id] = tx
        this.txs[tx.id].applyHighlighting(this.highlightCriteria)
        this.blockScene.insert(tx, 0, false)
      }
      this.expiredTxs[block.txns[i].id] = true
    }
    console.log(`New block with ${knownCount} known transactions and ${unknownCount} unknown transactions`)
    this.blockScene.initialLayout()
    setTimeout(() => { this.poolScene.scrollLock = false; this.poolScene.layoutAll() }, 4000)

    blockVisible.set(true)

    currentBlock.set(block)

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
      console.log(this.selectedTx)
      detailTx.set(this.selectedTx)
      if (this.selectedTx) overlay.set('tx')
      this.selectionLocked = !!this.selectedTx && !(this.selectionLocked && sameTx)
    }
  }

  onDetailTxChanged (tx) {
    if (!tx) {
      if (this.selectedTx) {
        this.selectedTx.hoverOff()
        this.selectedTx = null
      }
      selectedTx.set(null)
      this.selectionLocked = false
    }

    selectedTx.set(null)
  }
}
