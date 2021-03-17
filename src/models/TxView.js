import TxSprite from './TxSprite.js'
import { timeOffset } from '../utils/time.js'

// converts from this class's update format to TxSprite's update format
// now, id, value, layer, position, size, palette, color, alpha, duration, adjust
function toSpriteUpdate(display, duration, start, adjust) {
  return {
    now: start ? start - timeOffset : Date.now() - timeOffset,
    duration: duration,
    ...display,
    ...(display.color ? { palette: display.color.palette, color: display.color.index, alpha: display.color.alpha } : { color: null }),
    adjust
  }
}

export default class TxView {
  constructor ({ id, time, value, vertexArray }) {
    this.id = id
    this.time = time
    this.value = value
    this.initialised = false
    this.vertexArray = vertexArray
  }

  destroy () {
    if (this.sprite) this.sprite.destroy()
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
  update ({ display, duration, delay, state, start, adjust }) {
    this.state = state

    if (!this.initialised || !this.sprite) {
      this.initialised = true
      const update = toSpriteUpdate(display, duration, start)
      update.id = this.id
      update.value = this.value
      this.sprite = new TxSprite(update, this.vertexArray)
    } else {
      const update = toSpriteUpdate(display, duration, start, adjust)
      this.sprite.update(update)
    }
  }

  getPosition () {
    if (this.initialised && this.sprite) return this.sprite.getPosition()
  }
}
