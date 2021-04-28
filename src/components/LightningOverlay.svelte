<script>
import analytics from '../utils/analytics.js'
import config from '../config.js'
import { onMount } from 'svelte'
import Overlay from '../components/Overlay.svelte'
import Icon from '../components/Icon.svelte'
import boltIcon from '../assets/icon/cil-bolt-filled.svg'
import tickIcon from '../assets/icon/cil-check-alt.svg'
import timerIcon from '../assets/icon/cil-av-timer.svg'
import { fade } from 'svelte/transition'
import { durationFormat } from '../utils/format.js'
import { overlay } from '../stores.js'

let amount = 5000
let invoice = null
let invoicePaid = false
let invoiceExpired = false
let invoicePoll
let pollingEnabled = false

let invoiceAmountLabel
let invoiceExpiryLabel
let invoiceHexLabel
const invoiceHexPlaceholder = 'lnbcxxxxxxt8l4pp5umz5kyakc0u8z3w2y568entyyq2gafgc3n5a7khdtk5m9fehkxnqdq6gf5hgen9v4jzqer0deshg6t0dccqzpgxqzjcsp5arlylwgraa2u75g4wh40swvxyvt0cpyrmnl4cha40uj5x2fr0t8q9qy9qsqzh3dtfag0ymaf8dpyxrly9p04jwlgdaxkh6g9ysaxyzz7jtrrkpsxv52mlzl6wgn6l6eur9yrl5q2quh5p8kagmng45gqjz9e2c6uxgqx5ezjr'
let qrSrc = null
$: {
  if (invoice && invoice.id && invoice.amount && invoice.BOLT11) {
    invoiceAmountLabel = `${Number.parseInt(invoice.amount) / 1000} sats`
    invoiceHexLabel = invoice.BOLT11
    qrSrc = `https://chart.googleapis.com/chart?chs=500x500&chld=L|2&cht=qr&chl=${invoice.BOLT11}`
  } else {
    stopExpiryTimer()
    invoiceAmountLabel = `${amount || 5000} sats`
    invoiceHexLabel = invoiceHexPlaceholder
    qrSrc = null
  }
}

let expiryTick
let expiresIn = null // time till expiry in seconds
$: {
  invoiceExpiryLabel = expiresIn == null ? '' : durationFormat.format(expiresIn * 1000)
}
$: {
  if ($overlay === 'lightning') {
    startExpiryTimer()
    stopPollingInvoice()
    pollingEnabled = true
    pollInvoice()
  } else {
    stopExpiryTimer()
    stopPollingInvoice()
    checkResetInvoice()
  }
}
function expiryTimer () {
  if (invoice && invoice.expiresAt) expiresIn = Math.round(((invoice.expiresAt * 1000) - Date.now()) / 1000)
  else expiresIn = null
}
function stopExpiryTimer () {
  if (expiryTick) clearInterval(expiryTick)
  expiryTick = null
}
function startExpiryTimer () {
  if (!expiryTick && $overlay === 'lightning' && invoice && invoice.id) {
    expiryTick = setInterval(expiryTimer, 200)
  }
}

onMount(() => {
  // check for existing invoice in local storage:
  const loadedInvoiceJSON = localStorage.getItem(`lightning-invoice`)
  localStorage.removeItem('lightning-invoice')
  if (loadedInvoiceJSON) {
    try {
      const loadedInvoice = JSON.parse(loadedInvoiceJSON)
      if (loadedInvoice && loadedInvoice.id && loadedInvoice.status && loadedInvoice.status === 'Unpaid' && (loadedInvoice.expiresAt * 1000) > Date.now()) {
        invoice = loadedInvoice
        processInvoice()
      }
    } catch (err) {
      console.log('error loading/parsing invoice')
    }
  }
})

function resetInvoice () {
  invoicePaid = false
  invoiceExpired = false
  invoice = null
  qrSrc = null
}

function checkResetInvoice () {
  if (invoice && invoice.status !== 'Unpaid') resetInvoice()
}

function stopPollingInvoice() {
  pollingEnabled = false
  if (invoicePoll) clearTimeout(invoicePoll)
  invoicePoll = null
}

function processInvoice () {
  if (invoice) {
    startExpiryTimer()
    if (invoice.status === 'Unpaid') {
      invoicePaid = false
      invoiceExpired = false
      localStorage.setItem('lightning-invoice', JSON.stringify(invoice))
      invoicePoll = setTimeout(pollInvoice, 2000)
    } else if (invoice.status === 'Paid') {
      invoicePaid = true
      invoiceExpired = false
      analytics.trackEvent('donations', 'lightning', 'paid', invoice.amount / 1000)
      localStorage.removeItem('lightning-invoice')
    } else if (invoice.status === 'Expired') {
      invoicePaid = false
      invoiceExpired = true
      localStorage.removeItem('lightning-invoice')
    }
  }
}

