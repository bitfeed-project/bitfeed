<script>
import config from '../config.js'

import SidebarTab from '../components/SidebarTab.svelte'
import Icon from '../components/Icon.svelte'

import Settings from '../components/Settings.svelte'
import cogIcon from '../assets/icon/cil-cog.svg'
import DevTools from '../components/DevTools.svelte'
import codeIcon from '../assets/icon/cil-code.svg'

import { sidebarToggle } from '../stores.js'

function settings (tab) {
  if ($sidebarToggle === tab) sidebarToggle.set(null)
  else sidebarToggle.set(tab)
}

</script>

<style type="text/scss">
  .sidebar {
    position: fixed;
    top: 120px;
    left: 100%;
  }
</style>

<div class="sidebar">
  <SidebarTab open={$sidebarToggle === 'settings'} on:click={() => {settings('settings')}}>
    <span slot="tab" title="Settings">
      <Icon icon={cogIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <Settings />
    </div>
  </SidebarTab>
  {#if config.dev && config.debug}
    <SidebarTab open={$sidebarToggle === 'dev'} on:click={() => {settings('dev')}}>
      <span slot="tab">
        <Icon icon={codeIcon} color="var(--bold-a)" />
      </span>
      <div slot="content">
        <DevTools />
      </div>
    </SidebarTab>
  {/if}
</div>
