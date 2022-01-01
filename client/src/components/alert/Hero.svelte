<script>
import { onMount } from 'svelte'
import config from '../../config.js'
import { heroes } from '../../stores.js'

let displayHeroes = []

function chooseRandomHeroes () {
  displayHeroes = []
  const validHeroes = Object.values($heroes).filter(hero => {
    return hero && hero.id && hero.img_ext
  })
  const randomIndex = Math.floor(Math.random() * validHeroes.length)
  for (let i = 0; i < Math.min(3, validHeroes.length); i++) {
    const randomHero = validHeroes[(randomIndex + i) % validHeroes.length]
    displayHeroes.push({
      ...randomHero,
      img: `${config.donationRoot}/img/avatar/${randomHero.id}${randomHero.img_ext}`
    })
  }
}

$: {
  if ($heroes && !displayHeroes.length) {
    chooseRandomHeroes()
  }
}



</script>

<div class="alert-content">
  <p class="msg">Thank you to all of our Community Heroes!</p>
  <div class="heros">
    {#each displayHeroes as hero}
      <img src={hero.img} alt={hero.username} title={hero.name} class="hero">
    {/each}
  </div>
</div>

<style type="text/scss">
.alert-content {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  color: var(--palette-x);

  .msg {
    font-size: 0.9em;
  }

  .heros {
    height: 2.5em;
    width: 7.5em;
    margin-left: 10px;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    flex-shrink: 0;

    .hero {
      width: 2.3em;
      height: 2.3em;
      margin: 0 0.1em;
      border-radius: 50%;
      object-fit: contain;
    }
  }

  @media screen and (max-width: 480px) {
    .heros {
      max-width: 5em;
      .hero:nth-child(3) {
        display: none;
      }
    }
  }
}

</style>
