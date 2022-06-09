import TxSprite from './TxSprite.js'

const highlightTransitionTime = 300

// converts from this class's update format to TxSprite's update format
// now, id, value, position, size, color, alpha, duration, adjust
function toSpriteUpdate(display, duration, minDuration, delay, start, adjust, smooth, boomerang) {
  return {
    now: (start || performance.now()),
    delay: delay,
    duration: duration,
    minDuration: minDuration,
    ...(display.position ? display.position: {}),
    ...(display.color ? display.color: {}),
    adjust,
    smooth,
    boomerang
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

    this.hover = false
    this.highlight = false
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
        color:
            i: x coord in color texture
            j: y coord in color texture
            alpha: alpha transparency
    duration: of the tweening animation from the previous display state
    delay: for queued transitions, how long to wait after current transition
           completes to start.
  */
  update ({ display, duration, minDuration, delay = 0, jitter, state, start, adjust, smooth, boomerang }) {
    this.state = state
    if (jitter) delay += (Math.random() * jitter)

    if (!this.initialised || !this.sprite) {
      this.initialised = true
      this.sprite = new TxSprite(
        toSpriteUpdate(display, duration, minDuration, delay, start, adjust, smooth, boomerang),
        this.vertexArray
      )
      // apply any pending modifications
      if (this.hover) {
        this.sprite.update({
          ...this.highlightColor,
          duration: highlightTransitionTime,
          adjust: false,
          modify: true
        })
      } else if (this.highlight) {
        this.sprite.update({
          ...this.highlightColor,
          duration: highlightTransitionTime,
          adjust: false,
          modify: true
        })
      }
    } else {
      this.sprite.update(
        toSpriteUpdate(display, duration, minDuration, delay, start, adjust, smooth, boomerang)
      )
    }
  }

  setHover (hoverOn, color) {
    if (hoverOn) {
      this.hover = true
      this.hoverColor = color
      this.sprite.update({
        ...this.hoverColor,
        duration: highlightTransitionTime,
        adjust: false,
        modify: true,
      })
    } else {
      this.hover = false
      this.hoverColor = null
      if (this.highlight) {
        if (this.sprite) {
          this.sprite.update({
            ...this.highlightColor,
            duration: highlightTransitionTime,
            adjust: false,
            modify: true
          })
        }
      } else {
        if (this.sprite) this.sprite.resume(highlightTransitionTime)
      }
    }
  }

  setHighlight (highlightOn, color) {
    if (highlightOn) {
      this.highlight = true
      this.highlightColor = color
      if (!this.hover) {
        if (this.sprite) {
          this.sprite.update({
            ...this.highlightColor,
            duration: highlightTransitionTime,
            adjust: false,
            modify: true
          })
        }
      }
    } else {
      this.highlight = false
      this.highlightColor = null
      if (!this.hover) {
        if (this.sprite) this.sprite.resume(highlightTransitionTime)
      }
    }
  }

  getPosition () {
    if (this.initialised && this.sprite) return this.sprite.getPosition()
  }
}
