import { serverConnected, serverDelay } from '../stores.js'
import config from '../config.js'

class TxStream {
  constructor () {
    this.websocketUri = config.websocket_uri || (config.dev ? 'ws://localhost:4000/ws/txs' : `wss://${window.location.host}/ws/txs`)
    this.reconnectBackoff = 128
    this.websocket = null
    this.setConnected(false)
    this.setDelay(1000)
    this.lastBeat = Date.now()

    this.reconnectTimeout = null
    this.heartbeatTimeout = null

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
    try {
      this.websocket = new WebSocket(this.websocketUri)
      this.websocket.onopen = (evt) => { this.onopen(evt) }
      this.websocket.onclose = (evt) => { this.onclose(evt) }
      this.websocket.onmessage = (evt) => { this.onmessage(evt) }
      this.websocket.onerror = (evt) => { this.onerror(evt) }
    } catch (error) {
      // console.log('failed to open websocket: ', error)
    }
  }

  reconnect () {
    if (this.reconnectBackoff) clearTimeout(this.reconnectBackoff)
    if (!this.connected) {
      if (this.reconnectBackoff < 4000) this.reconnectBackoff *= 2
      this.reconnectTimeout = setTimeout(() => { this.init() }, this.reconnectBackoff)
    }
  }

  onHeartbeat () {
    if (this.heartbeatTimeout) clearTimeout(this.heartbeatTimeout)
    if (this.reconnectTimeout) clearTimeout(this.reconnectTimeout)
    this.setDelay(Date.now() - this.lastBeat)
    this.setConnected(true)
    this.heartbeatTimeout = setTimeout(() => { this.sendHeartbeat() }, 5000)
  }

  sendHeartbeat () {
    this.lastBeat = Date.now()
    this.websocket.send('hb')
    this.heartbeatTimeout = setTimeout(() => {
      this.onclose()
    }, 2000)
  }

  onopen (event) {
    if (this.heartbeatTimeout) clearTimeout(this.heartbeatTimeout)
    this.setConnected(true)
    this.setDelay(500)
    this.reconnectBackoff = 128
    this.sendHeartbeat()
  }

  onmessage (event) {
    if (!event) return

    if (event.data === 'hb') {
      this.onHeartbeat()
    } else {
      const msg = JSON.parse(event.data)
      if (msg && msg.type === 'txn') {
        window.dispatchEvent(new CustomEvent('bitcoin_tx', { detail: msg.txn }))
      } else if (msg && msg.type === 'block') {
        console.log('Block recieved: ', msg.block)
        window.dispatchEvent(new CustomEvent('bitcoin_block', { detail: msg.block }))
      } else {
        // console.log('unknown message from websocket: ', msg)
      }

    }
  }

  onerror (event) {
    // console.log('websocket error: ', event)
  }

  onclose (event) {
    this.setConnected(false)
    this.reconnect()
  }

  dosend (message) {
    this.websocket.send(message)
  }

  close () {
    if (this.websocket) this.websocket.close()
  }

  subscribe (type, callback) {
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
