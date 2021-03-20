import { timeOffset } from '../utils/time.js'

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

  constructor({ now = Date.now(), id, value, layer, position, palette, color, alpha }, vertexArray) {
    const offsetTime = now - timeOffset
    this.id = id
    this.value = value
    this.layer = layer
    this.vertexArray = vertexArray

    this.attributes = {
      x: { a: position.x, b: position.x, t: offsetTime, v: 0, d: 0 },
      y: { a: position.y, b: position.y, t: offsetTime, v: 0, d: 0 },
      r: { a: position.r, b: position.r, t: offsetTime, v: 0, d: 0 },
      p: { a: palette, b: palette, t: offsetTime, v: 0, d: 0 },
      c: { a: color, b: color, t: offsetTime, v: 0, d: 0 },
      a: { a: alpha, b: alpha, t: offsetTime, v: 0, d: 0 },
    }

    this.vertexPointer = this.vertexArray.insert(this)

    this.compile()
  }

  update({ now = Date.now(), layer, position, palette, color, alpha, duration, minDuration, adjust }) {
    const offsetTime = now - timeOffset
    const v = duration > 0 ? (1 / duration) : 0

    let update = {
      x: position ? position.x : null,
      y: position ? position.y : null,
      r: position ? position.r : null,
      p: palette,
      c: color,
      a: alpha
    }

    if (update.x || update.y || update.r) {
      if (update.x == null) update.x = this.attributes.x.b
      if (update.y == null) update.y = this.attributes.y.b
      if (update.r == null) update.r = this.attributes.r.b
    }

    for (const key of Object.keys(update)) {
      // for each non-null attribute:
      if (update[key] != null) {
        // calculate current interpolated value, and set as 'from'
        interpolateAttributeStart(this.attributes[key], offsetTime, key)
        // set 'start' to now
        this.attributes[key].t = offsetTime
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

  // vertex offset = { x: { a, b }, y: { a, b} }
  compileVertex (offset) {
    return [
      this.attributes.x.a + offset.x.a,
      this.attributes.x.b + offset.x.b,
      this.attributes.x.t,
      this.attributes.x.v,

      this.attributes.y.a + offset.y.a,
      this.attributes.y.b + offset.y.b,
      this.attributes.y.t,
      this.attributes.y.v,

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
  }

  compile () {
    const size = this.attributes.r
    this.vertexData = [
      // duplicate vertex creates degenerate triangles & terminates the shape
      ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: size.a, b: size.b }}),
      ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: size.a, b: size.b }}),
      ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: size.a, b: size.b }}),
      ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: -size.a, b: -size.b }}),
      ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: -size.a, b: -size.b }}),
      ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: -size.a, b: -size.b }})
    ]
    this.vertexArray.setData(this.vertexPointer, this.vertexData)
  }

  moveVertexPointer (index) {
    this.vertexPointer = index
  }

  // getPosition () {
  //   return {
  //     x: this.attributes.x.b,
  //     y: this.attributes.y.b
  //   }
  // }
  //
  // getVertexData () {
  //   return this.vertexData
  // }

  destroy () {
    this.vertexArray.remove(this.vertexPointer)
    this.vertexPointer = null
  }
}

TxSprite.dataSize = 120
