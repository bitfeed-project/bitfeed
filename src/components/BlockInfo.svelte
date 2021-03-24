<script>
  import { fly } from 'svelte/transition'
  import { linear } from 'svelte/easing'
  import { createEventDispatcher } from 'svelte'

	const dispatch = createEventDispatcher()

  export let block
  export let visible

  function formatTime (time) {
    return (new Date(time)).toLocaleTimeString()
  }

  function formatBTC (sats) {
    return `${(sats/100000000).toPrecision(8)} BTC`
  }

  function formatBytes (bytes) {
    if (bytes) {
      return `${bytes.toLocaleString()} bytes`
    } else return `unknown size`
  }

  function hideBlock () {
    console.log('hide!')
    dispatch('hideBlock')
  }
</script>

<style type="text/scss">
  .block-info {
    position: absolute;
    bottom: 100%;
    left: 50%;
    transform: translateX(-50%);

    color: var(--palette-x);
    font-size: 14pt;

    pointer-events: all;

    .data-row {
      display: flex;
      flex-direction: row;
      flex-wrap: nowrap;
      justify-content: space-between;
    }

    .data-field {
      white-space: nowrap;

      &.close-button {
        width: 1em;
        height: 1em;
        background: var(--palette-x);
        display: flex;
        justify-content: center;
        align-items: center;
        margin: 0;
        padding: 0;
        cursor: pointer;

        .close-x {
          color: var(--palette-a);
          padding: 0;
          margin: 0;
        }
      }

       &:first-child {
         margin-right: 5px;
       }
       &:last-child {
         margin-left: 5px;
       }
    }
  }
</style>

{#each [block] as block (block)}
  {#if block != null && visible }
    <div class="block-info" out:fly="{{ y: -50, duration: 2000, easing: linear }}" in:fly="{{ y: 50, duration: 1000, easing: linear, delay: 2000 }}">
        <!-- <span class="data-field">Hash: { block.id }</span> -->
        <div class="data-row">
          <span class="data-field"><b>Block</b></span>
          <button class="data-field close-button" on:click={hideBlock}><span class="close-x">X</span></button>
        </div>
        <div class="data-row">
          <span class="data-field">Mined at { formatTime(block.time) }</span>
          <span class="data-field">{ formatBTC(block.value) }</span>
        </div>
        <div class="data-row">
          <span class="data-field">{ formatBytes(block.bytes) }</span>
          <span class="data-field">{ block.txnCount } transactions</span>
        </div>
    </div>
  {/if}
{/each}
