import { writable, derived } from 'svelte/store'
import { geoRobinson } from 'd3-geo-projection'

const projection = geoRobinson()

function createTxPool() {
	const { subscribe, set, update } = writable(0)

  set({})

  function add (tx) {
    if (tx && tx.id) {
			if (tx.coords) {
	      const position = projection([tx.coords.lng, tx.coords.lat])
	      tx.p = {
	        x: position[0],
	        y: position[1]
	      }
			} else if (tx.p) {
				const coords = projection.invert([tx.p.x, tx.p.y])
	      tx.coords = {
	        lng: coords[0],
	        lat: coords[1]
	      }
				console.log('adding tx on click: ', tx)
			}
			tx.last = Date.now()
      update(pool => {
        pool[tx.id] = tx
        return pool
      })
    }
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
    setStatus
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
