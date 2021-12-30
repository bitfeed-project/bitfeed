<script>
import analytics from '../utils/analytics.js'
import config from '../config.js'
import { onMount } from 'svelte'
import Overlay from '../components/Overlay.svelte'
import TierCard from './sponsor/TierCard.svelte'
import SatoshiSlider from './sponsor/SatoshiSlider.svelte'
import Pill from '../components/Pill.svelte'
import Icon from '../components/Icon.svelte'
import boltIcon from '../assets/icon/cil-bolt-filled.svg'
import chainIcon from '../assets/icon/cil-link.svg'
import tickIcon from '../assets/icon/cil-check-alt.svg'
import spinnerIcon from '../assets/icon/cil-sync.svg'
import timerIcon from '../assets/icon/cil-av-timer.svg'
import emailIcon from '../assets/icon/cil-envelope-closed.svg'
import clipboardIcon from '../assets/icon/cil-clipboard.svg'
import twitterIcon from '../assets/icon/cib-twitter.svg'
import { fade, fly } from 'svelte/transition'
import { durationFormat } from '../utils/format.js'
import { overlay } from '../stores.js'
import QRCode from 'qrcode'

let tab = 'form' // form | invoice | success
let waitingForInvoice = false

let unit = 'sats'
let sats = 2500
let btc = 0.000025
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

let invoiceUnit = 'sats'
let invoicePaidLabel
let invoiceAmountLabel
let invoiceExpiryLabel
let invoiceDestinationLabel
let invoiceHexLabel
const invoiceHexPlaceholder = 'lnbcxxxxxxt8l4pp5umz5kyakc0u8z3w2y568entyyq2gafgc3n5a7khdtk5m9fehkxnqdq6gf5hgen9v4jzqer0deshg6t0dccqzpgxqzjcsp5arlylwgraa2u75g4wh40swvxyvt0cpyrmnl4cha40uj5x2fr0t8q9qy9qsqzh3dtfag0ymaf8dpyxrly9p04jwlgdaxkh6g9ysaxyzz7jtrrkpsxv52mlzl6wgn6l6eur9yrl5q2quh5p8kagmng45gqjz9e2c6uxgqx5ezjr'
let qrSrc = null
let invoicePayments = []

let tierThresholds
let tiers = []

