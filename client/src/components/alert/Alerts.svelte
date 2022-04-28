<script>
import { onMount } from 'svelte'
import { alerts, heroes, sponsors, overlay, sidebarToggle, haveSupporters } from '../../stores.js'
import config from '../../config.js'
import ByMononaut from './ByMononaut.svelte'
import HeroMsg from './Hero.svelte'
import SponsoredMsg from './Sponsored.svelte'
import GenericAlert from './GenericAlert.svelte'
import GenericAlertv2 from './GenericAlertv2.svelte'
import { fly } from 'svelte/transition'

const components = {
  mononaut: ByMononaut,
  "sponsored-by": SponsoredMsg,
  // "be-a-hero": BeAHero,
  "thank-you-hero": HeroMsg,
  msg: GenericAlert,
  msg2: GenericAlertv2,
}
let ready
$: {
  ready = {
    mononaut: true,
    "sponsored-by": true,
    "thank-you-hero": $haveSupporters ? HeroMsg : null,
    msg: true,
    msg2: true,
  }
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
  if ($alerts && ready) {
    processedAlerts = $alerts.map(processAlert).filter(alert => alert != null)
    startAlerts()
  }
}

function processAlert (alert) {
  if (alert && alert.type && components[alert.type] && ready[alert.type] && (!alert.publicOnly || config.public)) {
    if (!sequences[alert.key]) sequences[alert.key] = 0
    return {
      ...alert,
      component: components[alert.type],
      action: actions[alert.action] || null
    }
  } else return null
}

let alert
let lastIndex = -1

onMount(() => {
   startAlerts()
})

function startAlerts () {
  if (!rotating && processedAlerts && processedAlerts.length) {
    rotating = true
    alert = processedAlerts[0] || { key: 'null1' }
    lastIndex = 0
    if (rotateTimer) clearTimeout(rotateTimer)
    rotateTimer = setTimeout(rotateAlerts, config.alertDuration)
  }
}

let rotateTimer
function rotateAlerts () {
  if (rotateTimer) clearTimeout(rotateTimer)

  if (processedAlerts && processedAlerts.length > 1) {
    // find the next alert in the queue
    let currentIndex = (lastIndex + 1) % processedAlerts.length

    lastIndex = currentIndex
    alert = processedAlerts[currentIndex]
  }

  rotateTimer = setTimeout(rotateAlerts, config.alertDuration)
}
</script>

<div class="alert-bar">
  {#key alert && alert.key}
    <div class="alert-wrapper" in:fly={{ y: -100, delay: 400 }} out:fly={{ x: 400}}>
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
  {/key}
</div>

<style type="text/scss">
.alert-bar {
  position: relative;
  width: 100%;
  height: 3.5em;

  .alert-wrapper {
    position: absolute;
    top: 0;
    bottom: 0;
    right: 0;
    width: 20em;
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
  }

  @media screen and (max-width: 480px) {
    height: 3em;
    width: 18em;
    .alert-wrapper {
      width: 18em;
    }
  }
}
</style>
