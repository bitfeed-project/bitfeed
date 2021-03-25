<script>
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { devEvents, devSettings } from '../stores.js'
// import { devSettings } from '../stores.js'
//
// function toggle(setting) {
//   $devSettings[setting] = !$devSettings[setting]
// }
//
// const settingConfig = {
//   setting: {
//     label: 'label'
//   },
// }

// function getSettingLabel(setting) {
//   if (settingConfig[setting]) return settingConfig[setting].label
// }

function addOne () {
  if ($devEvents.addOneCallback) $devEvents.addOneCallback()
}
function addMany () {
  if ($devEvents.addOneCallback) $devEvents.addManyCallback()
}
function addBlock () {
  if ($devEvents.addOneCallback) $devEvents.addBlockCallback()
}

function toggle (setting) {
  console.log(setting, $devSettings[setting])
  $devSettings[setting] = !$devSettings[setting]
  console.log($devSettings[setting])
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

<!-- {#each Object.keys($devSettings) as setting (setting) }
  <div class="setting setting-toggle" class:toggled-on={$devSettings[setting]} on:click={() => { toggle(setting) }}>
    { getSettingLabel(setting) }
  </div>
{/each} -->
<SidebarMenuItem on:click={addOne} label="Add One" />
<SidebarMenuItem on:click={addMany} label="Add Many" />
<SidebarMenuItem on:click={addBlock} label="Add Block" />
<SidebarMenuItem on:click={() => { toggle('guides')}} active={$devSettings.guides} label="Guides" />
