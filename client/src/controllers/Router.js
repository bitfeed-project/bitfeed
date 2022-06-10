import { urlPath, settings, loading, detailTx, highlightInOut, explorerBlock, overlay } from '../stores.js'
import { searchTx, searchBlockHash, searchBlockHeight } from '../utils/search.js'

export default class Router {
  constructor (initialPath = '/') {
    this.path = initialPath
    this.apply(initialPath)
    urlPath.subscribe(val => {
      if (val != null) {
        this.pushHistory(val)
        this.path = val
      }
    })
    window.addEventListener('popstate', e => {
      if (e && e.state && e.state.path) {
        this.path = e.state.path
        this.apply(e.state.path)
      }
    })
  }

  pushHistory (path, replace = false) {
    if (replace) {
      window.history.replaceState({path}, "", path, window.history.state)
    } else if (path !== this.path) {
      window.history.pushState({path}, "", path)
    }
  }

  clearPath () {
    urlPath.set("/")
  }

  apply (path) {
    const parts = path.split("/")
    if (path === '/') {
      detailTx.set(null)
      highlightInOut.set(null)
      urlPath.set("/")
      explorerBlock.set(null)
      overlay.set(null)
    } else {
      switch (parts[1]) {
        case 'block':
          if (parts[2] === "height") {
            try {
              const height = parseInt(parts[3])
              this.goToBlockHeight(height)
            } catch (err) {
              // ??
            }
          } else if (parts[2]) {
            this.goToBlock(parts[2])
          }
        break;

        case 'tx':
          if (parts[2]) {
            this.goToTransaction(parts[2])
          }
        break;

        case 'donate':
          overlay.set('donation')
        break;
      }
    }
  }

  async goToBlock (blockhash) {
    loading.increment()
    await searchBlockHash(blockhash)
    loading.decrement()
  }

  async goToBlockHeight (height) {
    loading.increment()
    await searchBlockHeight(height)
    loading.decrement()
  }

  async goToTransaction (q) {
    loading.increment()
    const parts = q.split(":")
    let txid, input, output
    if (parts.length) {
      if (parts[0].length == 64) {
        txid = parts[0]
        output = parseInt(parts[1])
        if (isNaN(output)) output = null
      } else if (parts[1].length == 64) {
        txid = parts[1]
        input = parseInt(parts[0])
        if (isNaN(input)) input = null
      } else {
        // invalid
      }
    } else {
      txid = q
    }
    await searchTx(txid, input, output)
    loading.decrement()
  }
}
