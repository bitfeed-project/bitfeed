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

<style type="text/scss">
  .setting {
    text-align: right;
    padding: 5px 10px;
    color: var(--palette-x);
    font-size: 0.8em;
    cursor: pointer;
    min-width: 80px;

    &:hover {
      font-weight: bold;
    }

    &.toggled-on {
      background: var(--bold-b);
      color: var(--dark-a);
    }

    &:last-child {
      border-bottom: none;
    }
  }
</style>

{#each Object.keys($settings) as setting (setting) }
  <SidebarMenuItem active={$settings[setting]} on:click={() => { toggle(setting) }} label={getSettingLabel(setting)} />
{/each}
