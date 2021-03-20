/*
  Utility class for access and management of low-level sprite data

  Maintains a single Float32Array of sprite data, keeping track of empty slots
  to allow constant-time insertion and deletion

  Automatically resizes by copying to a new, larger Float32Array when necessary,
  or compacting into a smaller Float32Array when there's space to do so.
*/
export class FastVertexArray {
  constructor (length, stride, counter) {
    // console.log(`Creating Fast Vertex Array with length ${length} and stride ${stride} `)
    this.length = length
    this.counter = counter
    this.count = 0
    this.stride = stride
    this.sprites = []
    this.data = new Float32Array(this.length * this.stride)
    this.freeSlots = []
    this.lastSlot = 0
    this.nullSprite = new Float32Array(this.stride)
    // this.print()
  }

  print () {
    // console.log(`Length: ${this.length}, Free slots: ${this.freeSlots.length}, last slot: ${this.lastSlot}`)
    // console.log(this.freeSlots)
    // console.log(this.data)
  }

  insert (sprite) {
    // console.log('inserting into FVA')
    this.count++
    if (this.counter) this.counter.increment()

    let position
    if (this.freeSlots.length) {
      position = this.freeSlots.shift()
    } else {
      position = this.lastSlot
      this.lastSlot++
      if (this.lastSlot > this.length) {
        this.expand()
      }
    }
    // this.print()
    this.sprites[position] = sprite
    return position
  }

  remove (index) {
    this.count--
    if (this.counter) this.counter.decrement()
    this.setData(index, this.nullSprite)
    this.freeSlots.push(index)
    this.sprites[index] = null
    if (this.length > 2048 && this.count < (this.length * 0.4)) this.compact()
    // this.print()
  }

  setData (index, dataChunk) {
    // console.log(`Updating chunk at ${index} (${index * this.stride})`)
    this.data.set(dataChunk, (index * this.stride))
    // this.print()
  }

  getData (index) {
    return this.data.subarray(index, this.stride)
  }

  expand () {
    // console.log('Expanding FVA')
    this.length *= 2
    const newData = new Float32Array(this.length * this.stride)
    newData.set(this.data)
    this.data = newData
    this.print()
  }

  compact () {
    // console.log('Compacting FVA')
    // console.log(this.sprites)
    // New array length is the smallest power of 2 larger than the sprite count
    const newLength = Math.pow(2, Math.ceil(Math.log2(this.count)))
    if (this.newLength != this.length) {
      // console.log(`compacting from ${this.length} to ${newLength}`)
      this.length = newLength
      this.data = new Float32Array(this.length * this.stride)
      let sprite
      const newSprites = []
      let i = 0
      for (var index in this.sprites) {
        sprite = this.sprites[index]
        if (sprite) {
          newSprites.push(sprite)
          sprite.moveVertexPointer(i)
          sprite.compile()
          i++
        }
      }
      this.sprites = newSprites
      this.freeSlots = []
      this.lastSlot = i
    }
    this.print()
  }

  getVertexData () {
    return this.data
  }
}
