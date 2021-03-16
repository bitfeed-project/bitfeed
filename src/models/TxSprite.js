function interpolateAnimationState (from, to, progress) {
  const clampedProgress = Math.max(0,Math.min(1,progress))
  return Object.keys(from).reduce((result, key) => {
    if (to[key] != null) {
      result[key] = from[key] + ((to[key] - from[key]) * clampedProgress)
    }
    return result
  }, from)
}

export default class TxSprite {
  constructor({ now, id, value, layer, position, size, palette, color, alpha }) {
    this.id = id
    this.value = value
    this.layer = layer

    this.duration = 0
    this.v = 0
    this.start = now

    this.from = {
      x: position.x,
      y: position.y,
      r: size,
      p: palette,
      c: color,
      a: alpha
    }
    this.to = {
      ...this.from
    }

    this.compile()
  }

  update({ now, duration, layer, position, size, palette, color, alpha }) {
    // Save a copy of the current target display
    const currentTarget = this.to

    // Check if we're mid-transition
    const progress = (this.duration && this.start) ? ((now - this.start) / this.duration) : 0
    if (progress >= 1 || progress <= 0) {
      // Transition finished or hasn't started:
      // so next transition starts from the current display state
      this.from = {
        ...currentTarget
      }
    } else {
      // Mid-transition:
      // we want to start the next transition from our current intermediate state
      // so find that by interpolating between the last transitions start and end states
      this.from = interpolateAnimationState(this.from, currentTarget, progress)
    }

    // Build new target display, inheriting from the current target where necessary
    this.to = {
      x: (position && position.x != null) ? position.x : this.from.x,
      y: (position && position.y != null) ? position.y : this.from.y,
      r: (size != null) ? size : this.from.r,
      p: (palette != null) ? palette : this.from.p,
      c: (color != null) ? color : this.from.c,
      a: (alpha != null) ? alpha : this.from.a
    }

    if (layer != null) this.layer = layer
    if (duration != null) {
      this.duration = duration
      this.v = duration ? (1 / duration) : 0
    }
    this.start = now

    this.compile()
  }

  compile () {
    this.vertexData = [
      this.start,
      this.layer,
      this.v,
      this.from.x,
      this.from.y,
      this.to.x,
      this.to.y,
      this.from.r,
      this.to.r,
      this.from.p,
      this.to.p,
      this.from.c,
      this.to.c,
      this.from.a,
      this.to.a,
    ]
  }

  getPosition () {
    return {
      x: this.to.x,
      y: this.to.y
    }
  }

  getVertexData () {
    return this.vertexData
  }
}
