export function subsidyAt(height) {
  const halvings = BigInt(Math.floor(height / 210000))
  if (halvings >= 64) return 0
  else {
    let sats = BigInt(5000000000)
    sats >>= halvings
    return Number(sats)
  }
}
