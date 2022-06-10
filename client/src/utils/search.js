import api from './api.js'
import BitcoinTx from '../models/BitcoinTx.js'
import BitcoinBlock from '../models/BitcoinBlock.js'
import { detailTx, selectedTx, currentBlock, explorerBlock, overlay, highlightInOut, urlPath } from '../stores.js'
import { addressToSPK } from './encodings.js'

// Quick heuristic matching to guess what kind of search a query is for
// ***does not validate that a given address/txid/block is valid***
function matchQuery (query) {
  if (!query || !query.length) return

  const q = query.toLowerCase()

  // Looks like a block height?
  const asInt = parseInt(q)
  // Remember to update the bounds in
  if (!isNaN(asInt) && asInt >= 0 && `${asInt}` === q) {
    return {
      query: 'blockheight',
      label: 'block height',
      height: asInt,
      value: asInt
    }
  }

  // Looks like a block hash?
  if (/^0{8}[a-f0-9]{56}$/.test(q)) {
    return {
      query: 'blockhash',
      label: 'block hash',
      hash: query,
      value: query,
    }
  }

  // Looks like a transaction input?
  if (/^[0-9]+:[a-f0-9]{64}$/.test(q)) {
    const parts = q.split(':')
    return {
      query: 'input',
      label: 'transaction input',
      txid: parts[1],
      output: parts[0],
      value: q
    }
  }

  // Looks like a transaction output?
  if (/^[a-f0-9]{64}:[0-9]+$/.test(q)) {
    const parts = q.split(':')
    return {
      query: 'output',
      label: 'transaction output',
      txid: parts[0],
      output: parts[1],
      value: q
    }
  }

  // Looks like a transaction id?
  if (/^[a-f0-9]{64}$/.test(q)) {
    return {
      query: 'txid',
      label: 'transaction',
      txid: q,
      value: q
    }
  }

  // Looks like an address
  if ((q.length >= 26 && q.length <= 34) || q.length === 42 || q.length === 62) {
    // Looks like a legacy address
    if (/^[13]\w{24,33}$/.test(q)) {
      let addressType
      if (q[0] === '1') addressType = 'p2pkh'
      else if (q[0] === '3') addressType = 'p2sh'
      else return null

      return {
        query: 'address',
        label: 'address',
        encoding: 'base58',
        addressType,
        address: query,
        value: query,
        scriptPubKey: addressToSPK(query)
      }
    }

    // Looks like a bech32 address
    if (/^bc1\w{39}(\w{20})?$/.test(q)) {
      let addressType
      if (q.startsWith('bc1q')) {
        if (q.length === 42) addressType = 'p2wpkh'
        else if (q.length === 62) addressType = 'p2wsh'
        else return null
      } else if (q.startsWith('bc1p') && q.length === 62) {
        addressType = 'p2tr'
      } else return null

      return {
        query: 'address',
        label: 'address',
        encoding: 'bech32',
        addressType,
        address: query,
        value: query,
        scriptPubKey: addressToSPK(query)
      }
    }
  }

  return null
}
export {matchQuery as matchQuery}

let currentBlockVal
currentBlock.subscribe(block => {
  currentBlockVal = block
})

async function fetchTx (txid) {
  if (!txid) return
  const response = await fetch(`${api.uri}/api/tx/${txid}`, {
    method: 'GET'
  })
  if (!response) throw new Error('null response')
  if (response.status == 200) {
    const result = await response.json()
    const txData = result.tx
    if (result.blockheight != null && result.blockhash != null) {
      txData.block = { height: result.blockheight, hash: result.blockhash, time: result.time * 1000 }
    }
    return new BitcoinTx(txData, null, (txData.inputs && txData.inputs[0] && txData.inputs[0].prev_txid === "0000000000000000000000000000000000000000000000000000000000000000"))
  } else {
    throw new Error(response.status)
  }
}

async function fetchBlockByHash (hash) {
  if (!hash || (currentBlockVal && hash === currentBlockVal.id)) return true
  // try to fetch static block
  console.log('downloading block', hash)
  let response = await fetch(`${api.uri}/api/block/${hash}`, {
    method: 'GET'
  })
  if (!response) {
    console.log('failed to download block', hash)
    throw new Error('null response')
  }
  if (response && response.status == 200) {
    const blockData = await response.json()
    let block
    if (blockData) {
      if (blockData.id) {
        block = new BitcoinBlock(blockData)
      } else block = new BitcoinBlock(BitcoinBlock.decompress(blockData))
    }
    if (block && block.id) {
      console.log('downloaded block', block.id)
    } else {
      console.log('failed to download block', block.id)
    }
    return block
  }
}
export {fetchBlockByHash as fetchBlockByHash}

async function fetchBlockByHeight (height) {
  if (height == null) return
  const response = await fetch(`${api.uri}/api/block/height/${height}`, {
    method: 'GET'
  })
  if (!response) throw new Error('null response')
  if (response.status == 200) {
    const hash = await response.json()
    return fetchBlockByHash(hash)
  } else {
    throw new Error(response.status)
  }
}

async function fetchSpends (txid) {
  if (txid == null) return
  const response = await fetch(`${api.uri}/api/spends/${txid}`, {
    method: 'GET'
  })
  if (!response) throw new Error('null response')
  if (response.status == 200) {
    const result = await response.json()
    return result.map(output => {
      if (output) {
        if (output === true) {
          return true
        } else {
          return {
            txid: output[0],
            vin: output[1],
          }
        }
      } else {
        return null
      }
    })
  } else {
    return null
  }
}
export {fetchSpends as fetchSpends}

function addSpends(tx, spends) {
  tx.outputs.forEach((output, index) => {
    if (spends[index]) {
      output.spend = {
        txid: spends[index][0],
        vin: spends[index][1],
      }
    } else {
      output.spend = null
    }
  })
  return tx
}
export {addSpends as addSpends}

export async function searchTx (txid, input, output) {
  if (input != null) {
    urlPath.set(`/tx/${input}:${txid}`)
  } else if (output != null) {
    urlPath.set(`/tx/${txid}:${output}`)
  } else {
    urlPath.set(`/tx/${txid}`)
  }
  try {
    let searchResult = await fetchTx(txid)
    if (searchResult) {
      selectedTx.set(searchResult)
      detailTx.set(searchResult)
      overlay.set('tx')
      if (input != null || output != null) highlightInOut.set({txid, input, output})
      return null
    } else {
      return '500'
    }
  } catch (err) {
    console.log('error fetching tx ', err)
    return err.message
  }
}

export async function searchBlockHash (hash) {
  urlPath.set(`/block/${hash}`)
  overlay.set(null)
  try {
    const searchResult = await fetchBlockByHash(hash)
    if (searchResult) {
      if (searchResult.id) {
        explorerBlock.set(searchResult)
      }
      return null
    } else {
      return '500'
    }
  } catch (err) {
    console.log('error fetching block ', err)
    return err.message
  }
}

export async function searchBlockHeight (height) {
  urlPath.set(`/block/height/${height}`)
  overlay.set(null)
  try {
    const searchResult = await fetchBlockByHeight(height)
    if (searchResult) {
      if (searchResult.id) {
        explorerBlock.set(searchResult)
      }
      return null
    } else {
      return '500'
    }
  } catch (err) {
    console.log('error fetching block ', err)
    return err.message
  }
}
