export const symbols = {
  AUD: {
    char: "AU$",
    pre: true
  },
  BRL: {
    char: "R$",
    pre: true
  },
  CAD: {
    char: "CA$",
    pre: true
  },
  CHF: {
    char: "fr.",
    pre: false
  },
  CLP: {
    char: "CLP$",
    pre: true
  },
  CNY: {
    char: "¥",
    pre: true
  },
  CZK: {
    char: "Kč",
    pre: false
  },
  DKK: {
    char: "kr.",
    pre: false
  },
  EUR: {
    char: "€",
    pre: true
  },
  GBP: {
    char: "£",
    pre: true
  },
  HKD: {
    char: "HK$",
    pre: true
  },
  HRK: {
    char: "kn",
    pre: false
  },
  HUF: {
    char: "Ft",
    pre: false
  },
  INR: {
    char: "₹",
    pre: true
  },
  ISK: {
    char: "kr",
    pre: false
  },
  JPY: {
    char: "¥",
    pre: true
  },
  KRW: {
    char: "₩",
    pre: true
  },
  NZD: {
    char: "NZ$",
    pre: true
  },
  PLN: {
    char: "zł",
    pre: false
  },
  RON: {
    char: "L",
    pre: false
  },
  RUB: {
    char: "₽",
    pre: false
  },
  SEK: {
    char: "kr",
    pre: false
  },
  SGD: {
    char: "S$",
    pre: true
  },
  THB: {
    char: "฿",
    pre: true
  },
  TRY: {
    char: "₺",
    pre: true
  },
  TWD: {
    char: "圓",
    pre: true
  },
  USD: {
    char: "$",
    pre: true
  }
}

export function formatCurrency (code, amount, params) {
  // Support for Intl.NumberFormat not quite there yet for all currencies/locales
  // const format = new Intl.NumberFormat(currency.locale, {currency: currency.code, currencyDisplay: "symbol", style: "currency"})
  // return format.format(amount)
  const currency = symbols[code] || symbols.USD
  let parts = [currency.char]
  if (params && params.compact) {
    let compacted = amount
    let suffixIndex = 0
    while (amount > 1000 && suffixIndex < 4) {
      amount /= 1000
      suffixIndex++
    }
    let precision
    if (suffixIndex == 0 && amount >= 10 && amount < 100) precision = 4
    else precision = 3

    const amountPart = amount < 1000 ? amount.toPrecision(precision) : Math.round(amount)
    parts.push(`${amountPart}${['','K','M','B','T'][suffixIndex]}`)
  } else {
    parts.push(amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }))
  }
  if (!currency.pre) parts = parts.reverse()
  return parts.join(' ')
}
