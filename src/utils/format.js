export const shortBtcFormat = new Intl.NumberFormat(undefined, { minimumSignificantDigits: 8, maximumSignificantDigits: 8 })
export const longBtcFormat = new Intl.NumberFormat(undefined, { maximumFractionDigits: 8 })
export const timeFormat = new Intl.DateTimeFormat(undefined, { timeStyle: "short"})
export const integerFormat = new Intl.NumberFormat(undefined)

const relativeTimeFormat = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' })
export const durationFormat = {
  format (milliseconds) {
    const seconds = milliseconds / 1000
    const absSeconds = Math.abs(seconds)
    if (absSeconds < 1) return 'now'
    else if (absSeconds < 60) return relativeTimeFormat.format(seconds, 'seconds')
    else return relativeTimeFormat.format(Math.round(seconds / 60), 'minutes')
  }
}