$: {
  if (tierThresholds) {
    tiers = [
      {
        title: 'Supporter',
        description: "Help to keep the lights on with a small donation",
        emoji: '🙏',
        color: 'var(--bold-b)',
        optional: true,
        min: 0.00005000,
        minSats: 5000,
        max: tierThresholds.hero.min,
        maxSats: btcToSats(tierThresholds.hero.min),
      },
      {
        title: 'Community Hero',
        description: "Add your Twitter profile to our Heroes Hall of Fame",
        emoji: '🦸',
        color: 'var(--bold-c)',
        min: tierThresholds.hero.min,
        minSats: btcToSats(tierThresholds.hero.min),
        max: tierThresholds.sponsor.min,
        maxSats: btcToSats(tierThresholds.sponsor.min),
      },
      {
        title: 'Enterprise Sponsor',
        description: "Display your logo on Bitfeed, with a link to your website",
        emoji: '🕴️',
        color: 'var(--bold-a)',
        min: tierThresholds.sponsor.min,
        minSats: btcToSats(tierThresholds.sponsor.min),
        max: Infinity,
        maxSats: Infinity,
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
    if (amount >= 0.001) {
      invoiceUnit = 'btc'
    } else {
      invoiceUnit = 'sats'
    }
    invoicePaidLabel = totalPaid ? amountToLabel(totalPaid, invoiceUnit) : null
    invoiceAmountLabel = amountToLabel(amount, invoiceUnit)

    invoiceDestinationLabel = selectedMethod.paymentMethod === 'BTC' ? 'Payment Address' : 'Payment Request'
    invoiceHexLabel = selectedMethod.destination
    setQR(selectedMethod.paymentLink)
  } else {
    qrSrc = null
    invoiceHexLabel = null
    invoicePaidLabel = null
    invoiceAmountLabel = null
    invoiceDestinationLabel = null
  }
}

let canTabLeft, canTabRight
$: {
  canTabLeft = (tab !== 'form')
  canTabRight = (tab === 'form' && !!invoice)
}
function setTab (to) {
  if (tab !== to) {
    tab = to
    const overlayInner = document.getElementById('donationOverlay')
    if (overlayInner) overlayInner.scrollTop = 0
  }
}
function tabLeft () {
  if (canTabLeft) setTab('form')
}
function tabRight () {
  if (canTabRight) setTab('invoice')
}

function amountToLabel (amount, unit) {
  if (unit === 'btc') {
    return `${amount} btc`
  } else {
    return `${btcToSats(amount)} sats`
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
  showCopyButton = (navigator && navigator.clipboard && navigator.clipboard.writeText) || !!invoiceSpan

  // check for existing invoice in local storage:
  const loadedInvoiceJSON = localStorage.getItem(`donation-invoice`)
  // localStorage.removeItem('donation-invoice')
  if (loadedInvoiceJSON) {
    try {
      const loadedInvoice = JSON.parse(loadedInvoiceJSON)
      if (loadedInvoice && loadedInvoice.id && loadedInvoice.status && (loadedInvoice.status === 'New' || loadedInvoice.status === 'Processing') && (loadedInvoice.expirationTime * 1000) > Date.now()) {
        setTab('invoice')
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
  setTab('form')
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
  if (state && invoice && invoice.id === state.id) {
    invoice = state
    if (invoice.status === 'Settled') {
      invoicePaid = true
      invoiceExpired = false
      invoiceProcessing = false
      analytics.trackEvent('donations', 'invoice', 'paid', btcToSats(invoice.amount))
      localStorage.removeItem('donation-invoice')
      invoice = null
      setTab('success')
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

    invoicePayments = []

    if (invoice.paymentMethods) {
      chainInvoice = null
      lightningInvoice = null
      invoice.paymentMethods.forEach(method => {
        if (method.paymentMethod === 'BTC-LightningNetwork') {
          processLightningInvoice(method)
        }
        else if (method.paymentMethod === 'BTC') processChainInvoice(method)
      })
    }
  }
}

function processNewInvoice (newInvoice, fillForm = false) {
  invoice = newInvoice
  if (newInvoice) {
    payOnChain = true

    startExpiryTimer()

    updateInvoice(newInvoice)

    if (fillForm) {
      if (invoice.amount) {
        setAmount(invoice.amount, true)
      }

      if (invoice.metadata) {
        if (invoice.metadata.twitter) twitter = invoice.metadata.twitter
        if (invoice.metadata.email) email = invoice.metadata.email
        if (invoice.metadata.isPrivate != null) isPrivate = !!invoice.metadata.isPrivate
      }
    }

    if (canPayLightning && invoice.amount && invoice.amount < 0.001) {
      payOnChain = false
    } else {
      payOnChain = true
    }
  }
}

function satsToBtc (sats) {
  return sats / 100000000
}
function btcToSats (btc) {
  return Math.round(btc * 100000000)
}

function setAmount (amount, inBTC = false) {
  if (inBTC) {
    sats = btcToSats(amount)
    btc = amount
  } else {
    sats = amount
    btc = satsToBtc(amount)
  }
}

function processLightningInvoice (invoice) {
  canPayLightning = true
  lightningInvoice = invoice
  if (invoice && invoice.payments && invoice.payments.length) {
    invoicePayments = invoicePayments.concat(invoice.payments)
  }
}

function processChainInvoice (invoice) {
  canPayOnChain = true
  chainInvoice = invoice
  if (invoice && invoice.payments && invoice.payments.length) {
    invoicePayments = invoicePayments.concat(invoice.payments)
  }
}

async function pollInvoice () {
  if (pollingEnabled && invoice && (invoice.status === 'New' || invoice.status === 'Processing')) {
    try {
      const response = await fetch(`${config.donationRoot}/api/invoice/${invoice.id}`, {
        method: 'GET'
      })
      let invoiceState = await response.json()
      updateInvoice(invoiceState)
    } catch (e) {
      console.log('error polling invoice: ', e)
    }
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
        amount: satsToBtc(sats),
        twitter,
        email,
        isPrivate
      })
    })
    let newInvoice = await response.json()
    if (newInvoice && newInvoice.amount) {
      analytics.trackEvent('donations', 'invoice', 'generate-success', btcToSats(newInvoice.amount))
      setTab('invoice')
    }
    processNewInvoice(newInvoice)
    waitingForInvoice = false
  }
}

function togglePaymentMethod () {
  payOnChain = !payOnChain
}

function toggleUnits () {
  if (unit === 'sats') unit = 'btc'
  else unit = 'sats'
}

let copied = false
let showCopyButton = true
let invoiceSpan

async function copyInvoice () {
  if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
    await navigator.clipboard.writeText(invoiceHexLabel)
    copied = true
    setTimeout(() => {
      copied = false
    }, 2000)
  } else if (invoiceSpan) {
    // fallback
    const range = document.createRange()
    range.selectNodeContents(invoiceSpan)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    copied = document.execCommand('copy')
    setTimeout(() => {
      copied = false
      selection.removeAllRanges()
    }, 2000)
  }
  analytics.trackEvent('donations', 'invoice', 'copy')
}
</script>

<Overlay name="donation" fullHeight>
  <section class="donation-modal">
    <div class="tab-nav">
      <button class="to left" class:disabled={!canTabLeft} on:click={tabLeft}>&larr;</button>
      <h2>Support Bitfeed</h2>
      <button class="to right" class:disabled={!canTabRight} on:click={tabRight}>&rarr;</button>
    </div>

    <div class="modal-tabs show-{tab}">
      <div class="tab form">
        <p class="info">
          Every satoshi helps to keep Bitfeed running and funds development of new features!
        </p>
        <p class="info">
          We accept donations in Bitcoin, either on-chain or over Lightning.
        </p>
        <p class="info">
          Choose your level of support:
        </p>

        <div class="support-tiers">
          {#each tiers as tier}
            <TierCard {...tier} active={btc >= tier.min && btc < tier.max} on:click={() => { setAmount(tier.min || 0.00005000, true) }} />
          {/each}
        </div>

        <!-- <div class="sats-slider">slider</div> -->

        <div class="choose-amount">
          <div class="amount-slider">
            <SatoshiSlider value={sats} max={btcToSats(1)} thresholds={tiers} logScale on:input={(e) => { setAmount(e.detail)}} />
          </div>
          <div class="amount-input">
            {#if unit === 'sats'}
              <input type="number" value={sats} step="100" min="100" on:input={(e) => { setAmount(e.target.value, false) }}>
            {:else}
              <input type="number" value={btc} step="0.0001" min="0.000001" on:input={(e) => { setAmount(e.target.value, true) }}>
            {/if}
          </div>
          <div class="unit-picker">
            <Pill left="sats" right="btc" active={unit === 'btc'} on:click={toggleUnits} />
          </div>
        </div>

        {#if tierThresholds && btc >= tierThresholds.hero.min}
          {#if btc >= tierThresholds.sponsor.min}
            <p class="credit-info">
              Enter your email or twitter handle so we can reach you to say thanks and confirm sponsorship details! Or leave these fields blank to donate anonymously.
            </p>
          {:else}
            <p class="credit-info">
              Enter your twitter handle to be added to our Heroes Hall of Fame! Or leave this field blank to donate anonymously.
            </p>
          {/if}


          <div class="donor-info-form">
            <div class="field">
              <label for="twitterHandle">Twitter</label>
              <div class="text-input twitter prefixed">
                <span class="icon-wrapper"><Icon icon={twitterIcon} inline /></span>
                <span class="prefix">@</span>
                <input id="twitterHandle" type="text" bind:value={twitter}>
              </div>
            </div>
            {#if btc >= tierThresholds.sponsor.min}
              <div class="field">
                <label for="twitterHandle">Email</label>
                <div class="text-input email-input">
                  <span class="icon-wrapper"><Icon icon={emailIcon} inline /></span>
                  <input id="emailAddress" type="email" bind:value={email}>
                </div>
              </div>
            {/if}
          </div>
        {/if}

        <button class="action-button" on:click={generateInvoice} >
          {#if waitingForInvoice }
            <span class="animate-spin"><Icon icon={spinnerIcon} /></span> loading
          {:else if invoice && invoice.id }
            Request a new invoice
          {:else}
            Request an invoice
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
            <p class="field invoice-amount"><span class="field-label">Amount:</span> { invoiceAmountLabel }</p>
            {#if invoicePaidLabel}
              <p class="field invoice-paid"><span class="field-label">Total Received:</span> { invoicePaidLabel }</p>
            {/if}
            {#if invoicePayments && invoicePayments.length}
            <ul class="payments">
              {#each invoicePayments as payment, index }
                <li class="field payment-status">Payment #{ index + 1 }: {amountToLabel(payment.value, invoiceUnit)} ({ payment.status })</li>
              {/each}
            </ul>
            {/if}
            <p class="field invoice-expires"><span class="field-label">Expiry:</span> { invoiceExpiryLabel }</p>
            <p class="field invoice"><span class="field-label">{ invoiceDestinationLabel }:</span> <span class="hex" bind:this={invoiceSpan}>{ invoiceHexLabel || invoiceHexPlaceholder }</span></p>
            {#if showCopyButton}
              <button class="copy-button" on:click={copyInvoice} title="Copy to clipboard" alt="Copy to clipboard">
                <Icon icon={clipboardIcon} color="var(--palette-x)" />
                {#if copied }
                  <span class="copy-notif" transition:fly={{ y: -5 }}>Copied to clipboard!</span>
                {/if}
              </button>
            {/if}
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

        <button class="action-button" on:click={() => {setTab('form')}} >
            Start Over
        </button>
      </div>
      <div class="tab success">
        <div class="qr-container paid">
          <h3 class="invoice-status">Confirmed</h3>
          <div class="invoice-icon"><Icon icon={tickIcon} color="white" /></div>
          <h3 class="invoice-status">Thank you!</h3>
        </div>
      </div>
    </div>
  </section>
</Overlay>

<style type="text/scss">
  .donation-modal {
    font-size: 0.9rem;

    p.info {
      text-align: center;
      margin: 0 0 .25em;
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

    input {
      margin: 0;
      border-radius: 5px;
    }

    .support-tiers {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
      justify-content: center;
      align-items: stretch;
    }

    .choose-amount {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;

      .amount-slider {
        width: 100%;
        flex-grow: 1;
        flex-shrink: 1;
      }
    }

    .amount-input {
      position: relative;
      display: inline-block;
      margin: 0 20px 1em;
      width: 200px;
      flex-shrink: 1;
      min-width: 160px;
      input {
        margin: 0;
        width: 100%;
      }
    }

    .unit-picker {
      width: 160px;
      flex-shrink: 0;
      margin-bottom: 1em;
    }

    .donor-info-form {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
      justify-content: center;
      align-items: baseline;

      .field {
        display: flex;
        flex-direction: row;
        flex-wrap: nowrap;
        justify-content: flex-start;
        align-items: baseline;
        width: 400px;
        max-width: 100%;
        flex-shrink: 1;
        flex-grow: 0;
        margin-bottom: .5em;

        .text-input {
          position: relative;
          margin: 0 1em;
          flex-grow: 1;
          flex-shrink: 1;

          input {
            padding-left: 3em;
            flex-grow: 1;
            flex-shrink: 1;
            width: 100%;
          }

          .icon-wrapper, .prefix {
            position: absolute;
            color: var(--palette-a);
          }
          .icon-wrapper {
            top: 0;
            bottom: 0;
            left: 0;
            width: 2em;
            display: flex;
            justify-content: center;
            align-items: center;
            border-top-left-radius: 5px;
            border-bottom-left-radius: 5px;
            background: var(--twitter-blue);
            color: white;
            fill: white;
            stroke: white;
          }
          .prefix {
            left: 2em;
            bottom: 0.4em;
            width: 1.6em;
            text-align: right;
          }

          &.prefixed {
            input {
              padding-left: 4em;
            }
          }
        }
      }
    }

    .action-button {
      background: var(--bold-a);
      color: white;
      padding: 0.5em 2em;
      margin: 1em 2em 0.5em;
      font-size: 1.1em;
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

      .payment-status {
        margin-left: 1em;
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

    .copy-button {
      position: relative;
      float: right;
      margin: 0 .25em;
      font-size: 1.5rem;
      cursor: pointer;

      .copy-notif {
        font-size: .7rem;
        color: var(--palette-x);
        position: absolute;
        top: 0;
        right: 125%;
        background: var(--palette-d);
        border: solid 1px var(--palette-x);
        padding: 2px;
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
