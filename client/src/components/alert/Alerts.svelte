<script>
import { onMount } from 'svelte'
import { alerts, heroes, sponsors, overlay, sidebarToggle } from '../../stores.js'
import config from '../../config.js'
import ByMononaut from './ByMononaut.svelte'
import HeroMsg from './Hero.svelte'
import SponsoredMsg from './Sponsored.svelte'
import GenericAlert from './GenericAlert.svelte'
import { fly } from 'svelte/transition'

const components = {
  mononaut: ByMononaut,
  "sponsored-by": SponsoredMsg,
  // "be-a-hero": BeAHero,
  "thank-you-hero": HeroMsg,
  msg: GenericAlert
}

const actions = {
  support: () => {
    $overlay = 'donation'
  },
  supporters: () => {
    $overlay = 'supporters'
  },
  contact: () => {
    $sidebarToggle = 'contact'
  }
}

const sequences = {}
let rotating = false

let processedAlerts = []
$: {
  if ($alerts) {
    processedAlerts = $alerts.map(processAlert).filter(alert => alert != null)
    startAlerts()
  }
}

function processAlert (alert) {
  if (alert && alert.type && components[alert.type]) {
    if (!sequences[alert.key]) sequences[alert.key] = 0
    return {
      ...alert,
      component: components[alert.type],
      action: actions[alert.action] || null
    }
  } else return null
}

let activeAlerts = [{ key: 'null1' }, { key: 'null2' }]
let lastIndex = -1

onMount(() => {
   startAlerts()
})

function startAlerts () {
  if (!rotating && processedAlerts && processedAlerts.length) {
    rotating = true
    activeAlerts[0] = processedAlerts[0] || { key: 'null1' }
    activeAlerts[1] = processedAlerts[1] || { key: 'null2' }
    lastIndex = processedAlerts[1] ? 1 : 0
    if (rotateTimer) clearTimeout(rotateTimer)
    rotateTimer = setTimeout(rotateAlerts, config.alertDuration)
  }
}

let rotateTimer
function rotateAlerts () {
  if (rotateTimer) clearTimeout(rotateTimer)

  if (processedAlerts && processedAlerts.length > 2) {
    // find the next alert in the queue
    let currentIndex = -1
    if (activeAlerts[1]) {
      currentIndex = processedAlerts.findIndex(alert => { alert.key === activeAlerts[1].key})
    }
    if (currentIndex < 0) currentIndex = lastIndex
    currentIndex = (currentIndex + 1) % processedAlerts.length
    // roll over to the next alert if there's a key clash
    if (processedAlerts[currentIndex].key === activeAlerts[1].key) {
      currentIndex = (currentIndex + 1) % processedAlerts.length
    }

    lastIndex = currentIndex
    let nextAlert = processedAlerts[currentIndex]
    if (nextAlert)
    activeAlerts[0] = activeAlerts[1]
    activeAlerts[1] = { key: 'temp' }
    setTimeout(() => {
      activeAlerts[1] = nextAlert
      sequences[alert.key]++
    }, 1000)
  } else if (processedAlerts) {
    activeAlerts[0] = processedAlerts[0] || { key: 'null1' }
    activeAlerts[1] = processedAlerts[1] || { key: 'null2' }
  }

  rotateTimer = setTimeout(rotateAlerts, config.alertDuration)
}
</script>

<div class="alert-bar" transition:fly={{ y: -100 }}>
  {#each activeAlerts as alert (alert.key)}
    <div class="alert-wrapper" in:fly|local={{ y: -100 }} out:fly|local={{ x: 400}}>
      {#if alert && alert.component }
        {#if alert.href}
          <a class="alert link" target="_blank" rel="noopener" href={alert.href}>
            <svelte:component this={alert.component} {...alert} sequence={sequences[alert.key]} />
          </a>
        {:else if alert.action}
          <div class="alert action" on:click={alert.action}>
            <svelte:component this={alert.component} {...alert} sequence={sequences[alert.key]} />
          </div>
        {:else}
          <div class="alert">
            <svelte:component this={alert.component} {...alert} sequence={sequences[alert.key]} />
          </div>
        {/if}
      {/if}
    </div>
  {/each}
</div>

<style type="text/scss">
.alert-bar {
  position: relative;
  width: 100%;
  flex-grow: 1;
  flex-shrink: 1;
  height: 3.5em;

  .alert-wrapper {
    position: absolute;
    top: 0;
    bottom: 0;
    right: 0;
    width: 20em;
    transform: translateX(-110%);
    transition: transform 500ms ease-in-out;

    .alert {
      position: absolute;
      top: 0;
      bottom: 0;
      right: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border-bottom-left-radius: 10px;
      border-bottom-right-radius: 10px;
      overflow: hidden;
      cursor: pointer;
      background: var(--palette-c);
      transition: background 200ms;

      &:hover {
        background: var(--palette-d);
      }

      :global(.alert-content) {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        padding: .5em 1em;
        color: var(--palette-x);
      }
    }

    &:first-child {
      transform: translateX(0%);
    }
  }

  @media screen and (max-width: 850px) {
    .alert-wrapper {
      transform: translateX(0);

      &:first-child {
        transform: translateX(110%);
      }
    }
  }

  @media screen and (max-width: 480px) {
    height: 3em;

    .alert-wrapper {
      font-size: 0.8em;
      width: 16em;
    }
  }
}
</style>
