import TxPoolScene from './TxPoolScene.js'

export default class TxBlockScene extends TxPoolScene {
  constructor ({ width, height, unit = 4, padding = 1, layer, blockId, controller }) {
    super({ width, height, unit, padding, layer, controller })
    this.heightLimit = null
    this.expired = false
    this.layedOut = false
    this.blockId = blockId
  }

  resize ({ width, height, unit, padding }) {
    if (this.initialised) {
      this.unitWidth = unit || this.unitWidth || 4
      this.unitPadding = padding || this.unitPadding || 1
      this.paddedUnitWidth = this.unitWidth + (this.unitPadding * 2)
      console.log(`Resizing block: ${this.unitWidth}, ${this.unitPadding}, ${this.paddedUnitWidth}`)
      let txCount = this.getTxList().length
      this.blockWidth = Math.ceil(Math.sqrt(txCount))
      this.blockHeight = this.blockWidth
      this.width = (this.blockWidth + 1) * this.paddedUnitWidth
      this.height = (this.blockHeight + 1) * this.paddedUnitWidth
      this.scene.offset = {
        x: (window.innerWidth - this.width) / 2,
        y: (window.innerHeight - this.height) / 2
      }
      this.scene.scroll = 0
    }
  }

  layoutTx (tx, sequence) {
    const position = this.place(tx.id, sequence)
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: window.innerWidth * ((position.x - this.scene.offset.x) / this.width),
            y: window.innerHeight * (1 + ((position.y - this.scene.offset.y) / this.height))
          },
          size: 8,
          color: {
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
        position,
        size: 4,
        color: {
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

  prepareTx (tx, sequence) {
    const position = this.place(tx.id, sequence)
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: window.innerWidth * ((position.x - this.scene.offset.x) / this.width),
            y: window.innerHeight * (1 + ((position.y - this.scene.offset.y) / this.height))
          },
          size: 8,
          color: {
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
        color: {
          palette: 0,
          index: 0,
          alpha: 1
        }
      },
      duration: 2000,
      delay: 0
    })
  }

  expireTx (tx) {
    this.updateTx(tx, {
      display: {
        size: 30,
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

  layoutAll () {
    this.resize({})
    super.layoutAll()
  }

  initialLayout () {
    this.prepareAll()
    setTimeout(() => {
      this.layoutAll()
    }, 2000)
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
      this.controller.destroyBlock(this.blockId)
    }, 3000)
  }
}
