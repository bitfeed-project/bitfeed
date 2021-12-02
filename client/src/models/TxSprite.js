const hoverTransitionTime = 300

function interpolate (startState, endState, startTime, duration, now) {
  const progress = Math.max(0, Math.min(1, (now - startTime) / duration))
  return startState + ((endState - startState) * progress)
}

function interpolateAttributeStart(attribute, now, label, binaryAttribute) {
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
    let progress = (now - attribute.t)
    if (!binaryAttribute) {
      attribute.a = attribute.a + ((progress / attribute.d) * (attribute.b - attribute.a))
    }
    attribute.d = attribute.d - progress
    attribute.v = 1 / attribute.d
  }
}

export default class TxSprite {

  constructor({ now = performance.now(), layer, position, palette, color, alpha }, vertexArray) {
    const offsetTime = now
    this.layer = layer
    this.vertexArray = vertexArray
    this.vertexData = Array(VI.length).fill(0)
    this.updateMap = {
      x: 0, y: 0, r: 0, p: 0, c: 0, a: 0
    }

    this.attributes = {
      x: { a: position.x, b: position.x, t: offsetTime, v: 0, d: 0 },
      y: { a: position.y, b: position.y, t: offsetTime, v: 0, d: 0 },
      r: { a: position.r, b: position.r, t: offsetTime, v: 0, d: 0 },
      p: { a: palette, b: palette, t: offsetTime, v: 0, d: 0 },
      c: { a: color, b: color, t: offsetTime, v: 0, d: 0 },
      a: { a: alpha, b: alpha, t: offsetTime, v: 0, d: 0 },
    }

    this.vertexPointer = this.vertexArray.insert(this)

    this.hover = false
    this.hoverCache = null

    this.compile()
  }

  update ({ now = performance.now(), layer, position, palette, color, alpha, duration, minDuration, adjust }, internal) {
    // if (!internal && (palette || color || alpha)) this.clearHover()
    if (!internal && (palette != null || color != null || alpha != null)) this.clearHover()
    const offsetTime = now
    const v = duration > 0 ? (1 / duration) : 0

    this.updateMap.x = position ? position.x : null
    this.updateMap.y = position ? position.y : null
    this.updateMap.r = position ? position.r : null
    this.updateMap.p = palette
    this.updateMap.c = color
    this.updateMap.a = alpha

    if (this.updateMap.x || this.updateMap.y || this.updateMap.r) {
      if (this.updateMap.x == null) this.updateMap.x = this.attributes.x.b
      if (this.updateMap.y == null) this.updateMap.y = this.attributes.y.b
      if (this.updateMap.r == null) this.updateMap.r = this.attributes.r.b
    }

    for (const key of Object.keys(this.updateMap)) {
      // for each non-null attribute:
      if (this.updateMap[key] != null) {
        // calculate current interpolated value, and set as 'from' (except the non-interpolatable palette attribute)
        interpolateAttributeStart(this.attributes[key], offsetTime, key, key === 'p')
        // interpolateAttributeStart(this.attributes[key], offsetTime, key)
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
        this.attributes[key].b = this.updateMap[key]
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

    // update vertex data in place
    // ugly, but avoids allocating and spreading large temporary arrays
    for (let step = 0; step < VI.length; step++) {
      // components of each field in the vertex array are defined by an entry in VI:
      // VI[i].a is the attribute, VI[i].f is the inner field, VI[i].offA and VI[i].offB are offset factors
      this.vertexData[step] = this.attributes[VI[step].a][VI[step].f] + (VI[step].offA * size.a)  + (VI[step].offB * size.b)
    }

    // this.vertexData = [
    //   ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: -size.a, b: -size.b }}),
    //   ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: size.a, b: size.b }}),
    //   ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: -size.a, b: -size.b }}),
    //   ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: -size.a, b: -size.b }}),
    //   ...this.compileVertex({ x: { a: size.a, b: size.b }, y: { a: size.a, b: size.b }}),
    //   ...this.compileVertex({ x: { a: -size.a, b: -size.b }, y: { a: size.a, b: size.b }})
    // ]
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

  clearHover () {
    if (this.hoverCache) {
      this.attributes.p = { ...this.hoverCache.p }
      this.attributes.c = { ...this.hoverCache.c }
      this.attributes.a = { ...this.hoverCache.a }
    }
    this.hoverCache = null
  }

  // On hover, we transition to the hover color
  // If the sprite already has a color transition in progress, we cache it
  // in order to smoothly transition back
  setHover (hoverOn) {
    if (hoverOn !== this.hover) {
      if (hoverOn) {
        // cache current color transition
        this.hoverCache = {
          p: { ...this.attributes.p },
          c: { ...this.attributes.c },
          a: { ...this.attributes.a },
          at: performance.now()
        }
        this.update({
          palette: 3.5,
          color: 0.0,
          alpha: 1.0,
          duration: hoverTransitionTime,
          adjust: false
        }, true)
      } else if (this.hoverCache) {
        // switch back to previous color transition
        this.clearHover()
        this.compile()
      }
    }
    this.hover = this.hoverOn
  }

  destroy () {
    this.vertexArray.remove(this.vertexPointer)
    this.vertexPointer = null
  }
}

TxSprite.vertexSize = 20
TxSprite.vertexCount = 6
TxSprite.dataSize = TxSprite.vertexSize * TxSprite.vertexCount

const VI = []
;([
  [-1,-1],
  [ 1, 1],
  [ 1,-1],
  [-1,-1],
  [ 1, 1],
  [-1, 1]
]).forEach(offsets => {
  ;(['x','y','p','c','a']).forEach((attribute, aIndex) => {
    ;(['a','b','t','v']).forEach(field => {
      VI.push({
        a: attribute,
        f: field,
        offA: (attribute === 'x' || attribute === 'y') && (field === 'a') ? offsets[aIndex] : 0,
        offB: (attribute === 'x' || attribute === 'y') && (field === 'b') ? offsets[aIndex] : 0
      })
    })
  })
})
