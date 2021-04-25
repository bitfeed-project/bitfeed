import { writable, derived } from 'svelte/store'
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
		if (val != null) initial[field] = JSON.parse(val)
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
export const mempoolCount = createCounter()
export const mempoolScreenHeight = writable(0)
export const frameRate = writable(null)
export const avgFrameRate = writable(null)
export const blockVisible = writable(false)
export const currentBlock = writable(null)
export const selectedTx = writable(null)

export const settingsOpen = writable(false)

export const settings = createCachedDict('settings', {
	darkMode: true,
	showNetworkStatus: true,
	showFPS: false,
	fancyGraphics: true,
	showDonation: true
})

export const devSettings = (config.dev && config.debug) ? createCachedDict('dev-settings', {
	guides: false
}) : writable({})

export const sidebarToggle = writable(null)

export const nativeAntialias = writable(false)

const newVisitor = !localStorage.getItem('seen-welcome-msg')
// export const overlay = writable(newVisitor ? 'about' : null)
export const overlay = writable('lightning')
