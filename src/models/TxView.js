import TxSprite from './TxSprite.js'
import { timeOffset } from '../utils/time.js'

// converts from this class's update format to TxSprite's update format
function toSpriteUpdate(display, duration, start) {
  return {
    now: start ? start - timeOffset : Date.now() - timeOffset,
    duration,
    ...display,
    ...(display.color ? { palette: display.color.palette, color: display.color.index, alpha: display.color.alpha } : { color: null })
  }
}

export default class TxView {
  constructor ({ id, time, value }) {
    this.id = id
    this.time = time
    this.value = value
    this.initialised = false
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
    next: another transition to animate after this one completes
          (you can nest several transitions like this)
          Performing another direct update cancels any pending transitions
  */
  update ({ display, duration, delay, state, next, start }) {
    if (next) {
      if (this.awaiting) clearTimeout(this.awaiting)
      this.awaiting = setTimeout(() => {
        this.update(next)
      }, (duration || 0) + (next.delay || 0))
    }

    this.state = state

    if (!this.initialised) {
      this.initialised = true
      const update = toSpriteUpdate(display, duration, start)
      update.id = this.id
      update.value = this.value
      this.sprite = new TxSprite(update)
    } else {
      const update = toSpriteUpdate(display, duration, start)
      this.sprite.update(update)
    }
  }

  getPosition () {
    if (this.initialised && this.sprite) return this.sprite.getPosition()
  }
}
