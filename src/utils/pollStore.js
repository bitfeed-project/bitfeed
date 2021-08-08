import { writable } from 'svelte/store'

function makeRatePollStore () {
  let timer
  const { subscribe, set, update } = writable({})

  const fetcher = () => {
    fetch(`https://blockchain.info/ticker?t=${Date.now()}`).then(async response => {
      const rates = await response.json()
      set(rates)
    }).catch(err => {
      console.log('error fetching exchange rates: ', err)
    })
  }
  fetcher()
  timer = setInterval(fetcher, 60000)

  return {
    subscribe,
    set,
    update
  }
}

export const exchangeRates = makeRatePollStore()
