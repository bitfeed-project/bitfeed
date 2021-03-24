<script>
import Icon from '../components/Icon.svelte'
import config from '../config.js'
import coffeeIcon from '../assets/icon/cib-buy-me-a-coffee.svg'
import clipboardIcon from '../assets/icon/cil-clipboard.svg'

</script>

<style type="text/scss">
  .donation-bar {
    .main-bar {
      display: flex;
      flex-direction: row;
      justify-content: center;
      align-items: center;
      padding: 5px 5px;
      flex-shrink: 1;

      background: var(--bold-a);
      color: var(--palette-x);

      border-bottom-left-radius: 5px;
      border-bottom-right-radius: 5px;

      .coffee-icon {
        font-size: 2rem;
      }

      .copy-button {
        background: none;
        border: none;
        padding: 0;
        margin: 0;
        margin-left: 5px;
        font-size: 1.5rem;
        cursor: pointer;
      }
    }
  }
</style>

<div class="donation-bar">
  <div class="main-bar">
    <span class="coffee-icon">
      <Icon icon={coffeeIcon} color="var(--palette-x)"/>
    </span>
    <span>{ config.donationAddress }</span>
    <button class="copy-button">
      <Icon icon={clipboardIcon} color="var(--palette-x)" />
    </button>
  </div>
</div>
