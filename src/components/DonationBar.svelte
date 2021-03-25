<script>
import { onMount } from 'svelte'
import Icon from '../components/Icon.svelte'
import config from '../config.js'
import { fly } from 'svelte/transition'
// import { linear } from 'svelte/easing'
import coffeeIcon from '../assets/icon/cib-buy-me-a-coffee.svg'
import clipboardIcon from '../assets/icon/cil-clipboard.svg'

let copied = false
let addressElement

let showCopyButton = true

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

</script>

<style type="text/scss">
  .donation-bar {
    z-index: 100;
    position: absolute;
    top: 0;
    width: 500px;
    min-width: 100px;
    max-width: calc(100vw - 110px);
    margin: auto;
    transition: width 300ms, max-width 300ms;

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

        .copy-button {
          position: relative;
          background: none;
          border: none;
          padding: 0;
          margin: 0;
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

      .expandable-content {
        max-height: 0;
        transition: max-height 300ms;
        overflow: hidden;

        .donation-info {
          font-size: 0.8em;
        }

        .address-qr {
          display: none;
          position: absolute;
          top: 100%;
          left: 0;
          right: 0;
          margin: auto;
          max-width: 100vw;
        }
      }
    }

    @media (min-width: 611px) {
      left: 110px;
      right: 110px;
    }

    @media (max-width: 610px) {
      right: 0;
    }

    &:hover {
      max-width: 100vw;

      .donation-content {
        .main-content {
          flex-wrap: wrap;

          .address-and-copy {
            .address {
              word-break: break-all;
              overflow: visible;
              text-align: left;
            }
          }
        }

        .address-qr {
          display: block;
          max-width: 100%;
        }

        .expandable-content {
          max-height: 100px;
        }
      }
    }
  }
</style>

<div class="donation-bar" transition:fly={{ y: -10 }}>
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
      </div>
    </div>
    <div class="expandable-content">
      <p class="donation-info">
        Thank you! Donations help to keep this site running. Transactions to the donation address appear highlighted in green.
      </p>
      <img src="/img/qr.png" alt="" class="address-qr">
    </div>
  </div>
</div>
