function interpolateAttributeStart(attribute, now, modular) {
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
    if (modular && Math.abs(attribute.a - attribute.b) > 0.5) {
      if (attribute.a > 0.5) {
        attribute.a -= 1
        attribute.a = attribute.a + ((progress / attribute.d) * (attribute.b - attribute.a))
      } else {
        attribute.a = attribute.a + ((progress / attribute.d) * (attribute.b - 1 - attribute.a))
      }
      if (attribute.a < 0) attribute.a += 1
    } else {
      attribute.a = attribute.a + ((progress / attribute.d) * (attribute.b - attribute.a))
    }
    attribute.d = attribute.d - progress
    attribute.v = 1 / attribute.d
  }
}

export default class TxSprite {

  constructor({ now = performance.now(), x, y, r, h, l, alpha }, vertexArray) {
    const offsetTime = now
    this.vertexArray = vertexArray
    this.vertexData = Array(VI.length).fill(0)
    this.updateMap = {
      x: 0, y: 0, r: 0, h: 0, l: 0, a: 0
    }

    this.attributes = {
      x: { a: x, b: x, t: offsetTime, v: 0, d: 0 },
      y: { a: y, b: y, t: offsetTime, v: 0, d: 0 },
      r: { a: r, b: r, t: offsetTime, v: 0, d: 0 },
      h: { a: h, b: h, t: offsetTime, v: 0, d: 0 },
      l: { a: l, b: l, t: offsetTime, v: 0, d: 0 },
      a: { a: alpha, b: alpha, t: offsetTime, v: 0, d: 0 },
    }

    // Used to temporarily modify the sprite, so that the base view can be resumed later
    this.modAttributes = null

    this.vertexPointer = this.vertexArray.insert(this)

    this.compile()
  }

  interpolateAttributes (updateMap, attributes, offsetTime, v, duration, minDuration, adjust) {
    for (const key of Object.keys(updateMap)) {
      // for each non-null attribute:
      if (updateMap[key] != null) {
        // calculate current interpolated value, and set as 'from'
        interpolateAttributeStart(attributes[key], offsetTime, key === 'h')
        // interpolateAttributeStart(attributes[key], offsetTime, key)
        // set 'start' to now
        attributes[key].t = offsetTime
        // if 'adjust' flag set
        // set 'duration' to Max(remaining time, 'duration')
        if (!adjust || (duration && attributes[key].d == 0)) {
          attributes[key].v = v
          attributes[key].d = duration
        } else if (minDuration > attributes[key].d) {
          attributes[key].v = 1 / minDuration
          attributes[key].d = minDuration
        }
        // set 'to' to target value
        attributes[key].b = updateMap[key]
      }
    }
  }

  update ({ now = performance.now(), x, y, r, h, l, alpha, duration, minDuration, adjust, modify }) {
    const offsetTime = now
    const v = duration > 0 ? (1 / duration) : 0

    this.updateMap.x = x
    this.updateMap.y = y
    this.updateMap.r = r
    this.updateMap.h = h
    this.updateMap.l = l
    this.updateMap.a = alpha

    const isModified = !!this.modAttributes
    if (!modify) {
      this.interpolateAttributes(this.updateMap, this.attributes, offsetTime, v, duration, minDuration, adjust)
    } else {
      if (!isModified) { // set up the modAttributes
        this.modAttributes = {}
        for (const key of Object.keys(this.updateMap)) {
          if (this.updateMap[key] != null) {
            this.modAttributes[key] = { ...this.attributes[key] }
          }
        }
      }
      this.interpolateAttributes(this.updateMap, this.modAttributes, offsetTime, v, duration, minDuration, adjust)
    }

    this.compile()
  }

  // Transition from modified state back to base attributes
  resume (duration, now = performance.now()) {
    // If not in modified state, there's nothing to do
    if (!this.modAttributes) return

    const offsetTime = now
    const v = duration > 0 ? (1 / duration) : 0

    for (const key of Object.keys(this.modAttributes)) {
      // If this base attribute is static (fixed or post-transition), transition smoothly back
      if (this.attributes[key].v == 0 || (this.attributes[key].t + this.attributes[key].d) <= now) {
        // calculate current interpolated value, and set as 'from'
        interpolateAttributeStart(this.modAttributes[key], offsetTime, key === 'h')
        this.attributes[key].a = this.modAttributes[key].a
        this.attributes[key].t = offsetTime
        this.attributes[key].v = v
        this.attributes[key].d = duration
      }
    }

    this.modAttributes = null

    this.compile()
  }

  compile () {
    let attributes = this.attributes
    if (this.modAttributes) {
      attributes = {
        ...this.attributes,
        ...this.modAttributes
      }
    }
    const size = attributes.r

    // update vertex data in place
    // ugly, but avoids allocating and spreading large temporary arrays
    const vertexStride = VI.length + 2
    for (let vertex = 0; vertex < 6; vertex++) {
      this.vertexData[vertex * vertexStride] = vertexOffsetFactors[vertex][0]
      this.vertexData[(vertex * vertexStride) + 1] = vertexOffsetFactors[vertex][1]
      for (let step = 0; step < VI.length; step++) {
        // components of each field in the vertex array are defined by an entry in VI:
        // VI[i].a is the attribute, VI[i].f is the inner field, VI[i].offA and VI[i].offB are offset factors
        this.vertexData[(vertex * vertexStride) + step + 2] = attributes[VI[step].a][VI[step].f]
      }
    }

    this.vertexArray.setData(this.vertexPointer, this.vertexData)
  }

  moveVertexPointer (index) {
    this.vertexPointer = index
  }

  destroy () {
    this.vertexArray.remove(this.vertexPointer)
    this.vertexPointer = null
  }
}

TxSprite.vertexSize = 26
TxSprite.vertexCount = 6
TxSprite.dataSize = TxSprite.vertexSize * TxSprite.vertexCount

const vertexOffsetFactors = [
  [-1,-1],
  [ 1, 1],
  [ 1,-1],
  [-1,-1],
  [ 1, 1],
  [-1, 1]
]

const VI = []
;(['x','y','r','h','l','a']).forEach((attribute, aIndex) => {
  ;(['a','b','t','v']).forEach(field => {
    VI.push({
      a: attribute,
      f: field
    })
  })
})
