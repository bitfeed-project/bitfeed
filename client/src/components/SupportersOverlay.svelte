<script>
import config from '../config.js'
import { onMount } from 'svelte'
import Overlay from '../components/Overlay.svelte'
import { overlay, tiers, sponsors, heroes } from '../stores.js'

let displayHeroes = []
$: {
  if ($heroes) {
    displayHeroes = Object.values($heroes).filter(hero => {
      return hero && hero.id && hero.img_ext
    }).map(hero => {
      return {
        ...hero,
        img: `${config.donationRoot}/img/avatar/${hero.id}${hero.img_ext}`
      }
    })
  }
}
</script>

<Overlay name="supporters" fullSize>
  <section class="supporters-modal">
    <h2>Our Supporters</h2>
    <p class="info">
      Bitfeed is only possible thanks to the generosity of our supporters:
    </p>
    {#if $sponsors && $sponsors.length}
      <div class="group">
        <h3>Enterprise Sponsors</h3>
        <div class="entries">
          {#each $sponsors as sponsor}
            <a class="supporter" target="_blank" href={sponsor.website}>
              <img src={sponsor.img} alt={sponsor.name}>
              <span class="label">{ sponsor.name }</span>
            </a>
          {/each}
        </div>
      </div>
      <button class="action-button" on:click={() => { $overlay = 'donation' }}>
        Become a Sponsor!
      </button>
    {/if}
    {#if $heroes && displayHeroes.length}
      <div class="group">
        <h3>Community Heroes</h3>
        <div class="entries">
          {#each displayHeroes as hero}
            <a class="supporter hero" target="_blank" href="https://twitter.com/{hero.username}" title={hero.name}>
              <img src={hero.img} alt={hero.name}>
              <span class="label">@{ hero.username }</span>
            </a>
          {/each}
        </div>
      </div>
      <button class="action-button" on:click={() => { $overlay = 'donation' }}>
        Become a Community Hero!
      </button>
    {/if}
  </section>
</Overlay>

<style type="text/scss">
  .supporters-modal {
    font-size: 0.9rem;
    width: 100%;

    p.info {
      text-align: center;
      margin: 0 0 .25em;
    }

    h3 {
      margin-top: 2em;
    }

    .group {
      margin-bottom: 2em;
      .entries {
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
        justify-content: center;
        align-items: flex-start;

        .supporter {
          width: 120px;
          margin: 10px;
          display: flex;
          flex-direction: column;
          justify-content: flex-start;
          align-items: center;

          img {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            object-fit: cover;
            border: solid 3px transparent;
            transition: border 200ms;
          }

          &:hover {
            img {
              border: solid 3px var(--bold-a);
            }
          }

          &.hero {
            &:hover {
              img {
                border: solid 3px var(--bold-b);
              }
            }
            .label {
              max-width: 100%;
              overflow: hidden;
              text-overflow: ellipsis;
              font-size: 0.8em;
            }
          }
        }
      }
    }
  }
</style>
