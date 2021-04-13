import TxView from './TxView.js'
import config from '../config.js'

export default class BitcoinTx {
  constructor ({ version, id, value, inputs, outputs, witnesses, time, block }, vertexArray) {
    this.version = version
    this.id = id
    this.vertexArray = vertexArray
    this.pixelPosition = { x: 0, y: 0, r: 0}
    this.screenPosition = { x: 0, y: 0, r: 0}
    this.gridPosition = { x: 0, y: 0, r: 0}

    if (inputs && outputs) {
      this.inputs = inputs
      this.outputs = outputs
      this.value = this.calcValue()
    } else if (value) {
      this.value = value
    }

    this.witnesses = witnesses
    this.time = time

    if (config.donationHash && this.outputs) {
      this.outputs.forEach(output => {
        if (output.script_pub_key.includes(config.donationHash)) {
          console.log('donation!', this)
          this.highlight = true
        }
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

  hoverOn () {
    if (this.view) this.view.setHover(true)
  }

  hoverOff () {
    if (this.view) this.view.setHover(false)
  }
}
