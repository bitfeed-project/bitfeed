/*
  Interface definition for TxPackingScene type classes
*/

export default class TxPackingScene {
  constructor ({ width, height }) {
    this.init({ width, height })
  }

  init ({ width, height }) {
    this.width = width
    this.height = height
    this.txs = {}
    this.hiddenTxs = {}
    this.scene = {
      width: width,
      height: height,
      count: 0
    }
  }

  // insert a transaction into the scene
  // bool 'autoLayout' controls whether to calc & update the tx position immediately
  insert (tx, autoLayout?) {}

  // remove the transaction with the given id, return false if not present
  remove (id) {
    return !!success
  }

  // return a list of present transaction ids
  getTxList () {
    return [
      ...this.getActiveTxList(),
      ...this.getHiddenTxList()
      ...Object.keys(this.hiddenTxs)
    ]
  }
  getActiveTxList () {
    return Object.keys(this.txs)
  }
  getHiddenTxList () {
    return Object.keys(this.hiddenTxs)
  }

  // Return a flattened array of all vertex data of active tx sprites
  getVertexData () {
    return Object.values(this.txs).slice(-1000).flatMap(tx => tx.view.sprite.getVertexData())
  }
}
