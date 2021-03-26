export function logTxSize (value, max) {
  // console.log('calculating txSize', value)
  let scale = Math.ceil(Math.log10(value)) - 5
  // console.log(scale)
  return Math.min(max || Infinity,Math.max(1, scale)) // bound between 1 and the max displayable size (just in case!)
}
