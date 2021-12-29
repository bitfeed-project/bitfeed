<script>
import analytics from '../utils/analytics.js'
import config from '../config.js'
import { onMount } from 'svelte'
import Overlay from '../components/Overlay.svelte'
import TierCard from './sponsor/TierCard.svelte'
import Pill from '../components/Pill.svelte'
import Icon from '../components/Icon.svelte'
import boltIcon from '../assets/icon/cil-bolt-filled.svg'
import chainIcon from '../assets/icon/cil-link.svg'
import tickIcon from '../assets/icon/cil-check-alt.svg'
import spinnerIcon from '../assets/icon/cil-sync.svg'
import timerIcon from '../assets/icon/cil-av-timer.svg'
import { fade, fly } from 'svelte/transition'
import { durationFormat } from '../utils/format.js'
import { overlay } from '../stores.js'
import QRCode from 'qrcode'

let tab = 'form' // form | invoice | success
let waitingForInvoice = false

let sats = 5000
let btc = 0.00005
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

let tierThresholds
let tiers = []

$: {
  if (tierThresholds) {
    tiers = [
      {
        title: 'Supporter',
        description: "Help keep the lights on with a small donation",
        min: 0,
        max: tierThresholds.hero.min,
      },
      {
        title: 'Community Hero',
        description: "Add your twitter profile to our Heroes' Hall of Fame",
        min: tierThresholds.hero.min,
        max: tierThresholds.sponsor.min,
      },
      {
        title: 'Enterprise Sponsor',
        description: "Display your logo on Bitfeed, with a link to your website",
        min: tierThresholds.sponsor.min,
        max: Infinity,
      }
    ]
  }
}


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

let canTabLeft, canTabRight
$: {
  canTabLeft = (tab !== 'form')
  canTabRight = (tab === 'form' && !!invoice)
}
function tabLeft () {
  if (canTabLeft) tab = 'form'
}
function tabRight () {
  if (canTabRight) tab = 'invoice'
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
        tab = 'invoice'
        processNewInvoice(loadedInvoice, true)
      }
    } catch (err) {
      console.log('error loading/parsing invoice')
    }
  }
  loadTiers()
})

async function loadTiers () {
  try {
    const r = await fetch(`${config.donationRoot}/api/sponsorship/tiers.json`)
    tierThresholds = await r.json()
  } catch (e) {
    console.log('failed to load sponsorship tiers')
    console.log(e)
  }
}

