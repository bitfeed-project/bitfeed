import { Buffer } from 'buffer/'
window.Buffer = Buffer
import bech32 from 'bech32-buffer'
import { base58_to_binary, binary_to_base58 } from 'base58-js'
import { sha256 } from 'hash.js'

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

// Extract an address from a raw scriptpubkey
export function SPKToAddress (spk) {
  if (spk.startsWith('5120')) {
    // taproot
    return (new bech32.BitcoinAddress('bc', 1, hexToUintArray(spk.slice(4)))).encode()
  } else if (spk.startsWith('0020') || spk.startsWith('0014')) {
    // p2wsh or p2wpkh
    return (new bech32.BitcoinAddress('bc', 0, hexToUintArray(spk.slice(4)))).encode()
  } else if (spk.startsWith('76a914')) {
    // p2pkh
    const payload = "00" + spk.slice(6, -4)
    const checksum = hash(hash(payload)).slice(0, 8)
    return binary_to_base58(hexToUintArray(payload + checksum))
  } else if (spk.startsWith('a914')) {
    // p2sh
    const payload = "05" + spk.slice(4, -2)
    const checksum = hash(hash(payload)).slice(0, 8)
    return binary_to_base58(hexToUintArray(payload + checksum))
  } else if (spk.startsWith('6a')) {
    // OP_RETURN
    return 'OP_RETURN'
  }
}

function hexToUintArray(hex) {
  let a = new Uint8Array(hex.length / 2)
  for (let i = 0; i < a.length; i++) {
    a[i] = parseInt(hex.substr(2 * i, 2), 16)
  }
  return a
}

function hash (hex) {
  return sha256().update(hexToUintArray(hex)).digest('hex')
}
