<script>
import analytics from '../utils/analytics.js'
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { settings, nativeAntialias } from '../stores.js'

function toggle(setting) {
  $settings[setting] = !$settings[setting]
  analytics.trackEvent('settings', setting, $settings[setting] ? 'on' : 'off')
}

let settingConfig = {
  showNetworkStatus: {
    label: 'Show Network Status'
  },
  darkMode: {
    label: 'Dark Mode'
  },
  showFPS: {
    label: 'Show FPS'
  },
  showDonation: {
    label: 'Show Donation Info'
  }
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

function getSettingLabel(setting) {
  if (settingConfig[setting]) return settingConfig[setting].label
}

</script>

{#each Object.keys($settings) as setting (setting) }
  {#if settingConfig[setting]}
    <SidebarMenuItem active={$settings[setting]} on:click={() => { toggle(setting) }} label={getSettingLabel(setting)} />
  {/if}
{/each}