async function pollInvoice () {
  if (pollingEnabled && invoice && invoice.status === 'Unpaid') {
    const response = await fetch(`${config.dev ? config.devLightningRoot : ''}/api/lightning/invoice/${invoice.id}`, {
      method: 'GET'
    })
    invoice = await response.json()
    processInvoice()
  }
}

async function generateInvoice () {
  if (amount) {
    analytics.trackEvent('donations', 'lightning', 'generate', amount)
    resetInvoice()
    const response = await fetch(`${config.dev ? config.devLightningRoot : ''}/api/lightning/invoice`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ amount })
    })
    invoice = await response.json()
    if (invoice && invoice.amount) analytics.trackEvent('donations', 'lightning', 'generate-success', invoice.amount / 1000)
    processInvoice()
  }
}
</script>

<style type="text/scss">
  .info {
    p {
      text-align: justify;
    }

    .lightning-form {
      .sats-input {
        position: relative;
        display: inline-block;
        .units-label {
          position: absolute;
          top: 0;
          right: 1.4em;
          bottom: 0;
          text-align: right;
          color: var(--dark-c);
          top: 50%;
          transform: translateY(-50%);
        }
        input {
          margin: 0;
        }
      }

      .lightning-button {
        background: var(--bold-a);
        color: white;
        padding: 5px 8px;
        margin: .5em;
      }
    }

    .invoice-area {
      display: flex;
      flex-direction: row;
      align-items: stretch;
      flex-wrap: wrap;
    }

    .invoice-info {
      position: relative;
      padding: 10px;
      width: 280px;
      min-width: 200px;
      margin: .5em;
      flex: 1;

      .field {
        word-break: break-all;
        visibility: hidden;

        .field-label {
          font-weight: bold;
        }

        .hex {
          font-family: monospace;
        }
      }

      .placeholder-overlay {
        position: absolute;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 100%;
        border-radius: 10px;
        background: var(--dark-d);
        display: flex;
        justify-content: center;
        align-items: center;

        .placeholder-label {
          color: var(--light-a);
          opacity: 0.5;
        }
      }

      &.ready {
        .field {
          visibility: visible;
        }
      }
    }

    .qr-container {
      position: relative;
      flex: 1;
      width: 280px;
      min-width: 200px;
      min-height: 240px;
      margin: .5em;

      border-radius: 10px;
      background: var(--dark-d);
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;

      .invoice-status {
        font-weight: bold;
        font-size: 1.6em;
        color: white;
      }

      .invoice-icon {
        font-size: 8em;
      }

      .qr-image-wrapper {
        position: absolute;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: flex;
        justify-content: center;
        align-items: center;

        .qr-image {
          width: 90%;
          height: 90%;
          object-fit: contain;
          object-position: center;
        }
      }

      &.paid {
        background: var(--light-good);
      }

      &.expired {
        background: var(--light-unsure);
      }
    }
  }
</style>

<Overlay name="lightning">
  <section class="info">
    <h2>Donate with Lightning</h2>
    <p>
      Enter the amount you would like to donate, then click the button to generate a payment request:
    </p>

    <div class="lightning-form">
      <div class="sats-input">
        <input type="number" bind:value={amount}>
        <span class="units-label">sats</span>
      </div>
      <button class="lightning-button" on:click={generateInvoice} >
        <Icon icon={boltIcon} color="white" inline />
        {#if invoice && invoice.id }
          Generate New Request
        {:else}
          Generate Payment Request
        {/if}
      </button>
    </div>


    <div class="invoice-area">
      <div class="invoice-info" class:ready={invoice && invoice.id}>
        <p class="field invoice-amount"><span class="field-label">Amount:</span> { invoiceAmountLabel }</p>
        <p class="field invoice-expires"><span class="field-label">Expiry:</span> { invoiceExpiryLabel }</p>
        <p class="field invoice"><span class="field-label">Payment request:</span> <span class="hex">{ invoiceHexLabel }</span></p>
        {#if !invoice || !invoice.id }
          <div class="placeholder-overlay" transition:fade={{ duration: 300 }}>
            <p class="placeholder-label">Payment Request</p>
          </div>
        {/if}
      </div>

      <div class="qr-container" class:paid={invoicePaid} class:expired={invoiceExpired}>
        {#if invoicePaid }
          <div class="invoice-icon"><Icon icon={tickIcon} color="white" /></div>
          <h3 class="invoice-status">Recieved, Thanks!</h3>
        {:else if invoiceExpired}
          <div class="invoice-icon"><Icon icon={timerIcon} color="white" /></div>
          <h3 class="invoice-status">Request Expired</h3>
        {:else}
          <div class="invoice-icon"><Icon icon={boltIcon} color="white" /></div>
        {/if}
        {#if qrSrc && !invoicePaid && !invoiceExpired}
          <div class="qr-image-wrapper">
            <img src={qrSrc} class="qr-image" alt="invoice qr code">
          </div>
        {/if}
      </div>
    </div>
  </section>
</Overlay>
