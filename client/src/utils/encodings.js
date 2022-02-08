import { Buffer } from 'buffer/'
window.Buffer = Buffer
import bech32 from 'bech32-buffer'
import { base58_to_binary } from 'base58-js'

// Extract a raw script hash from an address
export function addressToSPK (address) {
  if (address.startsWith('bc1')) {
    const result = bech32.BitcoinAddress.decode(address)
    let prefix
    if (result.scriptVersion == 1) prefix = '5120' // taproot (OP_PUSHNUM_1 OP_PUSHBYTES_32)
    else if (address.length == 62) prefix = '0020' // p2wsh (OP_0 OP_PUSHBYTES_32)
    else prefix = '0014' // p2wpkh (OP_0 OP_PUSHBYTES_20)
    return prefix + Buffer.from(result.data).toString('hex')
  } else {
    const result = base58_to_binary(address)
    let prefix, postfix
    if (address.charAt(0) === '1') {
      prefix = '76a914' // p2pkh (OP_DUP OP_HASH160 OP_PUSHBYTES_20)
      postfix = '88ac' // p2pkh (OP_EQUALVERIFY OP_CHECKSIG)
    } else {
      prefix = 'a914' // p2sh (OP_HASH160 OP_PUSHBYTES_20)
      postfix = '87' // p2sh (OP_EQUAL)
    }
    return prefix + Buffer.from(result).toString('hex').slice(2, -8) + postfix
  }
}
