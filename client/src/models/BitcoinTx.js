import TxView from './TxView.js'
import config from '../config.js'
import { subsidyAt } from '../utils/bitcoin.js'
import { mixColor, pink, bluegreen, orange, teal, green, purple  } from '../utils/color.js'

export default class BitcoinTx {
  constructor (data, vertexArray, isCoinbase = false) {
    this.vertexArray = vertexArray
    this.setData(data, isCoinbase)
    if (vertexArray) this.view = new TxView(this)
  }

  setCoinbaseData (block) {
    if (this.is_preview) {
      const subsidy = subsidyAt(block.height)
      this.coinbase = {
        height: block.height,
        fees: this.value - subsidy,
        subsidy
      }
    } else {
      const cbInfo = this.inputs[0].script_sig
      // number of bytes encoding the block height
      const height_bytes = parseInt(cbInfo.substring(0,2), 16)
      // extract the specified number of bytes, reverse the endianness (reverse pairs of hex characters), parse as a hex string
      const parsed_height = parseInt(cbInfo.substring(2,2 + (height_bytes * 2)).match(/../g).reverse().join(''),16)
      // save remaining bytes as free data
      const sig = cbInfo.substring(2 + (height_bytes * 2))
      const sigAscii = sig.match(/../g).reduce((parsed, hexChar) => {
        return parsed + String.fromCharCode(parseInt(hexChar, 16))
      }, "")

      const height = block.height == null ? parsed_height : block.height

      const subsidy = subsidyAt(height)

      this.coinbase = {
        height,
        sig,
        sigAscii,
        fees: this.value - subsidy,
        subsidy
      }
    }
  }

  setVertexArray (vertexArray) {
    this.vertexArray = vertexArray
    this.view = new TxView(this)
  }

  setData ({ version, inflated, preview, id, value, fee, vbytes, numInputs, inputs, outputs, time, block }, isCoinbase=false) {
    this.version = version
    this.is_inflated = !!inflated
    this.is_preview = !!preview
    this.id = id
    this.pixelPosition = { x: 0, y: 0, r: 0}
    this.screenPosition = { x: 0, y: 0, r: 0}
    this.gridPosition = { x: 0, y: 0, r: 0}
    this.inputs = inputs
    if (numInputs != null) this.numInputs = numInputs
    this.outputs = outputs
    this.value = value
    this.fee = fee
    this.vbytes = vbytes

    if (this.fee != null) this.feerate = fee / vbytes

    if (inputs && outputs && value == null) {
      this.value = this.calcValue()
    }

    this.time = time
    this.highlight = false

    // is a coinbase transaction?
    this.isCoinbase = isCoinbase
    if (this.isCoinbase || this.fee == null || this.fee < 0) {
      this.fee = null
      this.feerate = null
    }

    if (!this.block) this.setBlock(block)

    const feeColor = ((this.isCoinbase || this.feerate == null)
      ? orange
      : mixColor(teal, purple, 1, Math.log2(128), Math.log2(this.feerate))
    )
    this.colors = {
      age: {
        block: { color: orange },
        pool: { color: orange, endColor: teal, duration: 60000 },
      },
      fee: {
        block: { color: feeColor },
        pool: { color: feeColor },
      }
    }
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
    if (this.block && (this.isCoinbase || (this.block.coinbase && this.id == this.block.coinbase.id))) {
      this.isCoinbase = true
      this.setCoinbaseData(this.block)
    }
  }

  onEnterScene () {
    this.enteredTime = performance.now()
  }

  getColor (scene, mode) {
    return this.colors[mode][scene]
  }

  hoverOn (color = bluegreen) {
    if (this.view) this.view.setHover(true, color)
  }

  hoverOff () {
    if (this.view) this.view.setHover(false)
  }

  highlightOn (color = pink) {
    if (this.view) this.view.setHighlight(true, color)
    this.highlight = true
  }

  highlightOff () {
    if (this.view) this.view.setHighlight(false)
    this.highlight = false
  }

  applyHighlighting (criteria) {
    let color
    this.highlight = false
    criteria.forEach(criterion => {
      if (criterion.txid === this.id) {
        this.highlight = true
        color = criterion.color
      } else if (criterion.address && criterion.scriptPubKey) {
        this.outputs.forEach(output => {
          if (output.script_pub_key === criterion.scriptPubKey) {
            this.highlight = true
            color = criterion.color
          }
        })
      }
    })
    this.view.setHighlight(this.highlight, color || pink)
  }

  static fromRPCData(txData, isCoinbase) {
    return {
      version: txData.version,
      inflated: false,
      preview: true,
      id: txData.txid,
      value: null, // calculated in constructor
      fee: txData.fee * 100000000,
      vbytes: txData.vsize,
      inputs: txData.vin.map(vin => { return { script_sig: vin.coinbase || vin.scriptSig.hex, prev_txid: vin.txid, prev_vout: vin.vout }}),
      outputs: txData.vout.map(vout => { return { value: vout.value * 100000000, script_pub_key: vout.scriptPubKey.hex }}),
    }
  }

  // unpack compact array format tx data
  static decompress (data, blockData) {
    return {
      version: data[0],
      inflated: false,
      preview: true,
      id: data[1],
      fee: data[2],
      value: data[3],
      vbytes: data[4],
      numInputs: data[5],
      outputs: data[6].map(vout => { return { value: vout[0], script_pub_key: vout[1] }}),
    }
  }
}
