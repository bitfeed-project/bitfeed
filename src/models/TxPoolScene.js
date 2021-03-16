export default class TxPoolScene {
  constructor ({ width, height, unit, padding, layer }) {
    this.init({ width, height, unit, padding, layer })
  }

  init ({ width, height, unit = 8, padding = 1, layer }) {
    this.layer = layer
    this.resize({ width, height, unit, padding })
    this.txs = {}
    this.hiddenTxs = {}
    this.heightLimit = this.height - 50
    this.scene = {
      width: width,
      height: height,
      count: 0,
      scroll: 0,
      offset: {
        x: 0,
        y: 0
      }
    }
    this.scrollRateLimitTimer = null
    this.initialised = true
  }

  resize ({ width, height, unit, padding }) {
    this.width = width
    this.height = height
    this.unitWidth = unit || this.unitWidth
    this.unitPadding = padding || this.unitPadding
    this.paddedUnitWidth = this.unitWidth + (this.unitPadding * 2)
    this.blockWidth = (Math.floor(width / this.paddedUnitWidth) - 1)
    this.blockHeight = (Math.floor(height / (this.paddedUnitWidth * 2)) - 1)
  }

  updateTx (tx, update) {
    if (tx) tx.updateView(update)
  }

  scroll (offset) {
    if (!this.scrollRateLimitTimer || Date.now() < (this.scrollRateLimitTimer + 10000)) {
      console.log(`scrolling pool by ${offset}`)
      this.scrollRateLimitTimer = Date.now()
      this.doScroll(offset)
    } else {
      console.log('scroll recharging')
    }
  }

  insert (tx, autoLayout=true) {
    if (autoLayout) {
      this.layoutTx(tx, this.scene.count++)
      this.txs[tx.id] = tx
    } else {
      this.hiddenTxs[tx.id] = tx
    }
  }

  scrollTx (tx, scrollDistance) {
    if (tx.view.initialised) {
      let currentPosition = tx.getPosition()
      this.updateTx(tx, {
        display: {
          position: {
            y: currentPosition.y + scrollDistance
          }
        }
      })
    }
  }

  doScroll (offset) {
    const ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.scrollTx(this.txs[ids[i]], offset)
    }
    this.scene.scroll -= offset
  }

  layoutTx (tx, sequence) {
    const position = this.place(tx.id, sequence)
    // if (this.heightLimit && position.y < this.heightLimit) this.scroll(position.y - this.heightLimit)
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: position.x,
            y: 0
          },
          size: this.unitWidth,
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
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position,
          size: this.unitWidth,
          color: {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        duration: 1500,
        delay: 0,
        state: 'entering',
        next: {
          display: {
            color: {
              palette: 0,
              index: 1
            }
          },
          duration: 30000,
          delay: 100,
          state: 'colorfade',
          next: {
            display: {},
            state: 'pool'
          }
        }
      })
    } else {
      const shuffleUpdate = {
        display: {
          position
        },
        duration: 1000,
        delay: 0,
        state: 'shuffling',
        next: {
          display: {
            color: {
              index: 1
            }
          },
          state: 'colorfade',
          duration: 15000,
          delay: 100
        }
      }
      // if (tx.view.state === 'pool' || tx.view.state === 'colorfade') {
      //   this.updateTx(tx, {
      //     display: {
      //       layer: this.layer
      //     },
      //     duration: 2000,
      //     delay: 0,
      //     state: 'pause',
      //     next: shuffleUpdate
      //   })
      // } else {
        this.updateTx(tx, shuffleUpdate)
      // }
    }
  }

  layoutAll () {
    this.scene.count = 0
    let ids = this.getHiddenTxList()
    for (let i = 0; i < ids.length; i++) {
      this.txs[ids[i]] = this.hiddenTxs[ids[i]]
      delete this.hiddenTxs[ids[i]]
    }
    ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.layoutTx(this.txs[ids[i]], this.scene.count++)
    }
  }

  remove (id) {
    let exists = !!this.txs[id]
    delete this.txs[id]
    return exists
  }

  getTxList () {
    return [
      ...this.getActiveTxList(),
      ...this.getHiddenTxList()
    ]
  }

  getActiveTxList () {
    if (this.txs) return Object.keys(this.txs)
    else return []
  }

  getHiddenTxList () {
    if (this.txs) return Object.keys(this.hiddenTxs)
    else return []
  }

  place (id, position) {
    return {
      x: this.scene.offset.x + (this.paddedUnitWidth * (1 + Math.floor(position % this.blockWidth))),
      y: this.scene.offset.y + this.height - (this.paddedUnitWidth * (0.5 + (Math.floor(position / this.blockWidth)))) + this.scene.scroll
    }
  }

  getVertexData () {
    // return Object.values(this.txs).slice(-1000).flatMap(tx => tx.view.sprite.getVertexData())
    return Object.values(this.txs).flatMap(tx => tx.view.sprite.getVertexData())
  }
}
