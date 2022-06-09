import TxPoolScene from './TxPoolScene.js'
import TxSprite from './TxSprite.js'
import { settings } from '../stores.js'
import { logTxSize, byteTxSize } from '../utils/misc.js'
import config from '../config.js'

let settingsValue
settings.subscribe(v => {
  settingsValue = v
})

export default class TxMondrianPoolScene extends TxPoolScene {
  constructor ({ width, height, unit, padding, controller, heightStore, colorMode }) {
    super({ width, height, unit, padding, controller, heightStore, colorMode })
  }

  resize ({ width, height, unit, padding }) {
    super.resize({ width, height, unit, padding })
    this.resetLayout()
  }

  resetLayout () {
    if (this.layout) this.layout.destroy()
    this.layout = new MondrianLayout({ width: this.blockWidth, height: this.blockHeight, context: this })
  }

  // calculates and returns the size of the tx in multiples of the grid size
  txSize (tx={ value: 1, vbytes: 1 }) {
    if (settingsValue.vbytes) return byteTxSize(tx.vbytes, this.blockWidth)
    else return logTxSize(tx.value, this.blockWidth)
  }

  place (tx) {
    const size = this.txSize(tx)
    const position = this.layout.place(tx, size)
    tx.gridPosition.x = position.x
    tx.gridPosition.y = position.y
    tx.gridPosition.r = position.r
  }

  doScroll (offset) {
    super.doScroll(offset)
    this.layout.redraw()
    this.layout.clearOffscreen()
  }

  // handle mouse-over events - return the tx at this mouse position, if any
  selectAt (position) {
    if (this.layout) {
      const gridPosition = this.screenToGrid(position)
      return this.layout.getTxInGridCell(gridPosition)
    } else return null
  }

  drop (id) {
    let tx = this.txs[id]
    if (tx && tx.gridSquare) {
      this.layout.remove(tx.gridSquare)
    }
    delete this.txs[id]
    return !!tx
  }
}

class MondrianLayout {
  constructor ({ width, height, context }) {
    this.width = width
    this.height = height
    this.context = context

    this.rowOffset = 0
    this.rows = []
    this.txMap = [] // map of which txs occupy each grid square
  }

  getRow (position) {
    return this.rows[position.y - this.rowOffset]
  }

  getSlot (position) {
    if (this.getRow(position)) {
      return this.getRow(position).map[position.x]
    }
  }

  addRow () {
    // Add a new layout row to the top of the layout
    // 'slots' is an ordered list of slots in this row
    // 'map' is dictionary mapping x coordinates to slots
    // 'max' is the height of the largest slot in this row
    const newRow = { y: this.rows.length + this.rowOffset, slots: [], map: {}, max: 0 }
    this.rows.push(newRow)
    return newRow
  }

  clearOffscreen () {
    let done = false
    const cutoff = -(this.context.scene.scroll + this.context.scene.offset.y) / this.context.gridSize
    // console.log(`clearing layout rows. cut off at grid ${cutoff}`)
    while (!done && this.rows.length) {
      const head = this.rows[0]
      let max = 0
      head.slots.forEach(x => {
        max = Math.max(max, x.r)
      })
      if (head.y + max < cutoff) {
        // console.log('row below cutoff - removing')
        this.rowOffset++
        this.destroyRow(head)
        this.rows.shift()
        this.txMap.shift()
        // console.log(head)
      } else {
        done = true
      }
    }
  }

  addSlot (slot) {
    // console.log(`adding a slot to layout row ${slot.y} at x = ${slot.x}`)
    // slots must have non-zero size
    if (slot.r <= 0) return

    // allow one slot per coordinate
    if (this.getSlot(slot)) {
      // the slot is already occupied
      // console.log('slot already exists at this location')
      const existingSlot = this.getSlot(slot)
      // swap for the new slot if it is larger
      if (slot.r > existingSlot.r) {
        existingSlot.r = slot.r
        this.updateSlotSprite(existingSlot)
      }
      return existingSlot
    } else {
      // Insert this slot into the ordered 'slots' list
      let insertAt = null
      const row = this.getRow(slot)
      if (!row) {
        // console.log('no such row!')
        // console.log(slot)
        return
      }
      for (let i = 0; i < row.slots.length && insertAt == null; i++) {
        // console.log(`insert at ${i}? (x = ${this.rows[slot.y].slots[i].x})`)
        if (row.slots[i].x > slot.x) {
          // console.log('yes')
          insertAt = i
        } else {
          // console.log('no')
        }
      }
      // console.log(`insert slot at position ${insertAt}`)
      if (insertAt == null) row.slots.push(slot)
      else row.slots.splice(insertAt || 0, 0, slot)
      row.map[slot.x] = slot

      // Set up a sprite for debugging graphics
      if (config.layoutHints) {
        slot.sprite = new TxSprite(this.slotToSprite(slot), this.context.controller.debugVertexArray)
      }

      return slot
    }
  }

