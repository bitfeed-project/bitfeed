import { writable, derived } from 'svelte/store'
import { makePollStore } from './utils/pollStore.js'
import LocaleCurrency from 'locale-currency'
import { currencies } from './utils/fx.js'
import config from './config.js'

function createCounter () {
	const { subscribe, set, update } = writable(0)

	return {
		subscribe,
		set,
		add: (x) => update(n => n + x),
		subtract: (x) => update(n => n - x),
		increment: () => update(n => n + 1),
		decrement: () => update(n => n - 1),
		reset: () => set(0)
	}
}

function createCachedDict (namespace, defaultValues) {
	const initial = {
		...defaultValues
	}

	// load from local storage
	Object.keys(initial).forEach(field => {
		const val = localStorage.getItem(`${namespace}-${field}`)
		if (val != null) {
			try {
				initial[field] = JSON.parse(val)
			} catch (e) {
				initial[field] = val
			}
		}
	})

	const { subscribe, set, update } = writable(initial)

	return {
		subscribe,
		set: (val) => {
			set(val)
			Object.keys(val).forEach(field => {
				localStorage.setItem(`${namespace}-${field}`, val[field])
			})
		}
	}
}

// refresh exchange rates every minute
export const exchangeRates = makePollStore('rates', 'https://blockchain.info/ticker', 60000, {})
// refresh messages from donation server every hour
export const alerts =  config.messagesEnabled ? makePollStore('alerts', `${config.donationRoot}/api/sponsorship/msgs.json`, 3600000, []) : writable(null)
// refresh sponsor data every 10 minutes
export const heroes = makePollStore('heroes', `${config.donationRoot}/api/sponsorship/heroes.json`, 600000, null)
export const sponsors = makePollStore('sponsors', `${config.donationRoot}/api/sponsorship/sponsors.json`, 600000, null)
// refresh sponsorship tiers every hour
export const tiers = config.donationsEnabled ? makePollStore('tiers', `${config.donationRoot}/api/sponsorship/tiers.json`, 3600000, null) : writable(null)

export const haveMessages = derived([alerts], ([$alerts]) => {
	return (
		$alerts && $alerts.length
	)
})
export const haveSupporters = derived([heroes, sponsors], ([$heroes,$sponsors]) => {
	return (
		$heroes && Object.values($heroes).length
	)
})

export const darkMode = writable(true)
export const serverConnected = writable(false)
export const serverDelay = writable(1000)

export const devEvents = writable({
	addOneCallback: null,
	addManyCallback: null,
	addBlockCallback: null
})

export const txQueueLength = createCounter()
export const txCount = createCounter()
export const lastBlockId = writable(null)
export const mempoolCount = createCounter()
export const mempoolScreenHeight = writable(0)
export const frameRate = writable(null)
export const avgFrameRate = writable(null)
export const blockVisible = writable(false)
export const currentBlock = writable(null)
export const selectedTx = writable(null)
export const blockAreaSize = writable(0)

export const settingsOpen = writable(false)

let localeCurrencyCode = LocaleCurrency.getCurrency(navigator.language)
if (!currencies[localeCurrencyCode]) localeCurrencyCode = 'USD'

export const settings = createCachedDict('settings', {
	darkMode: true,
	showNetworkStatus: true,
	currency: localeCurrencyCode,
	showFX: true,
	vbytes: false,
	colorByFee: false,
	fancyGraphics: true,
	showMessages: true,
	noTrack: false
})
export const colorMode = derived([settings], ([$settings]) => {
	return $settings.colorByFee ? "fee" : "age"
})

export const devSettings = (config.dev && config.debug) ? createCachedDict('dev-settings', {
	guides: false,
	layoutHints: false,
}) : writable({})

export const sidebarToggle = writable(null)

export const nativeAntialias = writable(false)

const newVisitor = !localStorage.getItem('seen-welcome-msg')
// export const overlay = writable(newVisitor ? 'about' : null)
export const overlay = writable(null)

export const highlight = writable([])
export const newHighlightQuery = writable(null)
export const highlightingFull = writable(false)
