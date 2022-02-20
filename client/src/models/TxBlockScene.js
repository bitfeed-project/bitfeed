import TxMondrianPoolScene from './TxMondrianPoolScene.js'

export default class TxBlockScene extends TxMondrianPoolScene {
  constructor ({ width, height, unit = 4, padding = 1, blockId, controller, heightStore, colorMode }) {
    super({ width, height, unit, padding, controller, heightStore, colorMode })
    this.heightLimit = null
    this.expired = false
    this.laidOut = false
    this.blockId = blockId
    this.initialised = true
    this.inverted = true
    this.hidden = false
    this.sceneType = 'block'
  }

  resize ({ width = this.width, height = this.height }) {
    if (this.initialised) {
      let blockWeight = 0
      const ids = this.getTxList()
      for (let i = 0; i < ids.length; i++) {
        let squareSize = 0
        if (this.txs[ids[i]]) squareSize = this.txSize(this.txs[ids[i]])
        else if (this.hiddenTxs[ids[i]]) squareSize = this.txSize(this.hiddenTxs[ids[i]])
        blockWeight += (squareSize * squareSize)
      }

      this.width = width
      this.height = height
      this.blockWidth = Math.ceil(Math.sqrt(blockWeight))
      this.blockHeight = this.blockWidth

      this.paddedUnit
      this.gridSize = width / this.blockWidth
      this.unitPadding = this.gridSize / 4
      this.unitWidth = this.gridSize - (this.unitPadding * 2)

      this.scene.offset = {
        x: (window.innerWidth - this.width) / 2,
        y: 2 * (window.innerHeight - this.height) / 3
      }
      this.scene.scroll = 0
    } else {
      this.width = width
      this.height = height
    }

    this.resetLayout()
  }

  setTxOnScreen (tx, pixelPosition) {
    if (!tx.view.initialised) {
      tx.view.update({
        display: {
          position: {
            x: Math.random() * window.innerWidth,
            y: -(Math.random() * window.innerWidth) - (this.scene.offset.y * 2) - pixelPosition.r,
            r: pixelPosition.r
          },
          color: tx.getColor('block', this.colorMode).color
        },
        delay: 0,
        state: 'ready'
      })
    }

    this.savePixelsToScreenPosition(tx, 0, this.hidden ? 50 : 0)
    if (this.hidden) {
      tx.view.update({
        display: {
          position: tx.screenPosition,
          color: tx.getColor('block', this.colorMode).color
        },
        duration: 0,
        delay: 0,
        state: 'block'
      })
    } else {
      tx.view.update({
        display: {
          position: tx.screenPosition,
          color: tx.getColor('block', this.colorMode).color
        },
        duration: this.laidOut ? 1000 : 2000,
        delay: 0,
        jitter: this.laidOut ? 0 : 1500,
        state: 'block'
      })
    }
  }

  prepareTxOnScreen (tx) {
    if (!tx.view.initialised) {
      tx.view.update({
        display: {
          position: {
            x: Math.random() * window.innerWidth,
            y: -(Math.random() * window.innerWidth) - (this.scene.offset.y * 2) - tx.pixelPosition.r,
            r: tx.pixelPosition.r
          },
          color: {
            ...tx.getColor('block', this.colorMode).color,
            alpha: 1
          }
        },
        delay: 0,
        state: 'ready'
      })
    }
    tx.view.update({
      display: {
      color: tx.getColor('block', this.colorMode).color
      },
      duration: 2000,
      delay: 0
    })
  }

  prepareTx (tx, sequence) {
    this.prepareTxOnScreen(tx, this.layoutTx(tx, sequence, 0, false))
  }

  hideTx (tx) {
    this.savePixelsToScreenPosition(tx)
    tx.view.update({
      display: {
        position: {
          y: tx.screenPosition.y + 50
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

  showTx (tx) {
    this.savePixelsToScreenPosition(tx)
    tx.view.update({
      display: {
        position: {
          y: tx.screenPosition.y
        },
        color: {
          alpha: 1
        }
      },
      duration: 500,
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

  layoutAll (args) {
    // if (!this.hidden) {
      super.layoutAll(args)
      this.laidOut = true
    // }
  }

  initialLayout () {
    this.prepareAll()
    setTimeout(() => {
      this.layoutAll()
    }, 3000)
  }

  hide () {
    this.hidden = true
    const ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.hideTx(this.txs[ids[i]])
    }
  }

  show () {
    if (this.hidden) {
      this.hidden = false
      const ids = this.getActiveTxList()
      for (let i = 0; i < ids.length; i++) {
        this.showTx(this.txs[ids[i]])
      }
    }
  }

  expire () {
    this.expired = true
    this.hide()
    setTimeout(() => {
      const txIds = this.getTxList()
      for (let i = 0; i < txIds.length; i++) {
        if (this.txs[txIds[i]]) this.controller.destroyTx(txIds[i])
      }
      this.layout.destroy()
    }, 3000)
  }
}
