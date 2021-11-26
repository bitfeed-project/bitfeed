<script>
import analytics from '../utils/analytics.js'
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { settings, nativeAntialias, exchangeRates, localCurrency } from '../stores.js'

function toggle(setting) {
  $settings[setting] = !$settings[setting]
  analytics.trackEvent('settings', setting, $settings[setting] ? 'on' : 'off')
}

let settingConfig = {
  showNetworkStatus: {
    label: 'Network Status'
  },
  darkMode: {
    label: 'Dark Mode'
  },
  showFPS: {
    label: 'FPS'
  },
  showDonation: {
    label: 'Donation Info'
  },
  vbytes: {
    label: 'Tx Size',
    type: 'pill',
    falseLabel: 'value',
    trueLabel: 'vbytes'
  },
}
$: {
  if ($nativeAntialias) {
    settingConfig.fancyGraphics = false
  } else {
    settingConfig.fancyGraphics = {
      label: 'Fancy Graphics'
    }
  }
}

$: {
  const rate = $exchangeRates[$localCurrency]
  if (rate && rate.last) {
    settingConfig.showFX = {
      label: '₿ Price'
    }
  } else {
    settingConfig.showFX = false
  }
}


function getSettings(setting) {
  return settingConfig[setting] || {}
}

</script>

{#each Object.keys($settings) as setting (setting) }
  {#if settingConfig[setting]}
    <SidebarMenuItem {...getSettings(setting)} active={$settings[setting]} on:click={() => { toggle(setting) }} />
  {/if}
{/each}
