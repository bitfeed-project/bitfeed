import TxMondrianPoolScene from './TxMondrianPoolScene.js'
import { settings } from '../stores.js'
import { logTxSize, byteTxSize } from '../utils/misc.js'
import { orange } from '../utils/color.js'
import config from '../config.js'

let settingsValue
settings.subscribe(v => {
  settingsValue = v
})

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
        y: 2 * (window.innerHeight - this.height) / ((window.innerWidth <= 640) ? 3.5 : 3)
      }
      this.scene.scroll = 0
    } else {
      this.width = width
      this.height = height
    }

    this.resetLayout()
  }

  // calculates and returns the size of the tx in multiples of the grid size
  txSize (tx={ value: 1, vbytes: 1 }) {
    if (settingsValue.vbytes) return byteTxSize(tx.vbytes, Math.Infinity)
    else return logTxSize(tx.value, Math.Infinity)
  }

  setTxOnScreen (tx, pixelPosition) {
    this.saveGridToPixelPosition(tx)
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

    this.savePixelsToScreenPosition(tx, 0, (this.hidden && !this.exited) ? 50 : 0)
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
        delay: 50,
        jitter: this.laidOut ? 500 : 1500,
        smooth: true,
        state: 'block'
      })
    }
  }

  prepareTxOnScreen (tx, now) {
    const oldRadius = tx.pixelPosition.r
    this.saveGridToPixelPosition(tx)
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
    } else {
      const jitter = (Math.random() * 1700)
      tx.view.update({
        display: {
          position: {
            r: oldRadius + Math.max(2, oldRadius * 0.2)
          },
        },
        delay: 50 + jitter,
        start: now,
        duration: 750,
        smooth: true,
        boomerang: true
      })
      tx.view.update({
        display: {
          color: settingsValue.darkMode && false ? {
            h: 0.8,
            l: 1.0
          } : orange,
        },
        start: now,
        delay: 50 + jitter,
        duration: 500,
      })
    }
  }

  prepareTx (tx, sequence) {
    this.place(tx)
    this.prepareTxOnScreen(tx)
  }

  enterTx (tx, start, right) {
    tx.view.update({
      display: {
        position: {
          x: tx.screenPosition.x + (right ? window.innerWidth : -window.innerWidth) + ((Math.random()-0.5) * (window.innerHeight/4)),
          y: tx.screenPosition.y + ((Math.random()-0.5) * (window.innerHeight/4)),
          r: tx.pixelPosition.r
        },
        color: {
          ...tx.getColor('block', this.colorMode).color,
          alpha: 0
        }
      },
      delay: 0,
      state: 'ready'
    })
    tx.view.update({
      display: {
        position: tx.screenPosition,
        color: {
          ...tx.getColor('block', this.colorMode).color,
          alpha: 1
        }
      },
      start,
      duration: 2000,
      delay: 100,
      jitter: 500,
      smooth: true,
    })
  }

  enter (right) {
    this.hidden = false
    this.exited = false
    const ids = this.getActiveTxList()
    const start = performance.now()
    for (let i = 0; i < ids.length; i++) {
      this.enterTx(this.txs[ids[i]], start, right)
    }
  }

  enterRight () {
    this.enter(true)
  }

  enterLeft () {
    this.enter(false)
  }

  exitTx (tx, start, right) {
    tx.view.update({
      display: {
        position: {
          x: tx.screenPosition.x + (right ? window.innerWidth : -window.innerWidth) + ((Math.random()-0.5) * (window.innerHeight/4)),
          y: tx.screenPosition.y + ((Math.random()-0.5) * (window.innerHeight/4)),
          r: tx.pixelPosition.r
        },
        color: {
          ...tx.getColor('block', this.colorMode).color,
          alpha: 0
        }
      },
      delay: 100,
      start,
      jitter: 500,
      duration: 2000,
      smooth: true,
    })
  }

  exit (right) {
    this.hidden = true
    this.exited = true
    const ids = this.getActiveTxList()
    const start = performance.now()
    for (let i = 0; i < ids.length; i++) {
      this.exitTx(this.txs[ids[i]], start, right)
    }
  }

  exitRight () {
    this.exit(true)
  }

  exitLeft () {
    this.exit(false)
  }

  hideTx (tx, now) {
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
      start: now,
      duration: 1500,
      delay: 50,
      state: 'fadeout',
      smooth: true,
    })
  }

  showTx (tx, now) {
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
      start: now,
      duration: 1500,
      delay: 50,
      state: 'fadeout',
      smooth: true,
    })
  }

  prepareAll () {
    const now = performance.now()
    this.resize({})
    this.scene.count = 0
    let ids = this.getHiddenTxList()
    for (let i = 0; i < ids.length; i++) {
      this.txs[ids[i]] = this.hiddenTxs[ids[i]]
      delete this.hiddenTxs[ids[i]]
    }
    ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.prepareTx(this.txs[ids[i]], now)
    }
  }

  layoutAll (args) {
    // if (!this.hidden) {
      super.layoutAll(args)
      this.laidOut = true
    // }
  }

  initialLayout (exited) {
    this.prepareAll()
    setTimeout(() => {
      this.layoutAll()
      if (exited) this.exitRight()
    }, 3000)
  }

  resetScroll () {
    return
  }

  hide () {
    this.hidden = true
    const now = performance.now()
    const ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.hideTx(this.txs[ids[i]], now)
    }
  }

  show () {
    if (this.hidden) {
      this.hidden = false
      const now = performance.now()
      const ids = this.getActiveTxList()
      for (let i = 0; i < ids.length; i++) {
        this.showTx(this.txs[ids[i]], now)
      }
    }
  }

  expire (delay=3000) {
    this.expired = true
    const txIds = this.getTxList()
    for (let i = 0; i < txIds.length; i++) {
      if (this.txs[txIds[i]]) {
        this.controller.deleteTx(txIds[i])
      }
    }
    setTimeout(() => {
      for (let i = 0; i < txIds.length; i++) {
        if (this.txs[txIds[i]]) {
          this.txs[txIds[i]].destroy()
        }
      }
      this.layout.destroy()
    }, delay)
  }

  selectAt (position) {
    if (this.layout) {
      const gridPosition = this.screenToGrid({ x: position.x + (this.gridSize/4), y: position.y - (this.gridSize/2) })
      return this.layout.getTxInGridCell(gridPosition)
    } else return null
  }
}
