import { writable } from 'svelte/store'

export function makePollStore (name, url, frequency, initialValue={}, responseHandler) {
  let timer
  const { subscribe, set, update } = writable(initialValue)
  if (!responseHandler) responseHandler = async (response, set) => {
    try {
      const data = await response.json()
      if (data) set(data)
    } catch (error) {
      console.log(`failed to parse polled data for ${name}: `, error)
    }
  }

  const fetcher = () => {
    fetch(`${url}?t=${Date.now()}`).then(response => { responseHandler(response, set) }).catch(err => {
      console.log(`error polling data for ${name}: `, error)
    })
  }
  fetcher()
  timer = setInterval(fetcher, frequency || 60000)

  return {
    subscribe,
    set,
    update
  }
}
