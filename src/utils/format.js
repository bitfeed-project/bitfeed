export const shortBtcFormat = new Intl.NumberFormat(undefined, { minimumSignificantDigits: 8, maximumSignificantDigits: 8 })
export const longBtcFormat = new Intl.NumberFormat(undefined, { maximumFractionDigits: 8 })
export const timeFormat = new Intl.DateTimeFormat(undefined, { timeStyle: "short"})
export const integerFormat = new Intl.NumberFormat(undefined)