  removeSlot (slot) {
    const row = this.getRow(slot)
    if (row) {
      delete row.map[slot.x]
      let indexOf = row.slots.indexOf(slot)
      row.slots.splice(indexOf, 1)
    }
    if (slot.sprite) slot.sprite.destroy()
  }

  // Update the layout to accommodate a square of size squareWidth placed in the given slot
  fillSlot (slot, squareWidth) {
    const square = {
      left: slot.x,
      right: slot.x + squareWidth,
      bottom: slot.y,
      top: slot.y + squareWidth
    }

    this.removeSlot(slot)

    // console.log(`filling slot at ${slot.x},${slot.y},${slot.r} with ${squareWidth}`)

    // Find and fix collisions for each affected row (from slot.y + 1 to slot.y + squareWidth - 1)
    for (let rowIndex = slot.y; rowIndex < square.top; rowIndex++) {
      // console.log(`Checking row ${rowIndex}`)
      const row = this.getRow({ y: rowIndex })
      if (row) {
        // look for an overlapping slot
        let collisions = []
        let maxExcess = 0
        for (let i = 0; i < row.slots.length; i++) {
          const testSlot = row.slots[i]
          // console.log(`Checking slot ${i} (x: ${testSlot.x}) in row ${rowIndex}`)
          // collision if this slot overlaps the new square
          if (!((testSlot.x + testSlot.r < square.left) || (testSlot.x >= square.right))) {
            // console.log('Collision!')
            collisions.push(testSlot)
            // record how far this slot extends beyond the RHS of the filled slot (if at all)
            let excess = Math.max(0, (testSlot.x + testSlot.r) - (slot.x + slot.r))
            // console.log(`overruns by ${excess}`)
            maxExcess = Math.max(maxExcess, excess)
          }
        }
        // add a new slot on the RHS of the inserted square, unless one already exists or there's no space left there
        if (square.right < this.width && !row.map[square.right]) {
          // console.log(`Adding RHS square at ${square.right},${rowIndex},${(slot.r - squareWidth + maxExcess)}`)
          this.addSlot({ x: square.right, y: rowIndex, r: (slot.r - squareWidth + maxExcess) })
        }

        // process collisions (remove or adjust)
        // console.log('processing collisions: ', collisions)
        for (let i = 0; i < collisions.length; i++) {
          // shrink the slot to the now available space, or remove if no space left
          collisions[i].r = slot.x - collisions[i].x
          if (collisions[i].r > 0) this.updateSlotSprite(collisions[i])
          else this.removeSlot(collisions[i])
        }
      } else {
        // collision with implied slot in next uninitialised row
        this.addRow()
        if (slot.x > 0) this.addSlot({ x: 0, y: rowIndex, r: slot.x })
        if (square.right < this.width) this.addSlot({ x: square.right, y: rowIndex, r: this.width - square.right})
      }
    }

    // Find and fix collisions in region below the inserted square
    for (let rowIndex = Math.max(0, slot.y - squareWidth); rowIndex < slot.y; rowIndex++) {
      // console.log(`Checking row ${rowIndex}`)
      const row = this.getRow({ y: rowIndex })
      if (row) {
        // look for all overlapping slots
        for (let i = 0; i < row.slots.length; i++) {
          const testSlot = row.slots[i]
          // console.log(`Checking slot ${i} (x: ${slot[i].x}) in row ${rowIndex}`)
          // collision if this slot overlaps the filled slot
          if ((testSlot.x < slot.x + squareWidth) && (testSlot.x + testSlot.r > slot.x) && (testSlot.y + testSlot.r >= slot.y)) {
            // console.log('Collision!')

            // shrink the slot to the now available space
            const oldSlotWidth = testSlot.r
            testSlot.r = slot.y - testSlot.y
            if (testSlot.r > 0) this.updateSlotSprite(testSlot)
            else this.removeSlot(testSlot)
            // now there's some uncovered space on the RHS of the old slot
            let remaining = {
              x: testSlot.x + testSlot.r,
              y: testSlot.y,
              w: oldSlotWidth - testSlot.r,
              h: testSlot.r
            }
            // console.log('remaining space: ', remaining)
            // tile with free-floating slots to make sure we don't lose that space
            while (remaining.w > 0 && remaining.h > 0) {
              // console.log('tiling free space')
              if (remaining.w <= remaining.h) {
                this.addSlot({ x: remaining.x, y: remaining.y, r: remaining.w })
                remaining.y += remaining.w
                remaining.h -= remaining.w
              } else {
                this.addSlot({ x: remaining.x, y: remaining.y, r: remaining.h })
                remaining.x += remaining.h
                remaining.w -= remaining.h
              }
            }
          }
        }
      }
    }

    return { x: slot.x, y: slot.y, r: squareWidth }
  }

