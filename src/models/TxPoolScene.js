import config from '../config.js'

export default class TxPoolScene {
  constructor ({ width, height, unit, padding, layer, controller, heightStore }) {
    this.maxHeight = 0
    this.heightStore = heightStore
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

    if (config.dev) console.log('pool', this)
  }

  resize ({ width = this.width, height = this.height }) {
    this.width = width
    this.height = height
    this.heightLimit =  height / 4
    this.unitWidth = Math.floor(Math.max(4, width / 250))
    this.unitPadding =  Math.floor(Math.max(1, width / 1000))
    this.gridSize = this.unitWidth + (this.unitPadding * 2)
    this.blockWidth = (Math.floor(width / this.gridSize) - 1)
    this.blockHeight = (Math.floor(height / this.gridSize) - 1)

    this.scene.offset.x = (window.innerWidth - (this.blockWidth * this.gridSize)) / 2
    this.scene.offset.y = (window.innerHeight - (this.blockHeight * this.gridSize)) / 2
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
    if (tx.pixelPosition && (tx.pixelPosition.y + tx.pixelPosition.r) < -(this.scene.offset.y + 20)) {
      this.controller.destroyTx(tx.id)
    }
  }

  clearOffscreenTxs () {
    const ids = this.getTxList()
    for (let i = 0; i < ids.length; i++) {
      this.clearOffscreenTx(this.txs[ids[i]])
    }
  }

  redrawTx (tx, now) {
    if (tx && tx.view && tx.view.initialised) {
      this.saveGridToPixelPosition(tx)
      this.savePixelsToScreenPosition(tx)
      tx.view.update({
        display: {
          position: tx.screenPosition
        },
        duration: 1000,
        start: now,
        minDuration: 250,
        adjust: true
      })
    }
  }

  updateChunk (ids) {
    const now = performance.now()
    for (let i = 0; i < ids.length; i++) {
      this.redrawTx(this.txs[ids[i]], now)
    }
  }

  async doScroll (offset) {
    const ids = this.getTxList()
    this.scene.scroll += offset
    const processingChunks = []
    // Scrolling operation is potentially very costly, as we're calculating and updating positions of every active tx in the pool
    // So attempt to spread the cost over several frames, by separately processing chunks of 100 txs each
    // Schedule ~1 chunk per frame at the targeted framerate (60 fps, frame every 16.7ms)
    for (let i = 0; i < ids.length; i+=100) {
      processingChunks.push(new Promise((resolve, reject) => {
        setTimeout(() => {
          this.updateChunk(ids.slice(i, i+100))
          resolve()
        }, (i / 100) * 20)
      }))
    }
    await Promise.all(processingChunks)
    this.clearOffscreenTxs()
  }

  scroll (offset, force) {
    if (!this.scrollLock) this.doScroll(offset)
    else console.log("can't scroll - locked out!")
    // if (!this.scrollRateLimitTimer || force || performance.now() > (this.scrollRateLimitTimer + 1000)) {
    //   this.scrollRateLimitTimer = performance.now()
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
    this.place(tx, sequence, units)
    this.saveGridToPixelPosition(tx)
    const top = tx.pixelPosition.y + tx.pixelPosition.r
    const bottom = tx.pixelPosition.y - tx.pixelPosition.r
    if (top > this.maxHeight) {
      this.maxHeight = top
      if (this.heightStore) this.heightStore.set(this.maxHeight)
    }
    if (this.heightLimit && bottom > this.heightLimit) {
      this.scroll(this.heightLimit - bottom)
      this.maxHeight += (this.heightLimit - bottom)
      if (this.heightStore) this.heightStore.set(this.maxHeight)
      this.saveGridToPixelPosition(tx)
    }
    if (setOnScreen) this.setTxOnScreen(tx)
  }

