<script>
import analytics from '../utils/analytics.js'
import config from '../config.js'
import { onMount } from 'svelte'
import Overlay from '../components/Overlay.svelte'
import Pill from '../components/Pill.svelte'
import Icon from '../components/Icon.svelte'
import boltIcon from '../assets/icon/cil-bolt-filled.svg'
import tickIcon from '../assets/icon/cil-check-alt.svg'
import timerIcon from '../assets/icon/cil-av-timer.svg'
import { fade } from 'svelte/transition'
import { durationFormat } from '../utils/format.js'
import { overlay } from '../stores.js'
import QRCode from 'qrcode'

let sats = 5000
let twitter = null
let email = null
let isPrivate = false

let payOnChain = true

let invoice = null
let invoicePaid = false
let invoiceExpired = false
let invoiceProcessing = false
let lightningInvoice, chainInvoice, selectedMethod
let invoicePoll
let pollingEnabled = false

let invoicePaidLabel
let invoiceSatsLabel
let invoiceExpiryLabel
let invoiceDestinationLabel
let invoiceHexLabel
const invoiceHexPlaceholder = 'lnbcxxxxxxt8l4pp5umz5kyakc0u8z3w2y568entyyq2gafgc3n5a7khdtk5m9fehkxnqdq6gf5hgen9v4jzqer0deshg6t0dccqzpgxqzjcsp5arlylwgraa2u75g4wh40swvxyvt0cpyrmnl4cha40uj5x2fr0t8q9qy9qsqzh3dtfag0ymaf8dpyxrly9p04jwlgdaxkh6g9ysaxyzz7jtrrkpsxv52mlzl6wgn6l6eur9yrl5q2quh5p8kagmng45gqjz9e2c6uxgqx5ezjr'
let qrSrc = null

let canPayOnChain, canPayLightning
$: {
  canPayOnChain = !!chainInvoice
  canPayLightning = !!lightningInvoice

  if (!canPayOnChain && payOnChain) payOnChain = false
  else if (!canPayLightning && !payOnChain) payOnChain = true
  selectedMethod = (payOnChain ? chainInvoice : lightningInvoice)
  if (selectedMethod) {
    let totalPaid = Number.parseFloat(selectedMethod.totalPaid)
    let amount = Number.parseFloat(selectedMethod.amount)
    sats = Math.round(amount * 100000000)
    if (amount >= 0.01) {
      invoicePaidLabel = `${totalPaid.toFixed(8)} btc`
      invoiceSatsLabel = `${amount.toFixed(8)} btc`
    } else {
      invoicePaidLabel = `${Math.round(totalPaid * 100000000)} sats`
      invoiceSatsLabel = `${Math.round(amount * 100000000)} sats`
    }
    invoiceDestinationLabel = selectedMethod.paymentMethod === 'BTC' ? 'Payment Address' : 'Payment Request'
    invoiceHexLabel = selectedMethod.destination
    setQR(selectedMethod.paymentLink)
  } else {
    qrSrc = null
    invoiceHexLabel = null
    invoicePaidLabel = null
    invoiceSatsLabel = null
    invoiceDestinationLabel = null
  }
}

async function setQR(invoice) {
  try {
    qrSrc = await QRCode.toDataURL(invoice.toUpperCase())
  } catch (err) {
    console.log('error generating QR code: ', err)
  }
}

