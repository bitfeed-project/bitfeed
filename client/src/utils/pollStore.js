import { writable } from 'svelte/store'

export function makePollStore (name, url, frequency, initialValue={}, responseHandler) {
  let interval, timer
  const { subscribe, set, update } = writable(initialValue)
  if (!responseHandler) responseHandler = async (response, set) => {
    const data = await response.json()
    if (data) set(data)
  }

  const fetcher = () => {
    fetch(`${url}?t=${Date.now()}`).then(response => { responseHandler(response, set) }).catch(error => {
      console.log(`error polling data for ${name}: `, error)
      if (timer) clearTimeout(timer)
      timer = setTimeout(fetcher, 5000)
    })
  }
  fetcher()
  interval = setInterval(fetcher, frequency || 60000)

  return {
    subscribe,
    set,
    update
  }
}
