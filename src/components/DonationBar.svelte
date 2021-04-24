<script>
import { onMount } from 'svelte'
import Icon from '../components/Icon.svelte'
import config from '../config.js'
import { fly, fade } from 'svelte/transition'
// import { linear } from 'svelte/easing'
import coffeeIcon from '../assets/icon/cib-buy-me-a-coffee.svg'
import clipboardIcon from '../assets/icon/cil-clipboard.svg'
import qrIcon from '../assets/icon/cil-qr-code.svg'
import closeIcon from '../assets/icon/cil-x-circle.svg'
import openIcon from '../assets/icon/cil-arrow-circle-bottom.svg'
import boltIcon from '../assets/icon/cil-bolt-filled.svg'
import { overlay } from '../stores.js'

let copied = false
let addressElement

let showCopyButton = true
let expanded = false
let qrHidden = true
let qrLocked = false
let qrElement

onMount(() => {
  showCopyButton = (navigator && navigator.clipboard && navigator.clipboard.writeText) || !!addressElement
})

async function copyAddress () {
  if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
    await navigator.clipboard.writeText(config.donationAddress)
    copied = true
    setTimeout(() => {
      copied = false
    }, 2000)
  } else if (addressElement) {
    // fallback
    const range = document.createRange()
    range.selectNodeContents(addressElement)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    copied = document.execCommand('copy')
    setTimeout(() => {
      copied = false
      selection.removeAllRanges()
    }, 2000)
  }
}

function showQR () {
  qrHidden = false
}

function hideQR () {
  qrHidden = true
}

function clickaway (event) {
  console.log('clickaway', event)
  if (!qrElement.contains(event.target)) {
    qrLocked = false
    window.removeEventListener('click', clickaway)
  }
}

function toggleQR () {
  console.log('toggleQR', qrElement)
  qrLocked = !qrLocked
  window.addEventListener('click', clickaway)
}

function toggleExpanded () {
  expanded = !expanded
}

function openLightningOverlay () {
  console.log('opening lightning overlay')
  expanded = false
  $overlay = 'lightning'
}

</script>

<style type="text/scss">
  .donation-bar {
    z-index: 100;
    position: absolute;
    top: 0;
    width: 32rem;
    min-width: 100px;
    max-width: calc(100vw - 8.25rem);
    margin: auto;
    transition: width 300ms, max-width 300ms;

    .open-close-button {
      position: absolute;
      font-size: 1.2rem;
      bottom: -0.5em;
      right: 1rem;
      transform: rotate(0deg);
      background: var(--palette-c);
      border-radius: 50%;
      color: var(--palette-x);
      cursor: pointer;

      transition: transform 600ms;
    }

    .donation-content {
      padding: 5px 5px;

      background: var(--palette-c);
      color: var(--palette-x);

      border-bottom-left-radius: 5px;
      border-bottom-right-radius: 5px;

      .main-content {
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: center;

        .coffee-icon {
          font-size: 2rem;
        }

        .address-and-copy {
          display: flex;
          flex-direction: row;
          align-items: center;
          flex-shrink: 1;
          min-width: 4em;
        }

        .address {
          font-family: monospace;
          font-weight: bold;
          margin: 0 5px;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .copy-button, .qr-button {
          position: relative;
          margin: 0 .25em;
          font-size: 1.5rem;
          cursor: pointer;

          .copy-notif {
            font-size: .7rem;
            color: var(--palette-x);
            position: absolute;
            top: 100%;
            right: 0;
            background: var(--palette-d);
            border: solid 1px var(--palette-x);
            padding: 2px;
          }
        }
      }

      .donation-info {
        text-align: justify;
      }

      .expandable-content {
        max-height: 0;
        transition: max-height 300ms;
        overflow: hidden;
        padding: 0 0.5em 0.5em;
        font-size: 0.8em;

        .lightning-button {
          background: var(--bold-a);
          color: white;
          padding: 5px 8px;

          .lightning-icon {
            color: white;
          }
        }
      }
    }

    .address-qr {
      display: block;
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      margin: auto;
      max-width: 100vw;
      max-height: calc(100vh - 120px);
    }

    @media (min-width: 611px) {
      left: 110px;
      right: 110px;
    }

    @media (max-width: 610px) {
      right: 0;
    }

    &.expanded {
      max-width: 100vw;

      .open-close-button {
        transform: rotate(180deg);
      }

      .donation-content {
        .main-content {
          .address-and-copy {
            .address {
              word-break: break-all;
              overflow: visible;
              text-align: left;
            }
          }
        }

        .expandable-content {
          max-height: 200px;
        }
      }
    }
  }
</style>

<div class="donation-bar" transition:fly={{ y: -10 }} class:expanded>
  <div class="donation-content">
    <div class="main-content">
      <span class="coffee-icon">
        <Icon icon={coffeeIcon} color="var(--bold-a)" inline />
      </span>
      <div class="address-and-copy">
        <span class="address" bind:this={addressElement}>{ config.donationAddress }</span>
        {#if showCopyButton}
          <button class="copy-button" on:click={copyAddress} title="Copy address" alt="Copy address">
            <Icon icon={clipboardIcon} color="var(--palette-x)" />
            {#if copied }
              <span class="copy-notif" transition:fly={{ y: -5 }}>Copied to clipboard!</span>
            {/if}
          </button>
        {/if}
        <div class="qr-button" title="Show QR" on:pointerover={showQR} on:pointerenter={showQR} on:pointerleave={hideQR} on:pointerout={hideQR} on:pointercancel={hideQR} on:click={toggleQR} bind:this={qrElement}>
          <Icon icon={qrIcon} color="var(--palette-x)" />
        </div>
      </div>
    </div>
    <div class="expandable-content">
      <p class="donation-info">
        Enjoying Bitfeed? Donations keep this site running. On-chain transactions to the donation address above appear highlighted in green.
      </p>
      {#if config.lightningEnabled }
        <button class="lightning-button" on:click={openLightningOverlay} >
          <Icon icon={boltIcon} color="white" inline />Prefer Lightning?
        </button>
      {/if}
    </div>
  </div>
  {#if !qrHidden || qrLocked}
    <img src="/img/qr.png" alt="" class="address-qr" transition:fade={{ duration: 300 }} >
  {/if}
  <div class="open-close-button" on:click={toggleExpanded}>
    <Icon icon={openIcon} color="var(--palette-x)" />
  </div>
</div>
