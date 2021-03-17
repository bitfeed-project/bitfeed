function interpolateAttributeStart(attribute, now, label) {
  if (attribute.v == 0 || (attribute.t + attribute.d) <= now) {
    // transition finished, next transition starts from current end state
    // (clamp to 1)
    attribute.a = attribute.b
    attribute.v = 0
    attribute.d = 0
  } else if (attribute.t > now) {
    // transition not started
    // (clamp to 0)
  } else {
    // transition in progress
    // (interpolate)
    let progress =  (now - attribute.t)
    attribute.a = attribute.a + ((progress / attribute.d) * (attribute.b - attribute.a))
    attribute.d = attribute.d - progress
    attribute.v = 1 / attribute.d
  }
}

export default class TxSprite {
  constructor({ now = Date.now(), id, value, layer, position, size, palette, color, alpha }, vertexArray) {
    this.id = id
    this.value = value
    this.layer = layer
    this.vertexArray = vertexArray

    this.attributes = {
      x: { a: position.x, b: position.x, t: now, v: 0, d: 0 },
      y: { a: position.y, b: position.y, t: now, v: 0, d: 0 },
      r: { a: size, b: size, t: now, v: 0, d: 0 },
      p: { a: palette, b: palette, t: now, v: 0, d: 0 },
      c: { a: color, b: color, t: now, v: 0, d: 0 },
      a: { a: alpha, b: alpha, t: now, v: 0, d: 0 },
    }

    this.vertexPointer = this.vertexArray.insert(this)

    this.compile()
  }

  update({ now, layer, position, size, palette, color, alpha, duration, minDuration, adjust }) {
    const v = duration > 0 ? (1 / duration) : 0

    let update = {
      x: position ? position.x : null,
      y: position ? position.y: null,
      r: size,
      p: palette,
      c: color,
      a: alpha
    }

    for (const key of Object.keys(update)) {
      // for each non-null attribute:
      if (update[key] != null) {
        // calculate current interpolated value, and set as 'from'
        interpolateAttributeStart(this.attributes[key], now, key)
        // set 'start' to now
        this.attributes[key].t = now
        // if 'adjust' flag set
        // set 'duration' to Max(remaining time, 'duration')
        if (!adjust || (duration && this.attributes[key].d == 0)) {
          this.attributes[key].v = v
          this.attributes[key].d = duration
        } else if (minDuration > this.attributes[key].d) {
          this.attributes[key].v = 1 / minDuration
          this.attributes[key].d = minDuration
        }
        // set 'to' to target value
        this.attributes[key].b = update[key]
      }
    }

    this.compile()
  }

  compile () {
    this.vertexData = [
      this.attributes.x.a,
      this.attributes.x.b,
      this.attributes.x.t,
      this.attributes.x.v,

      this.attributes.y.a,
      this.attributes.y.b,
      this.attributes.y.t,
      this.attributes.y.v,

      this.attributes.r.a,
      this.attributes.r.b,
      this.attributes.r.t,
      this.attributes.r.v,

      this.attributes.p.a,
      this.attributes.p.b,
      this.attributes.p.t,
      this.attributes.p.v,

      this.attributes.c.a,
      this.attributes.c.b,
      this.attributes.c.t,
      this.attributes.c.v,

      this.attributes.a.a,
      this.attributes.a.b,
      this.attributes.a.t,
      this.attributes.a.v,
    ]
    this.vertexArray.setData(this.vertexPointer, this.vertexData)
  }

  moveVertexPointer (index) {
    this.vertexPointer = index
  }

  getPosition () {
    return {
      x: this.attributes.x.b,
      y: this.attributes.y.b
    }
  }

  getVertexData () {
    return this.vertexData
  }

  destroy () {
    this.vertexArray.remove(this.vertexPointer)
    this.vertexPointer = null
  }
}
