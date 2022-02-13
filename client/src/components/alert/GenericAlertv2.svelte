<script>
export let msg
export let shortmsg = null
export let imgs

let displayImgs = []

function chooseImgs () {
  displayImgs = []
  const randomIndex = Math.floor(Math.random() * imgs.length)
  for (let i = 0; i < Math.min(3, imgs.length); i++) {
    const randomImg = imgs[(randomIndex + i) % imgs.length]
    if (randomImg && randomImg.img) displayImgs.push(randomImg)
  }
}

$: {
  if (imgs && !displayImgs.length) {
    chooseImgs()
  }
}
</script>

<div class="alert-content">
  <p class="msg">
    {@html msg }
  </p>
  <p class="shortmsg">
    {@html shortmsg || msg }
  </p>
  <div class="imgs">
    {#each displayImgs as img}
    {#if img.href }
      <a href={img.href} target="_blank">
        <img src={img.img} alt={img.name} title={img.name} class="image">
      </a>
    {:else}
      <img src={img.img} alt={img.name} title={img.name} class="image">
    {/if}
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

  .imgs {
    height: 2.5em;
    width: 7.5em;
    margin-left: 10px;
    display: flex;
    flex-direction: row;
    justify-content: space-around;
    align-items: center;
    flex-shrink: 1;
    min-width: 6em;

    .image {
      width: 2.3em;
      height: 2.3em;
      margin: 0 0.1em;
      border-radius: 50%;
      object-fit: contain;
    }
  }

  @media screen and (max-width: 480px) {
    .imgs {
      max-width: 5em;
      .image:nth-child(3) {
        display: none;
      }
    }
  }
}

.msg, .shortmsg {
  margin: 0;
  font-size: .9em;
  width: 100%;
  text-align: center;
  max-height: 100%;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
}
.shortmsg {
  display: none;
}
img {
  height: 2.8em;
}

@media screen and (max-width: 480px) {
  .shortmsg {
    display: inline;
  }
  .msg {
    display: none;
  }
}

</style>
