import TxSprite from './TxSprite.js'

const hoverTransitionTime = 300

// converts from this class's update format to TxSprite's update format
// now, id, value, position, size, color, alpha, duration, adjust
function toSpriteUpdate(display, duration, delay, start, adjust) {
  return {
    now: (start || performance.now()) + (delay || 0),
    duration: duration,
    ...(display.position ? display.position: {}),
    ...(display.color ? display.color: {}),
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
        position: { x, y }
        size: in pixels
        color: (in HCL space)
            h: hue
            l: lightness
            alpha: alpha transparency
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
    if (hoverOn) {
      if (this.sprite) {
        this.sprite.update({
          h: 1.0,
          l: 0.4,
          duration: hoverTransitionTime,
          modify: true
        })
      }
    } else {
      if (this.sprite) {
        this.sprite.resume(hoverTransitionTime)
      }
    }
  }

  getPosition () {
    if (this.initialised && this.sprite) return this.sprite.getPosition()
  }
}
