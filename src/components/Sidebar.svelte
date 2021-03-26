<script>
import config from '../config.js'

import SidebarTab from '../components/SidebarTab.svelte'
import Icon from '../components/Icon.svelte'

import Settings from '../components/Settings.svelte'
import cogIcon from '../assets/icon/cil-cog.svg'
import DevTools from '../components/DevTools.svelte'
import codeIcon from '../assets/icon/cil-code.svg'
import questionIcon from '../assets/icon/help-circle.svg'
import infoIcon from '../assets/icon/info.svg'
import MempoolLegend from '../components/MempoolLegend.svelte'

import { sidebarToggle } from '../stores.js'

function settings (tab) {
  if ($sidebarToggle === tab) sidebarToggle.set(null)
  else sidebarToggle.set(tab)
}

</script>

<style type="text/scss">
  .sidebar {
    position: fixed;
    top: 20%;
    left: 100%;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: flex-start;
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
  <SidebarTab open={$sidebarToggle === 'legend'} on:click={() => {settings('legend')}}>
    <span slot="tab">
      <Icon icon={infoIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <MempoolLegend />
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
