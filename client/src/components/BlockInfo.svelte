<script>
  import analytics from '../utils/analytics.js'
  import { fly } from 'svelte/transition'
  import { linear } from 'svelte/easing'
  import { createEventDispatcher } from 'svelte'
  import Icon from '../components/Icon.svelte'
  import closeIcon from '../assets/icon/cil-x-circle.svg'
  import { shortBtcFormat, longBtcFormat, timeFormat, numberFormat } from '../utils/format.js'
  import { exchangeRates, settings } from '../stores.js'
  import { formatCurrency } from '../utils/fx.js'

	const dispatch = createEventDispatcher()

  let prevBlockId
  let blockId
  export let block
  export let visible
  const newBlockDelay = 2000
  let restoring = false
  let formattedBlockValue = ''

  $: {
    if (block && block.value) {
      const rate = $exchangeRates[$settings.currency]
      let local
      if (rate && rate.last) {
        local = formatCurrency($settings.currency, (block.value/100000000) * rate.last, { compact: true })
      } else {
        local = null
      }
      formattedBlockValue = `${formatBTC(block.value)}${local != null ? (' ≈ ' + local) : ''}`
    }
  }

  $: {
    if (block && visible) {
      prevBlockId = blockId
      blockId = block.id
    }
  }

  $: {
    if (visible && block && block.id === prevBlockId) {
      restoring = true
    } else {
      restoring = false
    }
  }

  function formatTime (time) {
    return timeFormat.format(time)
  }

  function formatBTC (sats) {
    return `₿ ${shortBtcFormat.format(sats/100000000)}`
  }

  function formatBytes (bytes) {
    if (bytes) {
      return `${numberFormat.format(bytes)} bytes`
    } else return `unknown size`
  }

  function formatCount (n) {
    if (n) {
      return numberFormat.format(n)
    } else return '0'
  }

  function formatFee (n) {
    if (n) {
      return numberFormat.format(n.toFixed(2))
    } else return  '0'
  }

  function hideBlock () {
    analytics.trackEvent('viz', 'block', 'hide')
    dispatch('hideBlock')
  }
</script>

<style type="text/scss">
  .close-button {
    width: 1em;
    height: 1em;
    background: none;
    border: none;
    display: flex;
    justify-content: center;
    align-items: center;
    margin: 0;
    padding: 0;
    cursor: pointer;
    pointer-events: all;
    font-size: 1.2em;

    &.standalone {
      display: none;
    }
  }

  .block-info {
    position: absolute;
    bottom: calc(100% + 0.25rem);
    left: 50%;
    min-width: 100%;
    transform: translateX(-50%);
    pointer-events: all;

    color: var(--palette-x);
    font-size: 1rem;

    @media (max-width: 360px) {
      font-size: 4.4vw;
    }

    .compact {
      display: none;
    }

    @media (max-aspect-ratio: 1/1) and (max-height: 760px) {
      .compact {
        display: block;
      }
      .full-size {
        display: none;
      }
    }
    @media (aspect-ratio: 1/1) and (max-height: 760px) {
      .compact {
        display: none;
      }
      .full-size {
        display: block;
      }
    }

    .data-row {
      display: flex;
      flex-direction: row;
      flex-wrap: nowrap;
      justify-content: space-between;

      &.spacer {
        display: none;
      }
    }

    .data-field {
      white-space: nowrap;

      &.close-button {
        width: 1em;
        height: 1em;
        background: none;
        border: none;
        display: flex;
        justify-content: center;
        align-items: center;
        margin: 0;
        padding: 0;
        cursor: pointer;
        margin-top: -5px;
      }

       &:first-child {
         margin-right: 5px;
       }
       &:last-child {
         margin-left: 5px;
       }
    }
  }

  @media (min-aspect-ratio: 1/1) {
    .block-info {
      bottom: unset;
      left: unset;
      top: 0;
      right: 100%;
      padding-right: .5rem;

      min-width: 0;
      transform: translateX(0);

      .data-row {
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        align-items: flex-end;

        &.spacer {
          display: flex;
        }
      }

      .data-field {
        white-space: wrap;
        margin-left: 0;
        margin-right: 5px;

        &.title-field {
          margin-bottom: .5em;
        }

        &.close-button {
          display: none;
        }
      }
    }

    .standalone.close-button {
      display: block;
      position: absolute;
      bottom: 100%;
      left: 100%;
      margin: 5px;
    }
  }

  @media (min-aspect-ratio: 1/1) and (max-height: 400px) {
    .standalone.close-button {
      top: 0;
      bottom: unset;
      margin-top: 0;
    }
  }
</style>

{#each [block] as block (block)}
  {#if block != null && visible }
    <div class="block-info" out:fly="{{ y: -50, duration: 2000, easing: linear }}" in:fly="{{ y: (restoring ? -50 : 50), duration: (restoring ? 500 : 1000), easing: linear, delay: (restoring ? 0 : newBlockDelay) }}">
        <!-- <span class="data-field">Hash: { block.id }</span> -->
        <div class="full-size">
          <div class="data-row">
            <span class="data-field title-field" title="{block.miner_sig}"><b>Latest Block: </b>{ numberFormat.format(block.height) }</span>
            <button class="data-field close-button" on:click={hideBlock}><Icon icon={closeIcon} color="var(--palette-x)" /></button>
          </div>
          <div class="data-row">
            <span class="data-field">Mined { formatTime(block.time) }</span>
            <span class="data-field">{ formattedBlockValue }</span>
          </div>
          <div class="data-row">
            <span class="data-field">{ formatBytes(block.bytes) }</span>
            <span class="data-field">{ formatCount(block.txnCount) } transactions</span>
          </div>
          <div class="data-row spacer">&nbsp;</div>
          <div class="data-row">
            <span class="data-field">Avg Fee Rate</span>
            {#if block.fees != null}
              <span class="data-field">{ formatFee(block.avgFeerate) } sats/vbyte</span>
            {:else}
              <span class="data-field">unavailable</span>
            {/if}
          </div>
        </div>
        <div class="compact">
          <div class="data-row">
            <span class="data-field title-field" title="{block.miner_sig}"><b>Latest Block: </b>{ numberFormat.format(block.height) }</span>
            <button class="data-field close-button" on:click={hideBlock}><Icon icon={closeIcon} color="var(--palette-x)" /></button>
          </div>
          <div class="data-row">
            <span class="data-field">Mined { formatTime(block.time) }</span>
            <span class="data-field">{ formattedBlockValue }</span>
          </div>
          <div class="data-row">
            <span class="data-field">{ formatCount(block.txnCount) } transactions</span>
            {#if block.fees != null}
              <span class="data-field">{ formatFee(block.avgFeerate) } sats/vb</span>
            {:else}
              <span class="data-field">{ formatBytes(block.bytes) }</span>
            {/if}
          </div>
        </div>
    </div>
    <button class="close-button standalone" on:click={hideBlock} out:fly="{{ y: -50, duration: 2000, easing: linear }}" in:fly="{{ y: (restoring ? -50 : 50), duration: (restoring ? 500 : 1000), easing: linear, delay: (restoring ? 0 : newBlockDelay) }}" >
      <Icon icon={closeIcon} color="var(--palette-x)" />
    </button>
  {/if}
{/each}
