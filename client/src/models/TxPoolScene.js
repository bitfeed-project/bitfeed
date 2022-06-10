import config from '../config.js'

export default class TxPoolScene {
  constructor ({ width, height, unit, padding, controller, heightStore, colorMode }) {
    this.colorMode = colorMode || "age"
    this.maxHeight = 0
    this.heightStore = heightStore
    this.sceneType = 'pool'
    this.init({ width, height, unit, padding, controller })
  }

  init ({ width, height, controller }) {
    this.controller = controller

    this.inverted = false

    this.scene = {
      count: 0,
      scroll: 0,
      offset: {
        x: 0,
        y: 0
      }
    }
    this.lastScroll = performance.now()

    this.resize({ width, height })
    this.txs = {}
    this.hiddenTxs = {}

    this.scrollRateLimitTimer = null
    this.initialised = true
  }

  resize ({ width = this.width, height = this.height }) {
    this.width = width
    this.height = height
    this.heightLimit =  (width <= 620) ? (height / 4.5) : (height / 4)
    this.unitWidth = Math.floor(Math.max(4, width / 250))
    this.unitPadding =  Math.floor(Math.max(1, width / 1000))
    this.gridSize = this.unitWidth + (this.unitPadding * 2)
    this.blockWidth = (Math.floor(width / this.gridSize) - 1)
    this.blockHeight = (Math.floor(height / this.gridSize) - 1)

    this.scene.offset.x = (window.innerWidth - (this.blockWidth * this.gridSize)) / 2
    this.scene.offset.y = (window.innerHeight - (this.blockHeight * this.gridSize)) / 2
  }

  setColorMode (mode) {
    this.colorMode = mode
    Object.values(this.txs).forEach(tx => {
      const txColor = tx.getColor(this.sceneType, mode)
      if (txColor.endColor) {
        tx.view.update({
          display: {
            color: txColor.color
          },
          duration: 0,
          delay: 0,
        })
        tx.view.update({
          display: {
            color: txColor.endColor
          },
          start: tx.enteredTime,
          duration: txColor.duration,
          delay: 0
        })
      } else {
        tx.view.update({
          display: {
            color: txColor.color
          },
          duration: 500,
          delay: 0,
        })
      }
    })
  }

  insert (tx, insertDelay, autoLayout=true) {
    if (autoLayout) {
      this.txs[tx.id] = tx
      this.place(tx)
      if (this.checkTxScroll(tx)) {
        this.applyTxScroll(tx)
      }
      this.setTxOnScreen(tx, insertDelay)
    } else {
      this.hiddenTxs[tx.id] = tx
    }
  }

  clearOffscreenTx (tx) {
    if (tx.pixelPosition && (tx.pixelPosition.y + tx.pixelPosition.r) < -(this.scene.offset.y + 100)) {
      this.controller.destroyTx(tx.id)
    }
  }

  clearOffscreenTxs () {
    const ids = this.getTxList()
    for (let i = 0; i < ids.length; i++) {
      this.clearOffscreenTx(this.txs[ids[i]])
    }
    this.clearTimer = null
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
        minDuration: 500,
        start: now,
        delay: 50,
        smooth: true,
        adjust: true
      })
    }
  }

  // updateChunk (ids, now = performance.now()) {
  //   for (let i = 0; i < ids.length; i++) {
  //     this.redrawTx(this.txs[ids[i]], now)
  //   }
  // }

  async doScroll (offset) {
    const now = performance.now()
    if (now - this.lastScroll > 1000) {
      this.lastScroll = now
      const ids = this.getTxList()
      this.scene.scroll += offset
      this.maxHeight += offset
      if (this.heightStore) this.heightStore.set(this.maxHeight)

      for (let i = 0; i < ids.length; i++) {
        this.redrawTx(this.txs[ids[i]], now)
      }

      if (!this.clearTimer) {
        this.clearTimer = setTimeout(() => {
          this.clearOffscreenTxs()
        }, 1500)
      }
    }
  }

  scroll (offset, force) {
    if (!this.scrollLock) this.doScroll(offset)
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

  checkTxScroll (tx, insertDelay, setOnScreen = true) {
    this.saveGridToPixelPosition(tx)
    const top = tx.pixelPosition.y + tx.pixelPosition.r
    const bottom = tx.pixelPosition.y - tx.pixelPosition.r
    if (top > this.maxHeight) {
      this.maxHeight = top
      if (this.heightStore) this.heightStore.set(this.maxHeight)
    }
    return (this.heightLimit && bottom > this.heightLimit)
  }

  applyTxScroll (tx) {
    const bottom = tx.pixelPosition.y - tx.pixelPosition.r
    this.scroll(this.heightLimit - bottom)
  }

  setTxOnScreen (tx, insertDelay=0) {
    this.saveGridToPixelPosition(tx)
    this.savePixelsToScreenPosition(tx)
    if (!tx.view.initialised) {
      const txColor = tx.getColor(this.sceneType, this.colorMode)
      tx.view.update({
        display: {
          position: this.pixelsToScreen({
            x: tx.pixelPosition.x,
            y: window.innerHeight + 10,
            r: this.unitWidth / 2
          }),
          color: {
            ...txColor.color,
            alpha: 1
          },
        },
        delay: 0,
        state: 'ready'
      })
      tx.view.update({
        display: {
          position: tx.screenPosition,
          color: txColor.color
        },
        duration: 2500,
        delay: insertDelay,
        state: 'pool'
      })
      if (txColor.endColor) {
        tx.view.update({
          display: {
            color: txColor.endColor
          },
          start: tx.enteredTime,
          duration: txColor.duration,
          delay: 0
        })
      }
    } else {
      tx.view.update({
        display: {
          position: tx.screenPosition
        },
        duration: 1000,
        minDuration: 500,
        delay: 50,
        jitter: 500,
        smooth: true,
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
      this.place(this.txs[ids[i]])
      this.saveGridToPixelPosition(this.txs[ids[i]])
    }

    this.resetScroll()

    for (let i = 0; i < ids.length; i++) {
      this.setTxOnScreen(this.txs[ids[i]])
    }
  }

  resetScroll () {
    const ids = this.getActiveTxList()
    let poolTop = -Infinity
    let poolBottom = Infinity
    let poolScreenTop = -Infinity
    let tx
    for (let i = 0; i < ids.length; i++) {
      tx = this.txs[ids[i]]
      // this.saveGridToPixelPosition(tx)
      poolTop = Math.max(poolTop, tx.pixelPosition.y - tx.pixelPosition.r)
      poolScreenTop = Math.max(poolScreenTop, tx.pixelPosition.y + tx.pixelPosition.r)
      poolBottom = Math.min(poolBottom, tx.pixelPosition.y - tx.pixelPosition.r)
    }

    this.maxHeight = poolScreenTop
    let scrollAmount = Math.min(-this.scene.scroll, this.heightLimit - poolTop)

    this.scene.scroll += scrollAmount
    this.maxHeight += scrollAmount

    if (this.heightStore) this.heightStore.set(this.maxHeight)
  }

  remove (id) {
    let exists = !!this.txs[id]
    delete this.txs[id]
    return exists
  }

  drop (id) {
    return this.remove(id)
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

  place (tx) {
    const size = this.txSize(tx)
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

  applyHighlighting (criteria) {
    Object.values(this.txs).forEach(tx => {
      tx.applyHighlighting(criteria)
    })
    Object.values(this.hiddenTxs).forEach(tx => {
      tx.applyHighlighting(criteria)
    })
  }
}
