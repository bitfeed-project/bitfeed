// Use Intl formatting utilities where available, else fall back to simple formatting

export const shortBtcFormat = (Intl && Intl.NumberFormat) ? new Intl.NumberFormat(undefined, { minimumSignificantDigits: 8, maximumSignificantDigits: 8 }) : {
  format (number) {
    return Number(number).toPrecision(8).slice(0,9)
  }
}
export const longBtcFormat = (Intl && Intl.NumberFormat) ? new Intl.NumberFormat(undefined, { maximumFractionDigits: 8 }) : {
  format (number) {
    return Number(number).toFixed(8)
  }
}
export const timeFormat = (Intl && Intl.DateTimeFormat) ? new Intl.DateTimeFormat(undefined, { timeStyle: "short"}) : {
  format (date) {
    const d = new Date(date)
    return `${('' + d.getHours()).padStart(2, '0')}:${('' + d.getMinutes()).padStart(2, '0')}`
  }
}
export const integerFormat = (Intl && Intl.NumberFormat) ? new Intl.NumberFormat(undefined) : {
  format (number) {
    return Number(number).toLocaleString()
  }
}

const relativeTimeFormat = (Intl && Intl.RelativeTimeFormat && false) ? new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' }) : {
  format (time, unit) {
    return `${Number(Math.abs(time)).toLocaleString()} ${unit}${time < 0 ? ' ago' : ''}`
  }
}

export const durationFormat = {
  format (milliseconds) {
    const seconds = milliseconds / 1000
    const absSeconds = Math.abs(seconds)
    if (absSeconds < 1) return 'now'
    else if (absSeconds < 60) return relativeTimeFormat.format(seconds, 'seconds')
    else return relativeTimeFormat.format(Math.round(seconds / 60), 'minutes')
  }
}
