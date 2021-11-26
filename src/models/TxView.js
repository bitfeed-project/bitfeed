import TxSprite from './TxSprite.js'

// converts from this class's update format to TxSprite's update format
// now, id, value, layer, position, size, palette, color, alpha, duration, adjust
function toSpriteUpdate(display, duration, delay, start, adjust) {
  return {
    now: (start || performance.now()) + (delay || 0),
    duration: duration,
    ...display,
    ...(display.color != null ? { palette: display.color.palette, color: display.color.index, alpha: display.color.alpha } : { color: null }),
    adjust
  }
}

export default class TxView {
  constructor ({ id, time, value, vbytes, vertexArray }) {
    this.id = id
    this.time = time
    this.value = value
    this.vbytes = vbytes
    this.initialised = false
    this.vertexArray = vertexArray
  }

  destroy () {
    if (this.sprite) {
      this.sprite.destroy()
      this.sprite = null
    }
  }

  /*
    display: defines the final appearance of the sprite
        layer: z index
        position: { x, y }
        size: in pixels
        color:
            palette: id of texture to choose color from
            index: where in the texture to sample
    duration: of the tweening animation from the previous display state
    delay: for queued transitions, how long to wait after current transition
           completes to start.
  */
  update ({ display, duration, delay, jitter, state, start, adjust }) {
    this.state = state
    if (jitter) delay += (Math.random() * jitter)

    if (!this.initialised || !this.sprite) {
      this.initialised = true
      this.sprite = new TxSprite(
        toSpriteUpdate(display, duration, delay, start),
        this.vertexArray
      )
    } else {
      this.sprite.update(
        toSpriteUpdate(display, duration, delay, start, adjust)
      )
    }
  }

  setHover (hoverOn) {
    if (this.sprite) this.sprite.setHover(hoverOn)
  }

  getPosition () {
    if (this.initialised && this.sprite) return this.sprite.getPosition()
  }
}
