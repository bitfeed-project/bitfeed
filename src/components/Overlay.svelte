<script>
import analytics from '../utils/analytics.js'
import Icon from '../components/Icon.svelte'
import closeIcon from '../assets/icon/cil-x-circle.svg'
import { overlay } from '../stores.js'
import { createEventDispatcher } from 'svelte'
import { fade, fly } from 'svelte/transition'
const dispatch = createEventDispatcher()

export let name = 'none'

let open
$: {
  const oldOpen = open
  open = $overlay === name
  if (oldOpen !== undefined && open != oldOpen) {
    analytics.trackEvent('overlay', name, open ? 'open' : 'close')
  }
}

function close () {
  $overlay = null
  dispatch('close')
}
</script>

<style type="text/scss">
  .overlay-wrapper {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 200;

    display: flex;
    justify-content: center;
    align-items: center;

    .overlay-background {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      z-index: -1;

      background: var(--dark-a);
      opacity: 50%;
    }

    .overlay-outer {
      position: relative;
      padding: 1em;
      border-radius: 10px;
      background: var(--palette-c);
      color: var(--palette-x);
      max-width: 80%;
      max-height: 80%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;

      @media (min-width: 1200px) {
        max-width: 960px;
      }

      .close-button {
        position: absolute;
        bottom: 100%;
        left: 100%;
        font-size: 1.2rem;
        display: block;
        background: none;
        border: none;
        padding: 0;
        margin: -0.2em;
        cursor: pointer;

        background: var(--palette-c);
        border-radius: 50%;
      }

      .overlay-inner {
        overflow: auto;
        padding-right: 1em;
      }
    }
  }
</style>

{#if open}
<div class="overlay-wrapper">
  <div class="overlay-background" on:click={close} transition:fade={{ duration: 500 }} />
  <div class="overlay-outer" transition:fly={{ duration: 500, y: 50 }}>
    <div class="overlay-inner">
      <slot />
    </div>
    <button class="close-button" on:click={close} >
      <Icon icon={closeIcon} color="var(--palette-x)" />
    </button>
  </div>
</div>
{/if}
