import { serverConnected, serverDelay } from '../stores.js'

class TxStream {
  constructor () {
    this.websocketUri = 'ws://localhost:4000/ws/txs'
    this.reconnectBackoff = 128
    this.websocket = null
    this.setConnected(false)
    this.setDelay(1000)
    this.lastBeat = Date.now()

    this.reconnectTimeout = null
    this.heartbeatTimeout = null

    console.log(this)
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
    try {
      this.websocket = new WebSocket(this.websocketUri)
      this.websocket.onopen = (evt) => { this.onopen(evt) }
      this.websocket.onclose = (evt) => { this.onclose(evt) }
      this.websocket.onmessage = (evt) => { this.onmessage(evt) }
      this.websocket.onerror = (evt) => { this.onerror(evt) }
    } catch (error) {
      console.log('failed to open websocket: ', error)
    }
  }

  reconnect () {
    console.log('reconnect')
    if (this.reconnectBackoff) clearTimeout(this.reconnectBackoff)
    if (!this.connected) {
      if (this.reconnectBackoff < 4000) this.reconnectBackoff *= 2
      console.log(`reconnecting after ${this.reconnectBackoff / 1000} seconds`)
      this.reconnectTimeout = setTimeout(() => { this.init() }, this.reconnectBackoff)
    }
  }

  onHeartbeat () {
    // console.log('heartbeat recieved')
    if (this.heartbeatTimeout) clearTimeout(this.heartbeatTimeout)
    if (this.reconnectTimeout) clearTimeout(this.reconnectTimeout)
    this.setDelay(Date.now() - this.lastBeat)
    // console.log(`heartbeat delay of ${this.delay}ms`)
    this.setConnected(true)
    this.heartbeatTimeout = setTimeout(() => { this.sendHeartbeat() }, 5000)
  }

  sendHeartbeat () {
    // console.log('sending heartbeat')
    this.lastBeat = Date.now()
    this.websocket.send('hb')
    this.heartbeatTimeout = setTimeout(() => {
      console.log('heartbeat timed out')
      this.onclose()
    }, 2000)
  }

  onopen (event) {
    console.log('tx websocket connected')
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
        console.log('unknown message from websocket: ', msg)
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
    console.log('sending to websocket: ', message)
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
