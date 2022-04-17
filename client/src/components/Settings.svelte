<script>
import config from '../config.js'
import analytics from '../utils/analytics.js'
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { settings, nativeAntialias, exchangeRates, haveMessages } from '../stores.js'
import { currencies } from '../utils/fx.js'

function toggle(setting) {
  if (settingConfig[setting] != null && settingConfig[setting].valueType === 'bool') {
    onChange(setting, !$settings[setting])
  }
}

function onChange(setting, value) {
  $settings[setting] = value
  analytics.trackEvent('settings', setting, $settings[setting])
}

const currencyOptions = Object.keys(currencies).map(code => {
  return {
    value: code,
    label: `${currencies[code].char} ${currencies[code].name}`,
    tags: [code, currencies[code].name, ...currencies[code].countries]
  }
})

let settingConfig = {
  showNetworkStatus: {
    label: 'Network Status',
    valueType: 'bool'
  },
  darkMode: {
    label: 'Dark Mode',
    valueType: 'bool'
  },
  currency: {
    label: 'Fiat Currency',
    type: 'dropdown',
    valueType: 'string',
    options: currencyOptions
  },
  vbytes: {
    label: 'Size by',
    type: 'pill',
    falseLabel: 'value',
    trueLabel: 'vbytes',
    valueType: 'bool'
  },
  colorByFee: {
    label: 'Color by',
    type: 'pill',
    falseLabel: 'age',
    trueLabel: 'fee rate',
    valueType: 'bool'
  },
  showSearch: {
    label: 'Search Bar',
    valueType: 'bool'
  }
}
$: {
  if ($nativeAntialias) {
    settingConfig.fancyGraphics = false
  } else {
    settingConfig.fancyGraphics = {
      label: 'Fancy Graphics',
      valueType: 'bool'
    }
  }
  if (config.messagesEnabled && $haveMessages) {
    settingConfig.showMessages = {
      label: 'Message Bar',
      valueType: 'bool'
    }
  }
}

$: {
  const rate = $exchangeRates[$settings.currency]
  if (rate && rate.last) {
    settingConfig.showFX = {
      label: '₿ Price',
      valueType: 'bool'
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
    <SidebarMenuItem {...getSettings(setting)} value={$settings[setting]} on:click={() => { toggle(setting) }} on:input={(e) => { onChange(setting, e.detail)}} />
  {/if}
{/each}
