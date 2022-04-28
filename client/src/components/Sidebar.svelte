<script>
import config from '../config.js'
import analytics from '../utils/analytics.js'

import SidebarTab from '../components/SidebarTab.svelte'
import Icon from '../components/Icon.svelte'

import Settings from '../components/Settings.svelte'
import cogIcon from '../assets/icon/cil-cog.svg'
import DevTools from '../components/DevTools.svelte'
import codeIcon from '../assets/icon/cil-code.svg'
import questionIcon from '../assets/icon/help-circle.svg'
import infoIcon from '../assets/icon/info.svg'
import atIcon from '../assets/icon/cil-at.svg'
import gridIcon from '../assets/icon/grid-icon.svg'
import peopleIcon from '../assets/icon/cil-people.svg'
import giftIcon from '../assets/icon/cil-gift.svg'
import bookmarkIcon from '../assets/icon/cil-bookmark.svg'
import MempoolLegend from '../components/MempoolLegend.svelte'
import ContactTab from '../components/ContactTab.svelte'
import SearchTab from '../components/SearchTab.svelte'

import { sidebarToggle, overlay, currentBlock, blockVisible, haveSupporters } from '../stores.js'

let searchTabComponent

let blockHidden = false
$: blockHidden = ($currentBlock && !$blockVisible)

function settings (tab) {
  if ($sidebarToggle) analytics.trackEvent('sidebar', $sidebarToggle, 'close')
  if ($sidebarToggle === tab) {
    sidebarToggle.set(null)
  } else {
    analytics.trackEvent('sidebar', tab, 'open')
    sidebarToggle.set(tab)
  }
}

function openOverlay (key) {
  $overlay = key
}

function showBlock () {
  analytics.trackEvent('viz', 'block', 'show')
  $blockVisible = true
}
</script>

<style type="text/scss">
  .sidebar {
    position: fixed;
    top: 20%;
    left: 100%;
    display: flex;
    flex-direction: column-reverse;
    justify-content: flex-start;
    align-items: flex-start;

    @media (max-width: 480px) and (max-height: 480px) {
      display: none;
    }
  }
</style>

<div class="sidebar">
  <!-- displayed in reverse order, to preserve proper z-index layering -->
  {#if blockHidden }
    <SidebarTab  on:click={() => showBlock()} tooltip="Show Latest Block">
      <span slot="tab">
        <Icon icon={gridIcon} color="var(--bold-a)" />
      </span>
      <div slot="content">
        <MempoolLegend />
      </div>
    </SidebarTab>
  {/if}
  {#if config.dev && config.debug}
    <SidebarTab open={$sidebarToggle === 'dev'} on:click={() => {settings('dev')}} tooltip="Debug">
      <span slot="tab">
        <Icon icon={codeIcon} color="var(--bold-a)" />
      </span>
      <div slot="content">
        <DevTools />
      </div>
    </SidebarTab>
  {/if}
  {#if config.donationsEnabled }
    <SidebarTab on:click={() => openOverlay('donation')} tooltip="Donate">
      <span slot="tab">
        <Icon icon={giftIcon} color="var(--bold-a)" />
      </span>
    </SidebarTab>
  {/if}
  {#if $haveSupporters }
    <SidebarTab on:click={() => openOverlay('supporters')} tooltip="Supporters">
      <span slot="tab">
        <Icon icon={peopleIcon} color="var(--bold-a)" />
      </span>
    </SidebarTab>
  {/if}
  <SidebarTab on:click={() => openOverlay('about')} tooltip="About">
    <span slot="tab">
      <Icon icon={questionIcon} color="var(--bold-a)" />
    </span>
  </SidebarTab>
  <SidebarTab open={$sidebarToggle === 'contact'} on:click={() => {settings('contact')}} tooltip="Contact">
    <span slot="tab">
      <Icon icon={atIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <ContactTab />
    </div>
  </SidebarTab>
  <SidebarTab open={$sidebarToggle === 'legend'} on:click={() => {settings('legend')}} tooltip="Key">
    <span slot="tab">
      <Icon icon={infoIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <MempoolLegend />
    </div>
  </SidebarTab>
  <SidebarTab open={$sidebarToggle === 'search'} on:click={() => {settings('search')}} tooltip="Search & Highlight" bind:this={searchTabComponent}>
    <span slot="tab" title="Search & Highlight">
      <Icon icon={bookmarkIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <SearchTab tab={searchTabComponent} />
    </div>
  </SidebarTab>
  <SidebarTab open={$sidebarToggle === 'settings'} on:click={() => {settings('settings')}} tooltip="Settings">
    <span slot="tab" title="Settings">
      <Icon icon={cogIcon} color="var(--bold-a)" />
    </span>
    <div slot="content">
      <Settings />
    </div>
  </SidebarTab>
</div>
