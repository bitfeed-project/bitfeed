import { addressToSPK } from './encodings.js'

// Quick heuristic matching to guess what kind of search a query is for
// ***does not validate that a given address/txid/block is valid***
export function matchQuery (query) {
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
