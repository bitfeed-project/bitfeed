<script>
import Icon from '../components/Icon.svelte'
import twitterIcon from '../assets/icon/cib-twitter.svg'
import atIcon from '../assets/icon/cil-at.svg'
import Mononaut from '../components/Mononaut.svelte'

</script>

<style type="text/scss">
  .contact {
    text-align: center;
    width: 24em;
    max-width: calc(100vw - 50px);

    .mononaut {
      font-family: monospace;
      font-size: 1.2em;
    }

    .avatar-and-intro {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: center;

      .intro {
        flex-shrink: 2;
      }
    }

    .monkey-avatar {
      float: left;
      width: 10em;
      margin: 0 10px 10px;
      flex-shrink: 1;
      flex-grow: 1;
    }

    .social-link {
      box-sizing: border-box;
      display: inline-flex;
      flex-direction: row;
      align-items: center;
      justify-content: flex-start;
      height: 2.0em;
      font-size: 1.2em;
      font-weight: bold;
      padding: .3em;
      border-radius: 1.0em;
      background: var(--bold-a);
      font-family: monospace;
      color: white;

      .social-icon {
        width: 1.5em;
        height: 1.5em;
        font-size: 0.8em;
        padding: 0.1em;
        border-radius: 50%;
        display: flex;
        justify-content: center;
        align-items: center;
        background: white;
        margin-right: .5em;
      }

      .handle {
        margin-right: .5em;
      }

      &.twitter {
        background: var(--twitter-blue);
      }
      &.email {
        background: var(--monospace-purple);
      }
    }
  }
</style>

<div class="contact tab-content">
  <div class="avatar-and-intro">
    <a class="monkey-avatar" target="_blank" href="https://monospace.live">
      <Mononaut />
    </a>
    <div class="intro">
      <p>Bitfeed is an experiment by <b class="mononaut">mononaut</b>.</p>
      <p>Questions? Comments? Suggestions? Job offers?</p>
    </div>
  </div>
  <p style="clear: both">Message me on twitter at
    <a class="social-link twitter" target="_blank" href="https://twitter.com/mononautical">
      <span class="social-icon">
        <Icon icon={twitterIcon} color="var(--twitter-blue)" />
      </span>
      <span class="handle">@mononautical</span>
    </a>
  </p>
  <p>Or email any recipient at
  <a class="social-link email" target="_blank" href="mailto:bitfeed@monospace.live">
    <span class="social-icon">
      <Icon icon={atIcon} color="var(--monospace-purple)" />
    </span>
    <span class="handle">monospace.live</span>
  </a>
  </p>
</div>
