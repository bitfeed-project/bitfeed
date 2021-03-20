import TxView from './TxView.js'
import config from '../config.js'

export default class BitcoinTx {
  constructor ({ version, id, value, inputs, outputs, witnesses, time, block }, vertexArray) {
    this.version = version
    this.id = id
    this.vertexArray = vertexArray

    if (inputs && outputs) {
      this.inputs = inputs
      this.outputs = outputs
      this.value = this.calcValue()
    } else if (value) {
      this.value = value
    }

    this.witnesses = witnesses
    this.time = time

    if (config.donationAddress && this.outputs) {
      this.outputs.forEach(output => {
        if (output.address === config.donationAddress) this.highlight = true
      })
    }

    this.setBlock(block)
    this.view = new TxView(this)
  }

  destroy () {
    if (this.view) this.view.destroy()
  }

  calcValue () {
    if (this.outputs && this.outputs.length) {
      return this.outputs.reduce((acc, output) => {
        return acc + output.value
      }, 0)
    } else return 0
  }

  setBlock (block) {
    this.block = block
    this.state = this.block ? 'block' : 'pool'
  }

  updateView (update) {
    if (this.view) this.view.update(update)
  }

  setGridPosition (position) {
    this.gridPosition = position
  }
  getGridPosition () {
    if (this.gridPosition) return this.gridPosition
  }
  setScreenPosition (position) {
    this.screenPosition = position
  }
  getScreenPosition () {
    if (this.screenPosition) return this.screenPosition
  }
}