  setTxOnScreen (tx) {
    if (!tx.view.initialised) {
      tx.view.update({
        display: {
          layer: this.layer,
          position: this.pixelsToScreen({
            x: tx.pixelPosition.x,
            y: window.innerHeight + 10,
            r: this.unitWidth / 2
          }),
          color: tx.highlight ? this.highlightColor : {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        delay: 0,
        state: 'ready'
      })
      tx.view.update({
        display: {
          layer: this.layer,
          position: this.pixelsToScreen(tx.pixelPosition),
          color: tx.highlight ? this.highlightColor : {
            palette: 0,
            index: 0,
            alpha: 1
          }
        },
        duration: 2500,
        delay: 0,
        state: 'pool'
      })
      tx.view.update({
        display: {
          color: tx.highlight ? this.highlightColor : {
            palette: 0,
            index: 1
          }
        },
        duration: 60000,
        delay: 0
      })
    } else {
      tx.view.update({
        display: {
          position: this.pixelsToScreen(tx.pixelPosition)
        },
        duration: 1500,
        minDuration: 1000,
        delay: 0,
        adjust: true
      })
    }
  }

  layoutAll (resize = {}) {
    this.maxHeight = 0
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
    let poolScreenTop = -Infinity
    ids = this.getActiveTxList()
    let tx
    for (let i = 0; i < ids.length; i++) {
      tx = this.txs[ids[i]]
      this.saveGridToPixelPosition(tx)
      poolTop = Math.max(poolTop, tx.pixelPosition.y - tx.pixelPosition.r)
      poolScreenTop = Math.max(poolScreenTop, tx.pixelPosition.y + tx.pixelPosition.r)
      poolBottom = Math.min(poolBottom, tx.pixelPosition.y - tx.pixelPosition.r)
    }

    this.maxHeight = poolScreenTop

    if (this.heightLimit && poolTop > this.heightLimit) {
      let scrollAmount = this.heightLimit - poolTop
      this.scroll(scrollAmount, true)
      this.maxHeight += scrollAmount
    } else if (this.heightLimit && poolTop < this.heightLimit) {
      let scrollAmount = Math.min(-this.scene.scroll, this.heightLimit - poolTop)
      this.scroll(scrollAmount, true)
      this.maxHeight += scrollAmount
    }
    if (this.heightStore) this.heightStore.set(this.maxHeight)
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

  saveGridToPixelPosition (tx) {
    const pixelRadius = (tx.gridPosition.r * this.gridSize / 2) - this.unitPadding
    tx.pixelPosition.x = ((this.gridSize * tx.gridPosition.x) + pixelRadius)
    tx.pixelPosition.y = ((this.gridSize * tx.gridPosition.y) + pixelRadius) + this.scene.scroll
    tx.pixelPosition.r = pixelRadius
  }

  gridToPixels (position) {
    const pixelRadius = (position.r * this.gridSize / 2) - this.unitPadding
    return {
      x: ((this.gridSize * position.x) + pixelRadius),
      y: ((this.gridSize * position.y) + pixelRadius) + this.scene.scroll,
      r: pixelRadius
    }
  }

  savePixelsToScreenPosition (tx, xOffset = 0, yOffset = 0) {
    tx.screenPosition.x = tx.pixelPosition.x + this.scene.offset.x + xOffset
    tx.screenPosition.y = (this.inverted ? this.height - tx.pixelPosition.y : tx.pixelPosition.y) + this.scene.offset.y + yOffset
    tx.screenPosition.r = tx.pixelPosition.r
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

  screenToGrid (position) {
    const pixels = {
      x: position.x - this.scene.offset.x,
      y: position.y - this.scene.offset.y + (this.unitPadding)
    }
    if (this.inverted) pixels.y = this.height - pixels.y
    const grid = {
      x: Math.floor(pixels.x / this.gridSize),
      y: Math.floor(((pixels.y - this.scene.scroll) / this.gridSize)), // not sure why we need this offset??
      r: 0
    }
    return grid
  }

  place (tx, position, size) {
    tx.gridPosition.x = 1 + Math.floor(position % this.blockWidth)
    tx.gridPosition.y = 1 + (Math.floor(position / this.blockWidth))
    tx.gridPosition.r = size
  }

  getVertexData () {
    // return Object.values(this.txs).slice(-1000).flatMap(tx => tx.view.sprite.getVertexData())
    return Object.values(this.txs).flatMap(tx => tx.view.sprite.getVertexData())
  }

  selectAt (position) {
    return null
  }
}
