export const currencies = {
  AUD: {
    char: 'AU$',
    pre: true,
    name: 'Australian Dollar',
    countries: [ 'Australia' ],
    dp: 2,
    code: 'AUD'
  },
  BRL: {
    char: 'R$',
    pre: true,
    name: 'Brazilian Real',
    countries: [ 'Brazil' ],
    dp: 2,
    code: 'BRL'
  },
  CAD: {
    char: 'CA$',
    pre: true,
    name: 'Canadian Dollar',
    countries: [ 'Canada' ],
    dp: 2,
    code: 'CAD'
  },
  CHF: {
    char: 'fr.',
    pre: false,
    name: 'Swiss Franc',
    countries: [ 'Switzerland' ],
    dp: 2,
    code: 'CHF'
  },
  CLP: {
    char: 'CLP$',
    pre: true,
    name: 'Chilean Peso',
    countries: [ 'Chile' ],
    dp: 2,
    code: 'CLP'
  },
  CNY: {
    char: '¥',
    pre: true,
    name: 'Chinese Yuan',
    countries: [ 'China' ],
    dp: 2,
    code: 'CNY'
  },
  CZK: {
    char: 'Kč',
    pre: false,
    name: 'Czech Koruna',
    countries: [ 'Czechia' ],
    dp: 2,
    code: 'CZK'
  },
  DKK: {
    char: 'kr.',
    pre: false,
    name: 'Danish Krone',
    countries: [ 'Denmark' ],
    dp: 2,
    code: 'DKK'
  },
  EUR: {
    char: '€',
    pre: true,
    name: 'Euro',
    countries: [
      'European Union', 'Austria',
      'Belgium',        'Cyprus',
      'Estonia',        'Finland',
      'France',         'Germany',
      'Greece',         'Ireland',
      'Italy',          'Latvia',
      'Lithuania',      'Luxembourg',
      'Malta',          'Netherlands',
      'Portugal',       'Slovakia',
      'Slovenia',       'Spain',
      'Andorra',        'Monaco',
      'San Marino',     'Vatican City',
      'Kosovo',         'Montenegro'
    ],
    dp: 2,
    code: 'EUR'
  },
  GBP: {
    char: '£',
    pre: true,
    name: 'Pound Sterling',
    countries: [ 'United Kingdom' ],
    dp: 2,
    code: 'GBP'
  },
  HKD: {
    char: 'HK$',
    pre: true,
    name: 'Hong Kong Dollar',
    countries: [ 'Hong Kong' ],
    dp: 2,
    code: 'HKD'
  },
  HRK: {
    char: 'kn',
    pre: false,
    name: 'Croatian Kuna',
    countries: [ 'Croatia' ],
    dp: 2,
    code: 'HRK'
  },
  HUF: {
    char: 'Ft',
    pre: false,
    name: 'Hungarian Forint',
    countries: [ 'Hungary' ],
    dp: 2,
    code: 'HUF'
  },
  INR: {
    char: '₹',
    pre: true,
    name: 'Indian Rupee',
    countries: [ 'India', 'Bhutan' ],
    dp: 2,
    code: 'INR'
  },
  ISK: {
    char: 'kr',
    pre: false,
    name: 'Icelandic Króna',
    countries: [ 'Iceland' ],
    dp: 2,
    code: 'ISK'
  },
  JPY: {
    char: '¥',
    pre: true,
    name: 'Japanese Yen',
    countries: [ 'Japan' ],
    dp: 2,
    code: 'JPY'
  },
  KRW: {
    char: '₩',
    pre: true,
    name: 'Korean Won',
    countries: [ 'South Korea' ],
    dp: 2,
    code: 'KRW'
  },
  NZD: {
    char: 'NZ$',
    pre: true,
    name: 'New Zealand Dollar',
    countries: [ 'New Zealand' ],
    dp: 2,
    code: 'NZD'
  },
  PLN: {
    char: 'zł',
    pre: false,
    name: 'Polish Złoty',
    countries: [ 'Poland' ],
    dp: 2,
    code: 'PLN'
  },
  RON: {
    char: 'L',
    pre: false,
    name: 'Romanian Leu',
    countries: [ 'Romania' ],
    dp: 2,
    code: 'RON'
  },
  RUB: {
    char: '₽',
    pre: false,
    name: 'Russian Ruble',
    countries: [ 'Russia' ],
    dp: 2,
    code: 'RUB'
  },
  SEK: {
    char: 'kr',
    pre: false,
    name: 'Swedish Krona',
    countries: [ 'Sweden' ],
    dp: 2,
    code: 'SEK'
  },
  SGD: {
    char: 'S$',
    pre: true,
    name: 'Singapore Dollar',
    countries: [ 'Singapore' ],
    dp: 2,
    code: 'SGD'
  },
  THB: {
    char: '฿',
    pre: true,
    name: 'Thai Baht',
    countries: [ 'Thailand' ],
    dp: 2,
    code: 'THB'
  },
  TRY: {
    char: '₺',
    pre: true,
    name: 'Turkish Lira',
    countries: [ 'Turkey' ],
    dp: 2,
    code: 'TRY'
  },
  TWD: {
    char: '圓',
    pre: true,
    name: 'New Taiwan Dollar',
    countries: [ 'Taiwan' ],
    dp: 2,
    code: 'TWD'
  },
  USD: {
    char: '$',
    pre: true,
    name: 'US Dollar',
    countries: [ 'United States', 'USA' ],
    dp: 2,
    code: 'USD'
  }
}


export function formatCurrency (code, amount, params) {
  // Support for Intl.NumberFormat not quite there yet for all currencies/locales
  // const format = new Intl.NumberFormat(currency.locale, {currency: currency.code, currencyDisplay: "symbol", style: "currency"})
  // return format.format(amount)
  const currency = currencies[code] || currencies.USD
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
    parts.push(amount.toLocaleString(undefined, { minimumFractionDigits: currency.dp, maximumFractionDigits: currency.dp }))
  }
  if (!currency.pre) parts = parts.reverse()
  return parts.join(' ')
}
