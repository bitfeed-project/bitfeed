export default class TxPoolScene {
  constructor ({ width, height, unit, padding, layer, controller }) {
    this.init({ width, height, unit, padding, layer, controller })
  }

  init ({ width, height, unit = 8, padding = 1, layer, controller }) {
    this.controller = controller
    this.layer = layer
    this.resize({ width, height, unit, padding })
    this.txs = {}
    this.hiddenTxs = {}

    this.heightLimit =  Math.max(150, height / 4)
    this.heightBound = this.height - this.heightLimit
    this.poolTop = this.height
    this.poolBottom = this.height

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

    console.log('pool', this)
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

  getPoolHeight () {
    return this.poolBottom - this.poolTop
  }

  insert (tx, autoLayout=true) {
    if (autoLayout) {
      this.layoutTx(tx, this.scene.count++)
      this.txs[tx.id] = tx
    } else {
      this.hiddenTxs[tx.id] = tx
    }
  }

  clearOffscreenTx (tx) {
    const currentTargetPosition = tx.getPosition()
    if (currentTargetPosition && (currentTargetPosition.y + this.scene.scroll) > this.height + 150) {
      this.controller.destroyTx(tx.id)
    }
  }

  clearOffscreenTxs () {
    if (this.poolBottom + this.scene.scroll > (this.height + 150)) {
      const ids = this.getTxList()
      for (let i = 0; i < ids.length; i++) {
        this.clearOffscreenTx(this.txs[ids[i]])
      }
    }
  }

  scrollTx (tx, scrollDistance) {
    if (tx.view.initialised) {
      let currentTargetPosition = tx.getPosition()
      if (currentTargetPosition) {
        this.updateTx(tx, {
          display: {
            position: {
              y: currentTargetPosition.y + scrollDistance
            }
          },
          duration: 500,
          minDuration: 250,
          adjust: true
        })
      }
    }
  }

  doScroll (offset) {
    const ids = this.getTxList()
    this.scene.scroll -= offset
    for (let i = 0; i < ids.length; i++) {
      this.scrollTx(this.txs[ids[i]], this.scene.scroll)
    }
    this.clearOffscreenTxs()
  }

  scroll (offset, force) {
    if (!this.scrollRateLimitTimer || force || Date.now() > (this.scrollRateLimitTimer + 1000)) {
      this.scrollRateLimitTimer = Date.now()
      this.doScroll(offset)
    }
  }

  txSize (value) {
    // let scale = Math.log10(value)
    // let size = (scale*scale) / 5
    // let rounded = Math.pow(2, Math.ceil(Math.log2(size)))
    // return Math.max(4, rounded)
    return this.unitWidth
  }

  layoutTx (tx, sequence) {
    const rawPosition = this.place(tx.id, sequence)
    const scrolledPosition = {
      x: rawPosition.x,
      y: rawPosition.y + this.scene.scroll
    }
    tx.setPosition(rawPosition)
    if (this.heightLimit && scrolledPosition.y < this.heightBound) {
      this.scroll(scrolledPosition.y - this.heightBound)
      scrolledPosition.y = rawPosition.y + this.scene.scroll
    }
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: {
            x: scrolledPosition.x,
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
          position: scrolledPosition,
          // size: this.unitWidth,
          size: this.txSize(tx.value),
          color: {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        duration: 1500,
        delay: 0,
        state: 'pool'
      })
      this.updateTx(tx, {
        display: {
          color: {
            palette: 0,
            index: 1
          }
        },
        duration: 30000,
        delay: 0
      })
    } else {
      this.updateTx(tx, {
        display: {
          position: scrolledPosition
        },
        duration: 1000,
        minDuration: 1000,
        delay: 0,
        adjust: true
      })
    }
  }

  layoutAll () {
    this.scene.count = 0
    this.poolTop = Infinity
    this.poolBottom = -Infinity
    let ids = this.getHiddenTxList()
    for (let i = 0; i < ids.length; i++) {
      this.txs[ids[i]] = this.hiddenTxs[ids[i]]
      delete this.hiddenTxs[ids[i]]
    }
    ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      this.layoutTx(this.txs[ids[i]], this.scene.count++)
    }

    if (this.heightLimit && ((this.poolTop + this.scene.scroll) < this.heightBound)) {
      let scrollAmount = (this.poolTop + this.scene.scroll) - this.heightBound
      this.scroll(scrollAmount, true)
    } else if (this.heightLimit && ((this.poolTop + this.scene.scroll) > this.heightBound)) {
      let scrollAmount = Math.min(this.scene.scroll, (this.poolTop + this.scene.scroll) - this.heightBound)
      this.scroll(scrollAmount, true)
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
    const placement = {
      x: this.scene.offset.x + (this.paddedUnitWidth * (1 + Math.floor(position % this.blockWidth))),
      y: this.scene.offset.y + this.height - (this.paddedUnitWidth * (1 + (Math.floor(position / this.blockWidth))))
    }
    if (placement.y < this.poolTop) {
      this.poolTop = placement.y
    } else if (placement.y > this.poolBottom) {
      this.poolBottom = placement.y
    }
    return placement
  }

  getVertexData () {
    // return Object.values(this.txs).slice(-1000).flatMap(tx => tx.view.sprite.getVertexData())
    return Object.values(this.txs).flatMap(tx => tx.view.sprite.getVertexData())
  }
}
