<script>
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { settings } from '../stores.js'

function toggle(setting) {
  $settings[setting] = !$settings[setting]
}

const settingConfig = {
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

function getSettingLabel(setting) {
  if (settingConfig[setting]) return settingConfig[setting].label
}

</script>

{#each Object.keys($settings) as setting (setting) }
  <SidebarMenuItem active={$settings[setting]} on:click={() => { toggle(setting) }} label={getSettingLabel(setting)} />
{/each}
