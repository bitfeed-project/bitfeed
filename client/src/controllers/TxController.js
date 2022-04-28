import TxPoolScene from '../models/TxPoolScene.js'
import TxMondrianPoolScene from '../models/TxMondrianPoolScene.js'
import TxBlockScene from '../models/TxBlockScene.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import TxSprite from '../models/TxSprite.js'
import { FastVertexArray } from '../utils/memory.js'
import { searchTx, fetchSpends, addSpends } from '../utils/search.js'
import { overlay, txCount, mempoolCount, mempoolScreenHeight, blockVisible, currentBlock, selectedTx, detailTx, blockAreaSize, highlight, colorMode, blocksEnabled, latestBlockHeight, explorerBlockData, blockTransitionDirection, loading, urlPath } from '../stores.js'
import config from "../config.js"
import { tick } from 'svelte';

export default class TxController {
  constructor ({ width, height }) {
    this.vertexArray = new FastVertexArray(2048, TxSprite.dataSize, txCount)
    this.debugVertexArray = new FastVertexArray(1024, TxSprite.dataSize)
    this.txs = {}
    this.expiredTxs = {}
    this.poolScene = new TxMondrianPoolScene({ width, height, controller: this, heightStore: mempoolScreenHeight })
    this.blockAreaSize = (width <= 620) ? Math.min(window.innerWidth * 0.7, window.innerHeight / 2.75) : Math.min(window.innerWidth * 0.75, window.innerHeight / 2.5)
    blockAreaSize.set(this.blockAreaSize)
    this.blockScene = null
    this.block = null
    this.explorerBlockScene = null
    this.explorerBlock = null
    this.clearBlockTimeout = null
    this.txDelay = 0 //config.txDelay
    this.maxTxDelay = config.txDelay
    this.knownBlocks = {}

    this.selectedTx = null
    this.selectionLocked = false

    this.lastTxTime = 0
    this.txDelay = 0

    this.blocksEnabled = true
    blocksEnabled.subscribe(enabled => {
      this.blocksEnabled = enabled
    })
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
    explorerBlockData.subscribe(blockData => {
      if (blockData) {
        this.exploreBlock(blockData)
      } else {
        this.resumeLatest()
      }
    })
  }

  getVertexData () {
    return this.vertexArray.getVertexData()
  }

  getDebugVertexData () {
    return this.debugVertexArray.getVertexData()
  }

  getScenes () {
    if (this.blockScene && this.explorerBlockScene) return [this.poolScene, this.blockScene, this.explorerBlockScene]
    else if (this.blockScene) return [this.poolScene, this.blockScene]
    else return [this.poolScene]
  }

  redoLayout ({ width, height }) {
    this.poolScene.layoutAll({ width, height })
    if (this.blockScene) {
      this.blockScene.layoutAll({ width: this.blockAreaSize, height: this.blockAreaSize })
    }
    if (this.explorerBlockScene) {
      this.explorerBlockScene.layoutAll({ width: this.blockAreaSize, height: this.blockAreaSize })
    }
  }

  resize ({ width, height }) {
    this.blockAreaSize = (width <= 620) ? Math.min(window.innerWidth * 0.7, window.innerHeight / 2.75) : Math.min(window.innerWidth * 0.75, window.innerHeight / 2.5)
    blockAreaSize.set(this.blockAreaSize)
    this.redoLayout({ width, height })
  }

  setColorMode (mode) {
    this.colorMode = mode
    this.poolScene.setColorMode(mode)
    if (this.blockScene) {
      this.blockScene.setColorMode(mode)
    }
    if (this.explorerBlockScene) {
      this.explorerBlockScene.setColorMode(mode)
    }
  }

