<script>
  import { onMount } from 'svelte'
  import { tweened } from 'svelte/motion'
  import { easeOutBack } from '../utils/easing.js'
  import { interpolateLab } from 'd3-interpolate'

  export let tx

  $: console.log('tx id changed: ', tx.id)

  $: status = tx.status

  $: {
    if (status === 'mined') {
      expire()
    }
  }

  const dispatch = createEventDispatcher()

  const r = tweened(0, {
    easing: easeOutBack,
    duration: 600
  })
  const c = tweened('red',{
    interpolate: interpolateLab,
    duration: 200
  })
  const alpha = tweened(1, {
    delay: 200,
    duration: 200
  })
  const yOff = tweened(0)
    /*r: 1,
    c: {
      r: 49,
      g: 139,
      b: 150
    }
  }, {
    delay: 1000
  })*/

  function expire() {
    $c = '#ff9900'
    $alpha = 0
  }

  onMount(() => {
    console.log('created mempool tx: ', tx)
    $r = 4
  })
</script>

{#if tx}
<circle class="{tx.status}" cx='{tx.p.x}' cy='{tx.p.y + $yOff}' r='{$r}' fill="{$c}" opacity="{$alpha}">
  <title>{tx.id}</title>
</circle>
{/if}
