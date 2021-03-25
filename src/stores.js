import { writable, derived } from 'svelte/store'

// const COLOR_MAP_TEX1 = 1

function createTxPool() {
	const { subscribe, set, update } = writable(0)

  set({})

	/*
		tx lifecycle:
		ADDED:
		  -> skip to matching lifecycle stage
		MEMPOOL:
			-> Fit to mempool grid
			-> Animate entry to mempool position
		MINED:
			-> Fit to block grid
			-> Animate mempool to block position
		EXPIRE:
			-> Animate block position to faded out
		GARBAGE:
			-> If expired & aged out, remove from tx pool
	*/

	const nextStatusMap = {
		'entry': 'mempool',
		'mempool': 'mining',
		'mining': 'mined',
		'mined': 'expired',
		'expired': 'remove'
	}

	const txStates = {
		ready: {
			next: 'entry',
			auto: true,
			makeCheckpoint: (from) => {
				return {
					x: Math.random() * window.innerWidth,
					y: -20,
					r: 20,
					p: 0.0,
					c: 0.0,
					a: 1.0
				}
			}
		},
		entry: {
			next: 'mempool',
			auto: true,
			duration: 1500,
			variance: 750,
			makeCheckpoint: (from) => {
				return {
					...from,
					y: window.innerHeight - 20,
					r: 20,
					p: 0.0,
					c: 0.0,
					a: 1.0
				}
			}
		},
		mempool: {
			next: 'mining',
			auto: false,
			duration: 5000,
			makeCheckpoint: (from) => {
				return {
					...from,
					r: 20,
					p: 0.0,
					c: 1.0,
					a: 1.0
				}
			}
		},
		mining: {
			next: 'mined',
			auto: true,
			duration: 300,
			makeCheckpoint: (from) => {
				return {
					...from,
					r: 30,
					p: 0.0,
					c: 0.0,
					a: 1.0
				}
			}
		},
		mined: {
			next: 'expired',
			auto: false,
			duration: 1000,
			delay: 300,
			delayVariance: 300,
			makeCheckpoint: (from) => {
				return {
					...from,
					x: window.innerWidth * 0.5,
					y: window.innerHeight * 0.5,
					r: 30,
					p: 0.0,
					c: 0.0,
					a: 1.0
				}
			}
		},
		expired: {
			auto: true,
			duration: 1000,
			makeCheckpoint: (from) => {
				return {
					...from,
					r: 80,
					p: 0.0,
					c: 0.0,
					a: 0.0
				}
			}
		}
	}

	function interpolateAnimationState (from, to, progress) {
		const clampedProgress = Math.max(0,Math.min(1,progress))
		return Object.keys(from).reduce((result, key) => {
			if (to[key] != null) {
				result[key] = from[key] + ((to[key] - from[key]) * clampedProgress)
			}
	    return result;
		}, from);
	}

	function applyTransition(tx, toStatus, now) {
		// get final target
		let target = {
			...tx.to || {}
		}
		let nextStatus = tx.status
		while (nextStatus !== toStatus && txStates[nextStatus].next) {
			nextStatus = txStates[nextStatus].next
			target = txStates[nextStatus].makeCheckpoint(target)
		}
		// previous transition completed
		const progress = tx.duration && tx.last ? (now - tx.last) / tx.duration : 0
		if (progress >= 1 || progress <= 0) {
			tx.from = {
				...tx.to
			}
		} else { // mid-transition
			tx.from = interpolateAnimationState(tx.from, tx.to, progress)
		}
		tx.to = target
		tx.last = now + (txStates[toStatus].delay ? (txStates[toStatus].delay + (txStates[toStatus].delayVariance ? (Math.random()-0.5) * txStates[toStatus].delayVariance * 2 : 0)) : 0)
		tx.duration = txStates[toStatus].duration + (txStates[toStatus].variance ? ((Math.random()-0.5) * txStates[toStatus].variance * 2) : 0)
		tx.v = 1 / tx.duration
		tx.status = toStatus
	}

	function initTx (meta) {
		const tx = {
			...meta
		}
		tx.status = 'ready'
		tx.from = txStates.ready.makeCheckpoint(tx)
		tx.to = {
			...tx.from
		}
		applyTransition(tx, 'entry', Date.now())
		return tx
	}

  function add (meta) {
    if (meta && meta.id) {
			const tx = initTx(meta)
      update(pool => {
        pool[meta.id] = tx
        return pool
      })
    }
  }

	function rotateTxs () {
		update(pool => {
			if (pool) {
				let now = Date.now()
				Object.keys(pool).forEach(key => {
					if (pool[key].status && txStates[pool[key].status] && txStates[pool[key].status].auto && (now - pool[key].last) > pool[key].duration) {
						if (txStates[pool[key].status].next) applyTransition(pool[key], txStates[pool[key].status].next, now)
						else delete pool[key]
					}
				})
				return pool
			} else return pool
		})
	}

	let expireTimeout

	function mineTxs (txIds) {
		if (expireTimeout) {
			clearTimeout(expireTimeout)
			expireBlock()
		}
		update(pool => {
			if (pool) {
				let newPool = {
					...pool
				}
				const now = Date.now()
				txIds.forEach(id => {
					if (newPool[id]) {
						applyTransition(newPool[id], newPool[id].status === 'mempool' ? 'mining' : 'mined', now)
						newPool[id].last = now + (Math.random() * 1.0) // animation delay uniformly distributed over 0.0 - 1.0 seconds
					}
				})
				return newPool
			} else return pool
		})
		expireTimeout = setTimeout(expireBlock, 5000)
	}

	function expireBlock() {
		expireTimeout = null
		update(pool => {
			if (pool) {
				let newPool = {
					...pool
				}
				const now = Date.now()
				Object.keys(newPool).forEach(id => {
					if (newPool[id].status === 'mining' || newPool[id].status === 'mined') {
						applyTransition(newPool[id], 'expired', now)
					}
				})
				return newPool
			} else return pool
		})
	}

  function remove (id) {
    update(pool => {
      delete pool[id]
      return pool
    })
  }

  function setStatus ({ id, status }) {
    update(pool => {
      if (pool[id] && pool[id].status !== status) {
        pool[id].status = status
				pool[id].last = Date.now()
      }
			return pool
    })
  }

	return {
		subscribe,
		add,
    remove,
		set,
    setStatus,
		mineTxs,
		rotateTxs
	}
}

export const txPool = createTxPool()

export const txList = derived(
	txPool,
	($txPool, set) => {
    if ($txPool) {
      set(Object.values($txPool))
    } else set([])
  }
)

export const darkMode = writable(true)

export const serverConnected = writable(false)
export const serverDelay = writable(1000)

function createCounter () {
	const { subscribe, set, update } = writable(0)

	return {
		subscribe,
		increment: () => update(n => n + 1),
		decrement: () => update(n => n - 1),
		reset: () => set(0)
	}
}

export const devEvents = writable({
	addOneCallback: null,
	addManyCallback: null,
	addBlockCallback: null
})

export const txQueueLength = createCounter()
export const txCount = createCounter()
export const frameRate = writable(null)
export const blockVisible = writable(false)
export const currentBlock = writable(null)

export const settingsOpen = writable(false)
export const settings = writable({
	darkMode: true,
	showNetworkStatus: true,
	showFPS: false,
	showDonation: true
})
export const devSettings = writable({
	guides: true
})
export const sidebarToggle = writable(null)