  applyHighlighting () {
    this.poolScene.applyHighlighting(this.highlightCriteria)
    if (this.blockScene) {
      this.blockScene.applyHighlighting(this.highlightCriteria)
    }
    if (this.explorerBlockScene) {
      this.explorerBlockScene.applyHighlighting(this.highlightCriteria)
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
    if (this.txs[txid] && this.poolScene.drop(txid)) {
      this.txs[txid].view.update({
        display: {
          position: {
            y: -100, //this.txs[txid].screenPosition.y - 100
          },
          // color: {
          //   alpha: 0
          // }
        },
        delay: 0,
        duration: 2000
      })
      setTimeout(() => {
        this.destroyTx(txid)
      }, 2000)
      // this.poolScene.layoutAll()
    }
  }

  simulateBlock () {
    const time = Date.now() / 1000
    console.log('sim time ', time)
    this.addBlock({
      version: 'fake',
      id: Math.random(),
      value: 10000,
      prev_block: 'also_fake',
      merkle_root: 'merkle',
      timestamp: time,
      bits: 'none',
      txn_count: 20,
      fees: 100,
      txns: [{ version: 'fake', inflated: false, id: 'coinbase', value: 625000100, fee: 100, vbytes: 500, inputs:[{ prev_txid: '00000000000000000000000000000', prev_vout: 0, script_sig: '03e0170b04efb72c622f466f756e6472792055534120506f6f6c202364726f70676f6c642f0eb5059f0000000000000000',
        sequence_no: 0, value: 625000100, script_pub_key: "76a9145e9b23809261178723055968d134a947f47e799f88ac" }], outputs: [{ prev_txid: '00000000000000000000000000000', prev_vout: 0, script_sig: '03e0170b04efb72c622f466f756e6472792055534120506f6f6c202364726f70676f6c642f0eb5059f0000000000000000',
          sequence_no: 0, value: 625000100, script_pub_key: "76a9145e9b23809261178723055968d134a947f47e799f88ac" }], time: Date.now()
      }, ...Object.keys(this.txs).filter(() => {
        return (Math.random() < 0.5)
      }).map(key => {
        return {
          ...this.txs[key],
          inputs: this.txs[key].inputs.map(input => { return {...input, script_pub_key: null, value: null }}),
        }
      })]
    })
  }

  addBlock (blockData, realtime=true) {
    // discard duplicate blocks
    if (!blockData || !blockData.id || this.knownBlocks[blockData.id]) {
      return
    }

    let block
    block = new BitcoinBlock(blockData)

    latestBlockHeight.set(block.height)
    // this.knownBlocks[block.id] = true
    if (this.clearBlockTimeout) clearTimeout(this.clearBlockTimeout)

    this.expiredTxs = {}

    if (this.explorerBlockScene && this.explorerBlock && this.explorerBlock.id === block.id) {
      this.block = this.explorerBlock
      this.blockScene = this.explorerBlockScene
      this.explorerBlockScene = null
      this.explorerBlock = null
      urlPath.set("/")

      for (let i = 0; i < block.txns.length; i++) {
        this.txs[block.txns[i].id].setData(block.txns[i])
        this.poolScene.remove(block.txns[i].id)
      }
      this.poolScene.layoutAll()

      return
    }

    if (!this.explorerBlockScene) this.clearBlock()

    if (this.blocksEnabled) {
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
      this.blockScene.initialLayout(!!this.explorerBlockScene)
      setTimeout(() => { this.poolScene.scrollLock = false; this.poolScene.layoutAll() }, 4000)

      blockVisible.set(true)

      if (!this.explorerBlockScene) {
        currentBlock.set(block)
      }
    } else {
      this.poolScene.scrollLock = true
      for (let i = 0; i < block.txns.length; i++) {
        if (this.txs[block.txns[i].id] && this.txs[block.txns[i].id].view) {
          this.txs[block.txns[i].id].view.update({
            display: {
              color: this.txs[block.txns[i].id].getColor('block', 'age').color
            },
            duration: 1000,
            delay: 0,
            jitter: 0,
          })
        }
        this.expiredTxs[block.txns[i].id] = true
      }
      setTimeout(() => {
        for (let i = 0; i < block.txns.length; i++) {
          if (this.txs[block.txns[i].id] && this.txs[block.txns[i].id].view) {
            this.txs[block.txns[i].id].view.update({
              display: {
                position: { y: window.innerHeight + 50, r: 10 },
                color: { alpha: 0 }
              },
              duration: 3000,
              delay: 0,
              jitter: 1000,
            })
          }
          this.expiredTxs[block.txns[i].id] = true
        }
      }, 1500)
      setTimeout(() => {
        for (let i = 0; i < block.txns.length; i++) {
          this.poolScene.remove(block.txns[i].id)
        }
        this.poolScene.scrollLock = false
        this.poolScene.layoutAll()
      }, 5500)

      currentBlock.set(block)
    }

    this.block = block

    return block
  }

  async exploreBlock (blockData) {
    const block = blockData.isBlock ? blockData : new BitcoinBlock(blockData)

    if (this.block && this.block.id === block.id) {
      this.showBlock()
      return
    }

    let enterFromRight = false

    // clean up previous block
    if (this.explorerBlock && this.explorerBlockScene) {
      const prevBlock = this.explorerBlock
      const prevBlockScene = this.explorerBlockScene
      if (prevBlock.height < block.height) {
        prevBlockScene.exitLeft()
        enterFromRight = true
      }
      else prevBlockScene.exitRight()
      prevBlockScene.expire(2000)
    } else if (this.blockScene) {
      this.blockScene.exitRight()
    }

    this.explorerBlock = block

    if (this.blocksEnabled) {
      this.explorerBlockScene = new TxBlockScene({ width: this.blockAreaSize, height: this.blockAreaSize, blockId: block.id, controller: this, colorMode: this.colorMode })
      for (let i = 0; i < block.txns.length; i++) {
        const tx = new BitcoinTx({
          ...block.txns[i],
          block: block
        }, this.vertexArray)
        this.txs[tx.id] = tx
        this.txs[tx.id].applyHighlighting(this.highlightCriteria)
        this.explorerBlockScene.insert(tx, 0, false)
      }
      this.explorerBlockScene.prepareAll()
      this.explorerBlockScene.layoutAll()
      if (enterFromRight) {
        blockTransitionDirection.set('right')
        this.explorerBlockScene.enterRight()
      } else {
        blockTransitionDirection.set('left')
        this.explorerBlockScene.enterLeft()
      }
    }

    blockVisible.set(true)
    await tick()
    currentBlock.set(block)
  }

  async resumeLatest () {
    if (this.explorerBlock && this.explorerBlockScene) {
      const prevBlock = this.explorerBlock
      const prevBlockScene = this.explorerBlockScene
      prevBlockScene.exitLeft()
      prevBlockScene.expire(2000)
      this.explorerBlockScene = null
      this.explorerBlock = null
      urlPath.set("/")
    }
    if (this.blockScene && this.block) {
      blockTransitionDirection.set('right')
      await tick()
      this.blockScene.enterRight()
      currentBlock.set(this.block)
    }
  }

  async hideBlock () {
    if (this.blockScene && !this.explorerBlockScene) {
      blockTransitionDirection.set(null)
      await tick()
      this.blockScene.hide()
    }
  }

  showBlock () {
    if (this.blockScene && !this.explorerBlockScene) {
      this.blockScene.show()
    }
  }

  clearBlock () {
    if (this.blockScene) {
      this.blockScene.exitLeft()
      this.blockScene.expire()
    }
    this.block = null
    currentBlock.set(null)
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
      if (!selected && this.blockScene && !this.explorerBlock && !this.blockScene.hidden) selected = this.blockScene.selectAt(position)
      if (!selected && this.explorerBlockScene && this.explorerBlock && !this.explorerBlockScene.hidden) selected = this.explorerBlockScene.selectAt(position)

      if (selected !== this.selectedTx) {
        if (this.selectedTx) this.selectedTx.hoverOff()
        if (selected) selected.hoverOn()
      }
      this.selectedTx = selected
      selectedTx.set(this.selectedTx)
    }
  }

  async mouseClick (position) {
    if (this.poolScene) {
      let selected = this.poolScene.selectAt(position)
      if (!selected && this.blockScene && !this.explorerBlock && !this.blockScene.hidden) selected = this.blockScene.selectAt(position)
      if (!selected && this.explorerBlockScene && this.explorerBlock && !this.explorerBlockScene.hidden) selected = this.explorerBlockScene.selectAt(position)

      let sameTx = true
      if (selected !== this.selectedTx) {
        sameTx = false
        if (this.selectedTx) this.selectedTx.hoverOff()
        if (selected) selected.hoverOn()
      }
      this.selectedTx = selected
      selectedTx.set(selected)
      if (sameTx && selected) {
        if (!selected.is_inflated) {
          loading.increment()
          await searchTx(selected.id)
          loading.decrement()
        } else {
          const spendResult = await fetchSpends(selected.id)
          if (spendResult) selected = addSpends(selected, spendResult)
          urlPath.set(`/tx/${selected.id}`)
          detailTx.set(selected)
          overlay.set('tx')
        }
        console.log(selected)
      }
      this.selectionLocked = !!selected && !(this.selectionLocked && sameTx)
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
