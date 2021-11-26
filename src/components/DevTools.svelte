<script>
import SidebarMenuItem from '../components/SidebarMenuItem.svelte'
import { devEvents, devSettings } from '../stores.js'
import config from '../config.js'

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
  $devSettings[setting] = !$devSettings[setting]
}

</script>

<SidebarMenuItem on:click={addOne} label="Add One" />
<SidebarMenuItem on:click={addMany} label="Add Many" />
<SidebarMenuItem on:click={addBlock} label="Add Block" />
<SidebarMenuItem on:click={() => { toggle('guides')}} active={$devSettings.guides} label="Guides" />
{#if config.layoutHints}
  <SidebarMenuItem on:click={() => { toggle('layoutHints')}} active={$devSettings.layoutHints} label="Debug Layout" />
{/if}