function resetInvoice () {
  invoicePaid = false
  invoiceExpired = false
  invoice = null
  tab = 'form'
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

function updateInvoice (state) {
  // do not overwrite the state of a different invoice
  if (state && invoice.id === state.id) {
    invoice = state
    if (invoice.status === 'Settled') {
      invoicePaid = true
      invoiceExpired = false
      invoiceProcessing = false
      analytics.trackEvent('donations', 'invoice', 'paid', invoice.amount * 100000000)
      localStorage.removeItem('donation-invoice')
      invoice = null
      tab = 'success'
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
  }
}

function processNewInvoice (newInvoice, fillForm = false) {
  invoice = newInvoice
  if (newInvoice) {
    startExpiryTimer()

    updateInvoice(newInvoice)

    if (invoice.paymentMethods) {
      chainInvoice = null
      lightningInvoice = null
      invoice.paymentMethods.forEach(method => {
        if (method.paymentMethod === 'BTC-LightningNetwork') processLightningInvoice(method)
        else if (method.paymentMethod === 'BTC') processChainInvoice(method)
      })
    }

    if (fillForm) {
      if (invoice.amount) setAmount(invoice.amount, true)

      if (invoice.metadata) {
        if (invoice.metadata.twitter) twitter = invoice.metadata.twitter
        if (invoice.metadata.email) email = invoice.metadata.email
        if (invoice.metadata.isPrivate != null) isPrivate = !!invoice.metadata.isPrivate
      }
    }
  }
}

function setAmount (amount, inBTC = false) {
  if (inBTC) {
    sats = Math.round(amount * 100000000)
    btc = amount
  } else {
    sats = amount
    btc = amount / 100000000
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
    let invoiceState = await response.json()
    updateInvoice(invoiceState)
  }
}

async function generateInvoice () {
  if (sats) {
    analytics.trackEvent('donations', 'invoice', 'generate', sats)
    resetInvoice()
    waitingForInvoice = true
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
    if (newInvoice && newInvoice.amount) {
      analytics.trackEvent('donations', 'invoice', 'generate-success', newInvoice.amount * 100000000)
      tab = 'invoice'
    }
    processNewInvoice(newInvoice)
    waitingForInvoice = false
  }
}

function togglePaymentMethod () {
  payOnChain = !payOnChain
}
</script>

<Overlay name="donation" fullHeight>
  <section class="donation-modal">
    <div class="tab-nav">
      <button class="to left" class:disabled={!canTabLeft} on:click={tabLeft}>&larr;</button>
      <h2>Support Bitfeed</h2>
      <button class="to right" class:disabled={!canTabRight} on:click={tabRight}>&rarr;</button>
    </div>
    <p class="info">
      Every satoshi helps to keep Bitfeed running and funds development of new features!
    </p>

    <div class="modal-tabs show-{tab}">
      <div class="tab form">
        <div class="support-tiers">
          {#each tiers as tier}
            <TierCard {...tier} active={btc >= tier.min && btc < tier.max} on:click={() => { setAmount(tier.min || 0.00005000, true) }} />
          {/each}
        </div>

        <!-- <div class="sats-slider">slider</div> -->

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

        <button class="action-button" on:click={generateInvoice} >
          {#if waitingForInvoice }
            <span class="animate-spin"><Icon icon={spinnerIcon} /></span> loading
          {:else if invoice && invoice.id }
            Generate New Invoice
          {:else}
            Generate Donation Invoice
          {/if}
        </button>
      </div>
      <div class="tab invoice">
        <div class="method-toggle">
          <Pill leftDisabled={!canPayOnChain} rightDisabled={!canPayLightning} active={!payOnChain} on:click={togglePaymentMethod}>
            <span slot="left"><Icon icon={chainIcon} inline /> On-Chain</span>
            <span slot="right"><Icon icon={boltIcon} inline /> Lightning</span>
          </Pill>
        </div>
        <div class="invoice-area">
          <div class="invoice-info" class:ready={invoice && invoice.id}>
            <p class="field invoice-sats"><span class="field-label">Amount:</span> { invoiceSatsLabel }</p>
            <p class="field invoice-expires"><span class="field-label">Expiry:</span> { invoiceExpiryLabel }</p>
            <p class="field invoice"><span class="field-label">{ invoiceDestinationLabel }:</span> <span class="hex">{ invoiceHexLabel || invoiceHexPlaceholder }</span></p>
            {#if !invoice || !invoice.id || !invoiceHexLabel }
              <div class="placeholder-overlay" transition:fade={{ duration: 300 }}>
                <p class="placeholder-label">Payment Details</p>
              </div>
            {/if}
          </div>

          <div class="qr-container" class:expired={invoiceExpired}>
            {#if invoiceExpired}
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

        <button class="action-button" on:click={() => {tab = 'form'}} >
            Start Over
        </button>
      </div>
      <div class="tab success">
        <div class="qr-container paid">
          <h3 class="invoice-status">Received</h3>
          <div class="invoice-icon"><Icon icon={tickIcon} color="white" /></div>
          <h3 class="invoice-status">Thank you!</h3>
        </div>
      </div>
    </div>
  </section>
</Overlay>

<style type="text/scss">
  .donation-modal {
    p.info {
      text-align: center;
    }

    .tab-nav {
      position: relative;
      width: 100%;

      .to {
        position: absolute;
        top: 0;
        color: white;
        font-size: 2em;
        font-weight: 600;
        transition: opacity 200ms;

        &.disabled {
          opacity: 0;
        }

        &.left {
          left: 0;
        }
        &.right {
          right: 0;
        }
      }
    }

    .modal-tabs {
      position: relative;
      width: 100%;
      overflow-x: hidden;
      display: flex;
      flex-direction: row;

      .tab {
        transition: transform 300ms;
        width: 100%;
        flex-shrink: 0;
        flex-grow: 0;
      }

      &.show-form .tab {
        transform: translateX(0);
      }
      &.show-invoice .tab {
        transform: translateX(-100%);
      }
      &.show-success .tab {
        transform: translateX(-200%);
      }
    }

    .support-tiers {
      display: flex;
      flex-direction: row;
      justify-content: space-between;
      align-items: stretch;
    }

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

    .action-button {
      background: var(--bold-a);
      color: white;
      padding: 5px 15px;
      margin: .5em 1em;
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
      text-align: left;

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
      max-width: 500px;
      min-height: 400px;
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

    .tab.success {
      display: flex;
      flex-direction: row;
      justify-content: center;
    }
  }
</style>
