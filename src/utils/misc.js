export function logTxSize (value, max) {
  let scale = Math.ceil(Math.log10(value)) - 5
  // console.log(scale)
  return Math.min(max || Infinity,Math.max(1, scale)) // bound between 1 and the max displayable size (just in case!)
}

export function byteTxSize (vbytes, max, log) {
  if (!vbytes) vbytes = 1
  let scale = Math.max(1,Math.ceil(Math.sqrt(vbytes/144)))
  return Math.min(max || Infinity,Math.max(1, scale)) // bound between 1 and the max displayable size (just in case!)
}
