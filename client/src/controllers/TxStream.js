import { serverConnected, serverDelay, lastBlockId } from '../stores.js'
import config from '../config.js'

let mempoolTimer
let lastBlockSeen
lastBlockId.subscribe(val => { lastBlockSeen = val })


class TxStream {
  constructor () {
    this.apiRoot = `${config.backend ? config.backend : window.location.host }${config.backendPort ? ':' + config.backendPort : ''}`
    this.websocketUri = `${config.secureSocket ? 'wss://' : 'ws://'}${this.apiRoot}/ws/txs`
    this.apiUri = `${config.secureSocket ? 'https://' : 'http://'}${this.apiRoot}`
    console.log('connecting to ', this.websocketUri)
    this.reconnectBackoff = 250
    this.websocket = null
    this.setConnected(false)
    this.setDelay(0)
    this.lastBeat = performance.now()

    this.reconnectTimeout = null
    this.heartbeatTimeout = null

    this.delayInterval = setInterval(() => {
      if (this.lastBeat && this.connected) {
        this.setDelay(performance.now() - this.lastBeat)
      }
    }, 789)

    this.init()
  }

  setConnected (connected) {
    this.connected = connected
    serverConnected.set(connected)
  }

  setDelay (delay) {
    this.delay = delay
    serverDelay.set(delay)
  }

  init () {
    console.log('initialising websocket')
    if (!this.connected && (!this.websocket || this.websocket.readyState === WebSocket.CLOSED)) {
      if (this.websocket) this.disconnect()
      else {
        try {
          this.websocket = new WebSocket(this.websocketUri)
          this.websocket.onopen = (evt) => { this.onopen(evt) }
          this.websocket.onclose = (evt) => { this.onclose(evt) }
          this.websocket.onmessage = (evt) => { this.onmessage(evt) }
          this.websocket.onerror = (evt) => { this.onerror(evt) }
        } catch (error) {
          this.reconnect()
        }
      }
    } else this.reconnect()
  }

  reconnect () {
    if (this.reconnectBackoff) clearTimeout(this.reconnectBackoff)
    if (!this.connected) {
      console.log('......trying to reconnect websocket')
      if (this.reconnectBackoff < 8000) this.reconnectBackoff *= (Math.random()+1)
      this.reconnectTimeout = setTimeout(() => { this.init() }, this.reconnectBackoff)
    }
  }

  onHeartbeat () {
    if (this.heartbeatTimeout) clearTimeout(this.heartbeatTimeout)
    if (this.reconnectTimeout) clearTimeout(this.reconnectTimeout)
    this.setDelay(performance.now() - this.lastBeat)
    this.lastBeat = null
    this.setConnected(true)
    this.heartbeatTimeout = setTimeout(() => {
      this.sendHeartbeat()
    }, 5000)
  }

  sendHeartbeat () {
    if (this.heartbeatTimeout) clearTimeout(this.heartbeatTimeout)
    this.lastBeat = performance.now()
    if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
      this.lastBeat = performance.now()
      this.websocket.send('hb')
      this.heartbeatTimeout = setTimeout(() => {
        this.setDelay(performance.now() - this.lastBeat)
      }, 5000)
    }
  }

  sendBlockRequest () {
    if (config.noBlockFeed) return
    console.log('Checking for missed blocks...')
    this.websocket.send("block_id")
  }

  sendMempoolRequest () {
    this.websocket.send('count')
    if (mempoolTimer) clearTimeout(mempoolTimer)
    mempoolTimer = setTimeout(() => { this.sendMempoolRequest() }, 60000)
  }

  disconnect () {
    console.log('disconnecting websocket')
    if (this.websocket) {
      this.websocket.onopen = null
      this.websocket.onclose = null
      this.websocket.onmessage = null
      this.websocket.onerror = null
      this.websocket.close()
      this.websocket = null
    }
    this.setConnected(false)
    this.setDelay(0)
    this.reconnect()
  }

  onopen (event) {
    console.log('websocket opened')
    this.setConnected(true)
    this.setDelay(0)
    this.reconnectBackoff = 128
    this.sendHeartbeat()
    this.sendBlockRequest()
    this.sendMempoolRequest()
  }

  async fetchBlock (id, calledOnLoad) {
    if (id !== lastBlockSeen) {
      console.log('downloading block', id)
      const response = await fetch(`${this.apiUri}/block/${id}`, {
        method: 'GET'
      })
      let blockData = await response.json()
      window.dispatchEvent(new CustomEvent('bitcoin_block', { detail: { block: blockData, realtime: !calledOnLoad} }))
    } else {
      console.log('already seen block ', lastBlockSeen)
    }
  }

  onmessage (event) {
    if (!event) return
    if (event.data === 'hb') {
      this.onHeartbeat()
    } else if (event.data === 'error') {
      // ignore
    } else {
      try {
        const msg = JSON.parse(event.data)
        if (msg && msg.type === 'count') {
          window.dispatchEvent(new CustomEvent('bitcoin_mempool_count', { detail: msg.count }))
        } else if (msg && msg.type === 'block_id') {
          this.fetchBlock(msg.block_id)
        } else if (msg && msg.type === 'txn') {
          window.dispatchEvent(new CustomEvent('bitcoin_tx', { detail: msg.txn }))
        } else if (msg && msg.type === 'block') {
          if (msg.block && msg.block.id) {
            this.fetchBlock(msg.block.id)
          }
        } else {
          // console.log('unknown message from websocket: ', msg)
        }
      } catch (err) {
        // console.log('error parsing msg json: ', err)
      }
    }
  }

  onerror (event) {
    console.log('websocket error: ', event)
  }

  onclose (event) {
    console.log('websocket closed')
    this.setConnected(false)
    this.reconnect()
  }

  dosend (message) {
    this.websocket.send(message)
  }

  close () {
    console.log('closing websocket')
    if (this.websocket) this.websocket.close()
  }

  subscribe (type, callback) {
    console.log(`subscribing to bitcoin ${type} events`)
    window.addEventListener('bitcoin_'+type, (event) => {
      callback(event.detail)
    })
  }
}

let txStream

export default function getTxStream () {
  if (!txStream) {
    txStream = new TxStream()
  }
  return txStream
}
