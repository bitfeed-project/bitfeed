import { serverConnected, serverDelay, lastBlockId } from '../stores.js'
import config from '../config.js'
import api from '../utils/api.js'

let mempoolTimer
let lastBlockSeen
lastBlockId.subscribe(val => { lastBlockSeen = val })


class TxStream {
  constructor () {
    console.log('connecting to ', api.uri)
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
          this.websocket = new WebSocket(api.websocketUri)
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
  }

  async fetchBlock (id, calledOnLoad) {
    if (!id) return
    if (id !== lastBlockSeen) {
      try {
        console.log('downloading block', id)
        const response = await fetch(`${api.uri}/api/block/${id}`, {
          method: 'GET'
        })
        let blockData = await response.json()
        console.log('downloaded block', id)
        window.dispatchEvent(new CustomEvent('bitcoin_block', { detail: { block: blockData, realtime: !calledOnLoad} }))
      } catch (err) {
        console.log("failed to download block ", id)
      }
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

        if (!msg) throw new Error('null websocket message')

        switch (msg.type) {

          // reply to a last block_id request message
          case 'block_id':
            this.fetchBlock(msg.block_id, true)
            break;

          // notification of tx added to mempool
          case 'txn':
            window.dispatchEvent(new CustomEvent('bitcoin_tx', { detail: msg.txn }))
            break;

          // notification of tx dropped from mempool
          case 'drop':
            window.dispatchEvent(new CustomEvent('bitcoin_drop_tx', { detail: msg.txid }))
            break;

          // notification of a new block
          case 'block':
            if (msg.block && msg.block.id) {
              this.fetchBlock(msg.block.id)
            }
            break;
        }

        // all events can include a count field, with the latest mempool size
        if (msg.count) window.dispatchEvent(new CustomEvent('bitcoin_mempool_count', { detail: msg.count }))
      } catch (err) {
        console.log('error parsing msg json: ', err)
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
