<script>
import SocialLink from '../components/SocialLink.svelte'
import twitterIcon from '../assets/icon/cib-twitter.svg'
import atIcon from '../assets/icon/cil-at.svg'
import Mononaut from '../components/Mononaut.svelte'
import config from '../../package.json'
</script>

<style type="text/scss">
  .contact {
    text-align: center;
    width: 26em;
    max-width: calc(100vw - 50px);

    .mononaut {
      font-family: "Courier", monospace;
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
  }
</style>

<div class="contact tab-content">
  <div class="avatar-and-intro">
    <a class="monkey-avatar" target="_blank" href="https://monospace.live" rel="noopener">
      <Mononaut />
    </a>
    <div class="intro">
      <p>Bitfeed is an experiment by <b class="mononaut">mononaut</b>.</p>
      <p><b class="mononaut"> v{config.version} </b></p>
      <p>Questions? Comments? Suggestions?</p>
    </div>
  </div>
  <p style="clear: both">Message me on twitter at
    <SocialLink icon={twitterIcon} href="https://twitter.com/mononautical" color="var(--twitter-blue)">@mononautical</SocialLink>
  </p>
  <p>Or email any recipient at
    <SocialLink icon={atIcon} href="mailto:bitfeed@monospace.live" color="var(--monospace-purple)">monospace.live</SocialLink>
  </p>
</div>