  place (tx, size) {
    let found = false
    let rowIndex = 0
    let row
    let slotIndex = 0
    let square = null
    while (!found && rowIndex < this.rows.length) {
      row = this.rows[rowIndex]
      while (!found && slotIndex < row.slots.length) {
        const testSlot = row.slots[slotIndex]
        // check if square fits in space
        if (testSlot.r >= size) {
          found = true
          square = this.fillSlot(testSlot, size)
        }
        slotIndex++
      }
      slotIndex = 0
      rowIndex++
    }
    if (!found) {
      const row = this.addRow()
      const slot = this.addSlot({ x: 0, y: row.y, r: this.width })
      square = this.fillSlot(slot, size)
    }

    // update txMap

    tx.gridSquare = square

    for (let x = 0; x < square.r; x++) {
      for (let y = 0; y < square.r; y++) {
        this.setTxMapCell({ x: square.x + x, y: square.y + y }, tx)
      }
    }

    return square
  }

  remove (square) {
    for (let x = 0; x < square.r; x++) {
      for (let y = 0; y < square.r; y++) {
        this.clearTxMapCell({ x: square.x + x, y: square.y + y })
        if (x <= y) this.addSlot({ x: square.x + x, y: square.y + y, r: square.r - y })
      }
    }
    // this.addSlot({ x: square.x, y: square.y, r: square.r })
  }

  setTxMapCell (coord, tx) {
    const offsetY = coord.y - this.rowOffset
    while (this.txMap.length <= offsetY) {
      this.txMap.push(new Array(this.width).fill(null))
    }
    this.txMap[offsetY][coord.x] = tx
  }

  clearTxMapCell (coord, tx) {
    const offsetY = coord.y - this.rowOffset
    while (this.txMap.length <= offsetY) {
      this.txMap.push(new Array(this.width).fill(null))
    }
    if (this.txMap[offsetY]) this.txMap[offsetY][coord.x] = null
  }

  getTxInGridCell(coord) {
    const offsetY = coord.y - this.rowOffset
    if (this.txMap[offsetY]) return this.txMap[offsetY][coord.x]
    else return null
  }

  slotToSprite (slot) {
    const pos = this.context.pixelsToScreen(this.context.gridToPixels(slot))
    return {
      x: pos.x,
      y: pos.y,
      r: pos.r,
      h: 0.5,
      l: 0.5,
      alpha: 0.5
    }
  }

  updateSlotSprite (slot) {
    if (config.layoutHints) {
      slot.sprite.update({
        ...this.slotToSprite(slot),
        duration: 500,
        minDuration: 500,
        adjust: true
      })
    }
  }

  redraw () {
    if (config.layoutHints) {
      this.rows.forEach(row => {
        row.slots.forEach(slot => {
          this.updateSlotSprite(slot)
        })
      })
    }
  }

  destroyRow (row) {
    if (config.layoutHints) {
      row.slots.forEach(slot => {
        slot.sprite.destroy()
      })
    }
  }

  destroy () {
    if (config.layoutHints) {
      this.rows.forEach(row => {
        row.slots.forEach(slot => {
          slot.sprite.destroy()
        })
      })
    }
  }
}
