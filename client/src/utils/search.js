import api from './api.js'
import BitcoinTx from '../models/BitcoinTx.js'
import { detailTx, selectedTx, overlay, highlightInOut } from '../stores.js'
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
    return null /*{
      query: 'blockheight',
      height: asInt,
      value: asInt
    }*/
  }

  // Looks like a block hash?
  if (/^0{8}[a-f0-9]{56}$/.test(q)) {
    return null /* {
      query: 'blockhash',
      hash: query,
      value: query,
    }*/
  }

  // Looks like a transaction input?
  if (/^[0-9]+:[a-f0-9]{64}$/.test(q)) {
    const parts = q.split(':')
    return {
      query: 'input',
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
      txid: parts[0],
      output: parts[1],
      value: q
    }
  }

  // Looks like a transaction id?
  if (/^[a-f0-9]{64}$/.test(q)) {
    return {
      query: 'txid',
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

async function fetchTx (txid) {
  if (!txid) return
  try {
    const response = await fetch(`${api.uri}/api/tx/${txid}`, {
      method: 'GET'
    })
    const result = await response.json()
    const txData = result.tx
    txData.block = { height: result.blockheight, hash: result.blockhash, time: result.time * 1000 }
    return new BitcoinTx(txData, null, (txData.inputs && txData.inputs[0] && txData.inputs[0].prev_txid === "0000000000000000000000000000000000000000000000000000000000000000"))
  } catch (err) {
    console.log("failed to fetch tx ", txid)
    return null
  }
}

export async function searchTx(txid, input, output) {
  const searchResult = await fetchTx(txid)
  if (searchResult) {
    selectedTx.set(searchResult)
    detailTx.set(searchResult)
    overlay.set('tx')
    if (input != null || output != null) highlightInOut.set({txid, input, output})
    return true
  } else {
    return false
  }
}

export async function searchBlock(hash) {
  console.log("search block ", hash)
}
