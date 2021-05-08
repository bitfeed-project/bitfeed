import TxView from './TxView.js'
import config from '../config.js'

export default class BitcoinTx {
  constructor ({ version, id, value, inputs, outputs, time, block }, vertexArray) {
    this.version = version
    this.id = id
    this.vertexArray = vertexArray
    this.pixelPosition = { x: 0, y: 0, r: 0}
    this.screenPosition = { x: 0, y: 0, r: 0}
    this.gridPosition = { x: 0, y: 0, r: 0}
    this.inputs = inputs
    this.outputs = outputs
    this.value = value

    if (inputs && outputs && value == null) {
      this.value = this.calcValue()
    }

    this.time = time

    if (config.donationHash && this.outputs) {
      this.outputs.forEach(output => {
        if (output.script_pub_key.includes(config.donationHash)) {
          console.log('donation!', this)
          this.highlight = true
        }
      })
    }

    // is a coinbase transaction?
    if (this.inputs && this.inputs.length === 1 && this.inputs[0].prev_txid === "0000000000000000000000000000000000000000000000000000000000000000") {
      const cbInfo = this.inputs[0].script_sig
      // number of bytes encoding the block height
      const height_bytes = parseInt(cbInfo.substring(0,2), 16)
      // extract the specified number of bytes, reverse the endianness (reverse pairs of hex characters), parse as a hex string
      const height = parseInt(cbInfo.substring(2,2 + (height_bytes * 2)).match(/../g).reverse().join(''),16)
      // save remaining bytes as free data
      const sig = cbInfo.substring(2 + (height_bytes * 2))
      const sigAscii = sig.match(/../g).reduce((parsed, hexChar) => {
        return parsed + String.fromCharCode(parseInt(hexChar, 16))
      }, "")
      this.coinbase = {
        height,
        sig,
        sigAscii
      }
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
