export default class TxPoolScene {
  constructor ({ width, height, unit, padding, layer, controller }) {
    this.init({ width, height, unit, padding, layer, controller })
    this.highlightColor = {
      palette: 3,
      index: 0,
      alpha: 1
    }
  }

  init ({ width, height, layer, controller }) {
    this.controller = controller
    this.layer = layer

    this.inverted = false

    this.scene = {
      count: 0,
      scroll: 0,
      offset: {
        x: 0,
        y: 0
      }
    }

    this.resize({ width, height })
    this.txs = {}
    this.hiddenTxs = {}

    this.scrollRateLimitTimer = null
    this.initialised = true

    console.log('pool', this)
  }

  resize ({ width = this.width, height = this.height }) {
    this.width = width
    this.height = height
    this.heightLimit =  height / 4
    this.unitWidth = Math.floor(Math.max(4, width / 250))
    this.unitPadding = Math.floor(Math.max(1, width / 1000))
    this.gridSize = this.unitWidth + (this.unitPadding * 2)
    this.blockWidth = (Math.floor(width / this.gridSize) - 1)
    this.blockHeight = (Math.floor(height / this.gridSize) - 1)

    this.scene.offset.x = (window.innerWidth - (this.blockWidth * this.gridSize)) / 2
    this.scene.offset.y = (window.innerHeight - (this.blockHeight * this.gridSize)) / 2
  }

  updateTx (tx, update) {
    if (tx) tx.updateView(update)
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
    const pixelPosition = tx.getPixelPosition()
    if (pixelPosition && (pixelPosition.y + pixelPosition.r) < -(this.scene.offset.y + 20)) {
      this.controller.destroyTx(tx.id)
    }
  }

  clearOffscreenTxs () {
    const ids = this.getTxList()
    for (let i = 0; i < ids.length; i++) {
      this.clearOffscreenTx(this.txs[ids[i]])
    }
  }

  redrawTx (tx) {
    if (tx.view.initialised) {
      const pixelPosition = this.gridToPixels(tx.getGridPosition())
      tx.setPixelPosition(pixelPosition)
      this.updateTx(tx, {
        display: {
          position: this.pixelsToScreen(pixelPosition)
        },
        duration: 500,
        minDuration: 250,
        adjust: true
      })
    }
  }

  doScroll (offset) {
    const ids = this.getTxList()
    this.scene.scroll += offset
    for (let i = 0; i < ids.length; i++) {
      this.redrawTx(this.txs[ids[i]])
    }
    this.clearOffscreenTxs()
  }

  scroll (offset, force) {
    this.doScroll(offset)
    // if (!this.scrollRateLimitTimer || force || Date.now() > (this.scrollRateLimitTimer + 1000)) {
    //   this.scrollRateLimitTimer = Date.now()
    //   this.doScroll(offset)
    //   return true
    // } else return false
  }

  // calculates and returns the size of the tx in multiples of the grid size
  txSize (value) {
    // let scale = Math.log10(value)
    // let size = (scale*scale) / 5
    // let rounded = Math.pow(2, Math.ceil(Math.log2(size)))
    // return Math.max(4, rounded)
    return 1
  }

  layoutTx (tx, sequence, setOnScreen = true) {
    const units = this.txSize(tx.value)
    const gridPosition = this.place(tx.id, sequence, units)
    let pixelPosition = this.gridToPixels(gridPosition)
    tx.setGridPosition(gridPosition)
    if (this.heightLimit && (pixelPosition.y - pixelPosition.r) > this.heightLimit) {
      this.scroll(this.heightLimit - (pixelPosition.y - pixelPosition.r))
      pixelPosition = this.gridToPixels(gridPosition)
    }
    tx.setPixelPosition(pixelPosition)
    if (setOnScreen) this.setTxOnScreen(tx, pixelPosition)
    return pixelPosition
  }

  setTxOnScreen (tx, pixelPosition) {
    if (!tx.view.initialised) {
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: this.pixelsToScreen({
            x: pixelPosition.x,
            y: window.innerHeight + 10,
            r: this.unitWidth / 2
          }),
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
      this.updateTx(tx, {
        display: {
          layer: this.layer,
          position: this.pixelsToScreen(pixelPosition),
          color: tx.highlight ? this.highlightColor : {
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
          color: tx.highlight ? this.highlightColor : {
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
          position: this.pixelsToScreen(pixelPosition)
        },
        duration: 1000,
        minDuration: 1000,
        delay: 0,
        adjust: true
      })
    }
  }

  layoutAll (resize = {}) {
    this.resize(resize)
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

    let poolTop = -Infinity
    let poolBottom = Infinity
    ids = this.getActiveTxList()
    for (let i = 0; i < ids.length; i++) {
      const position = this.gridToPixels(this.txs[ids[i]].getGridPosition())
      poolTop = Math.max(poolTop, position.y - position.r)
      poolBottom = Math.min(poolBottom, position.y - position.r)
    }


    if (this.heightLimit && poolTop > this.heightLimit) {
      let scrollAmount = this.heightLimit - poolTop
      this.scroll(scrollAmount, true)
    } else if (this.heightLimit && poolTop < this.heightLimit) {
      let scrollAmount = Math.min(-this.scene.scroll, this.heightLimit - poolTop)
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

  gridToPixels (position) {
    const pixelRadius = (position.r * this.gridSize / 2) - this.unitPadding
    return {
      x: (this.gridSize * (position.x) + pixelRadius),
      y: (this.gridSize * (position.y) + pixelRadius) + this.scene.scroll,
      r: pixelRadius
    }
  }

  pixelsToScreen (position) {
    // if (this.inverted) {
    const screenPosition = {
      ...position
    }
    if (this.inverted) screenPosition.y = this.height - screenPosition.y
    screenPosition.x += this.scene.offset.x
    screenPosition.y += this.scene.offset.y
    return screenPosition
  }

  place (id, position, size) {
    const placement = {
      x: 1 + Math.floor(position % this.blockWidth),
      y: 1 + (Math.floor(position / this.blockWidth)),
      r: size
    }
    return placement
  }

  getVertexData () {
    // return Object.values(this.txs).slice(-1000).flatMap(tx => tx.view.sprite.getVertexData())
    return Object.values(this.txs).flatMap(tx => tx.view.sprite.getVertexData())
  }
}
