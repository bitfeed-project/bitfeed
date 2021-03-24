<script>
import { settings, settingsOpen } from '../stores.js'

function toggle(setting) {
  $settings[setting] = !$settings[setting]
}

function toggleSettingsMenu () {
  $settingsOpen = !$settingsOpen
}

const settingConfig = {
  showFPS: {
    label: 'Show FPS?'
  },
  darkMode: {
    label: 'Dark mode?'
  }
}

function getSettingLabel(setting) {
  if (settingConfig[setting]) return settingConfig[setting].label
}

</script>

<style type="text/scss">
  .settings-menu {
    display: block;
    position: fixed;
    top: 100px;
    left: 100%;

    background: none;
    border: solid 1px var(--palette-x);
    border-right: none;
    border-bottom-left-radius: 5px;
    color: var(--palette-x);

    transition: transform 300ms;

    &.open {
      transform: translateX(-100%);
    }

    .settings-button {
      display: block;
      position: absolute;
      top: -1px;
      right: 100%;
      width: 2em;
      height: 2em;

      background: none;
      border: solid 1px var(--palette-x);
      border-right: none;
      border-top-left-radius: 5px;
      border-bottom-left-radius: 5px;
      color: var(--palette-x);

      overflow: hidden;

      cursor: pointer;
    }

    .setting {
      text-align: right;
      padding: 5px 10px;
      border-bottom: solid 1px var(--palette-x);
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
  }
</style>

<div class="settings-menu" class:open={$settingsOpen}>
  <button class="settings-button" on:click={toggleSettingsMenu}>!!</button>

  {#each Object.keys($settings) as setting (setting) }
  <div class="setting setting-toggle" class:toggled-on={$settings[setting]} on:click={() => { toggle(setting) }}>
    { getSettingLabel(setting) }
  </div>
  {/each}
</div>