let expiryTick
let expiresIn = null // time till expiry in seconds
$: {
  invoiceExpiryLabel = expiresIn == null ? '' : durationFormat.format(expiresIn * 1000)
}
$: {
  if ($overlay === 'donation') {
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
  if (invoice && invoice.expirationTime) expiresIn = Math.round(((invoice.expirationTime * 1000) - Date.now()) / 1000)
  else expiresIn = null
}
function stopExpiryTimer () {
  if (expiryTick) clearInterval(expiryTick)
  expiryTick = null
}
function startExpiryTimer () {
  if (!expiryTick && $overlay === 'donation' && invoice && invoice.id) {
    stopExpiryTimer()
    expiryTick = setInterval(expiryTimer, 200)
  }
}

onMount(() => {
  // check for existing invoice in local storage:
  const loadedInvoiceJSON = localStorage.getItem(`donation-invoice`)
  // localStorage.removeItem('donation-invoice')
  if (loadedInvoiceJSON) {
    try {
      const loadedInvoice = JSON.parse(loadedInvoiceJSON)
      if (loadedInvoice && loadedInvoice.id && loadedInvoice.status && (loadedInvoice.status === 'New' || loadedInvoice.status === 'Processing') && (loadedInvoice.expirationTime * 1000) > Date.now()) {
        processInvoice(loadedInvoice)
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
  if (invoice && (invoice.status === 'New' || invoice.status === 'Processing')) resetInvoice()
}

function stopPollingInvoice() {
  pollingEnabled = false
  if (invoicePoll) clearTimeout(invoicePoll)
  invoicePoll = null
}

function processInvoice (newInvoice) {
  invoice = newInvoice
  if (invoice) {
    startExpiryTimer()
    if (invoice.status === 'Settled') {
      invoicePaid = true
      invoiceExpired = false
      invoiceProcessing = false
      analytics.trackEvent('donations', 'lightning', 'paid', invoice.amount * 100000000)
      localStorage.setItem('donation-invoice', JSON.stringify(invoice))
      // localStorage.removeItem('donation-invoice')
    } else if (invoice.status === 'Expired' || invoice.status === "Invalid" || (invoice.expirationTime * 1000) < Date.now()) {
      invoicePaid = false
      invoiceExpired = true
      invoiceProcessing = false
      localStorage.setItem('donation-invoice', JSON.stringify(invoice))
      // localStorage.removeItem('donation-invoice')
    } else if (invoice.status === 'New') {
      invoicePaid = false
      invoiceExpired = false
      invoiceProcessing = false
      localStorage.setItem('donation-invoice', JSON.stringify(invoice))
      invoicePoll = setTimeout(pollInvoice, 2000)
    } else if (invoice.status === 'Processing') {
      invoicePaid = false
      invoiceExpired = false
      invoiceProcessing = true
      localStorage.setItem('donation-invoice', JSON.stringify(invoice))
      invoicePoll = setTimeout(pollInvoice, 2000)
    }

    if (invoice.paymentMethods) {
      chainInvoice = null
      lightningInvoice = null
      invoice.paymentMethods.forEach(method => {
        if (method.paymentMethod === 'BTC-LightningNetwork') processLightningInvoice(method)
        else if (method.paymentMethod === 'BTC') processChainInvoice(method)
      })
    }

    if (invoice.metadata) {
      if (invoice.metadata.twitter) twitter = invoice.metadata.twitter
      if (invoice.metadata.email) email = invoice.metadata.email
      if (invoice.metadata.isPrivate != null) isPrivate = !!invoice.metadata.isPrivate
    }
  }
}

function processLightningInvoice (invoice) {
  canPayLightning = true
  lightningInvoice = invoice
}

function processChainInvoice (invoice) {
  canPayOnChain = true
  chainInvoice = invoice
}

async function pollInvoice () {
  if (pollingEnabled && invoice && (invoice.status === 'New' || invoice.status === 'Processing')) {
    const response = await fetch(`${config.donationRoot}/api/invoice/${invoice.id}`, {
      method: 'GET'
    })
    let newInvoice = await response.json()
    processInvoice(newInvoice)
  }
}

async function generateInvoice () {
  if (sats) {
    analytics.trackEvent('donations', 'invoice', 'generate', sats)
    resetInvoice()
    const response = await fetch(`${config.donationRoot}/api/invoice/new`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        amount: (sats / 100000000),
        twitter,
        email,
        isPrivate
      })
    })
    let newInvoice = await response.json()
    if (newInvoice && newInvoice.amount) analytics.trackEvent('donations', 'lightning', 'generate-success', newInvoice.amount * 100000000)
    processInvoice(newInvoice)
  }
}

function togglePaymentMethod () {
  payOnChain = !payOnChain
}
</script>

<Overlay name="donation">
  <section class="info">
    <h2>Support Bitfeed</h2>
    <p>
      Every satoshi helps to keep Bitfeed running and funds development of new features!
    </p>

    <div class="donation-form">
      <div class="support-tiers">
        supporter
        community hero
        enterprise sponsor
      </div>

      <div class="sats-slider">slider</div>

      <div class="sats-input">
        <input type="number" bind:value={sats}>
        <span class="units-label">sats</span>
      </div>

      <div class="twitter-input">
        <input type="text" bind:value={twitter}>
      </div>

      <div class="email-input">
        <input type="email" bind:value={email}>
      </div>

      <div class="keep-private">
        <input type="checkbox" bind:value={isPrivate}>
      </div>

      <button class="lightning-button" on:click={generateInvoice} >
        {#if invoice && invoice.id }
          Generate New Invoice
        {:else}
          Generate Donation Invoice
        {/if}
      </button>

      <div class="method-toggle">
        <Pill left="On-Chain" leftEnabled={canPayOnChain} right="Lightning" rightEnabled={canPayLightning} active={!payOnChain} on:click={togglePaymentMethod} />
      </div>

      <div class="invoice-area">
        <div class="invoice-info" class:ready={invoice && invoice.id}>
          <p class="field invoice-sats"><span class="field-label">sats:</span> { invoiceSatsLabel }</p>
          <p class="field invoice-expires"><span class="field-label">Expiry:</span> { invoiceExpiryLabel }</p>
          <p class="field invoice"><span class="field-label">{ invoiceDestinationLabel }:</span> <span class="hex">{ invoiceHexLabel || invoiceHexPlaceholder }</span></p>
          {#if !invoice || !invoice.id || !invoiceHexLabel }
            <div class="placeholder-overlay" transition:fade={{ duration: 300 }}>
              <p class="placeholder-label">Payment Details</p>
            </div>
          {/if}
        </div>

        <div class="qr-container" class:paid={invoicePaid} class:expired={invoiceExpired}>
          {#if invoicePaid }
            <div class="invoice-icon"><Icon icon={tickIcon} color="white" /></div>
            <h3 class="invoice-status">Received, Thanks!</h3>
          {:else if invoiceExpired}
            <div class="invoice-icon"><Icon icon={timerIcon} color="white" /></div>
            <h3 class="invoice-status">Invoice Expired</h3>
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
    </div>
  </section>
</Overlay>

<style type="text/scss">
  .info {
    p {
      text-align: justify;
    }

    .donation-form {
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
        padding: 5px 15px;
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
