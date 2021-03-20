import TxMondrianPoolScene from './TxMondrianPoolScene.js'

export default class TxBlockScene extends TxMondrianPoolScene {
  constructor ({ width, height, unit = 4, padding = 1, layer, blockId, controller }) {
    super({ width, height, unit, padding, layer, controller })
    this.heightLimit = null
    this.expired = false
    this.layedOut = false
    this.blockId = blockId
    this.initialised = true
  }

  resize ({ width = this.width, height = this.height }) {
    if (this.initialised) {
      let blockWeight = 0
      const ids = this.getTxList()
      for (let i = 0; i < ids.length; i++) {
        let squareSize = 0
        if (this.txs[ids[i]]) squareSize = this.txSize(this.txs[ids[i]].value || 1)
        else if (this.hiddenTxs[ids[i]]) squareSize = this.txSize(this.hiddenTxs[ids[i]].value || 1)
        blockWeight += (squareSize * squareSize)
      }

      console.log(`Resizing block: ${ids.length} txs, total weight: ${blockWeight}`)

      this.width = width
      this.height = height
      this.blockWidth = Math.ceil(Math.sqrt(blockWeight))
      this.blockHeight = this.blockWidth

      this.paddedUnit
      this.gridSize = width / this.blockWidth
      this.unitPadding = this.gridSize / 4
      this.unitWidth = this.gridSize - (this.unitPadding * 2)

      console.log(`Resized block: ${this.unitWidth}, ${this.unitPadding}, ${this.gridSize}`)

      this.scene.offset = {
        x: (window.innerWidth - this.width) / 2,
        y: (window.innerHeight - this.height) / 2
      }
      this.scene.scroll = 0
    } else {
      this.width = width
      this.height = height
    }

    this.resetLayout()
  }

  setTxOnScreen (tx, screenPosition) {
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: ((screenPosition.x - this.scene.offset.x) / this.width) * window.innerWidth,
            y: screenPosition.y - this.height - 20
          },
          color: tx.highlight ? this.highlightColor : {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        duration: 1500,
        delay: 0,
        state: 'ready'
      })
    }

    this.updateTx(tx, {
      display: {
        position: screenPosition,
        color: tx.highlight ? this.highlightColor : {
          palette: 0,
          index: 0,
          alpha: 1
        }
      },
      duration: 1500,
      delay: 0,
      state: 'block'
    })
  }

  prepareTxOnScreen (tx, screenPosition) {
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: ((screenPosition.x - this.scene.offset.x) / this.width) * window.innerWidth,
            y: screenPosition.y - (window.innerHeight + 20),
            r: screenPosition.r
          },
          color: tx.highlight ? this.highlightColor : {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        duration: 1500,
        delay: 0,
        state: 'ready'
      })
    }
    this.updateTx(tx, {
      display: {
        layer: this.layer,
        color: tx.highlight ? this.highlightColor : {
          palette: 0,
          index: 0,
          alpha: 1
        }
      },
      duration: 2000,
      delay: 0
    })
  }

  prepareTx (tx, sequence) {
    const screenPosition = this.layoutTx(tx, sequence, false)
    this.prepareTxOnScreen(tx, screenPosition)
  }

  expireTx (tx) {
    const screenPosition = tx.getScreenPosition()
    this.updateTx(tx, {
      display: {
        position: {
          y: screenPosition.y + 50
        },
        color: {
          alpha: 0
        }
      },
      duration: 2000,
      delay: 0,
      state: 'fadeout'
    })
  }

  prepareAll () {
    this.resize({})
    this.scene.count = 0
    let ids = this.getHiddenTxList()
    for (let i = 0; i < ids.length; i++) {
      this.txs[ids[i]] = this.hiddenTxs[ids[i]]
      delete this.hiddenTxs[ids[i]]
    }
    ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.prepareTx(this.txs[ids[i]], this.scene.count++)
    }
  }

  initialLayout () {
    this.prepareAll()
    setTimeout(() => {
      this.layoutAll()
    }, 3000)
  }

  expire () {
    this.expired = true
    const ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.expireTx(this.txs[ids[i]])
    }
    setTimeout(() => {
      const txIds = this.getTxList()
      for (let i = 0; i < txIds.length; i++) {
        if (this.txs[txIds[i]]) this.controller.destroyTx(txIds[i])
      }
      this.layout.destroy()
      this.controller.destroyBlock(this.blockId)
    }, 3000)
  }
}
