<script>
import { onMount } from 'svelte'
import { settings } from '../stores.js'
import { integerFormat } from '../utils/format.js'
import { logTxSize, byteTxSize } from '../utils/misc.js'
import { interpolateHcl } from 'd3-interpolate'
import { color } from 'd3-color'

const sizes = [
  { value: 1000000, vbytes: 1*256, size: null },
  { value: 10000000, vbytes: 4*256, size: null },
  { value: 100000000, vbytes: 9*256, size: null },
  { value: 1000000000, vbytes: 16*256, size: null },
  { value: 10000000000, vbytes: 25*256, size: null }
]

let unitWidth
let unitPadding
let gridSize
let colorScale
const colorScaleWidth = 200

function resize () {
  unitWidth = Math.floor(Math.max(4, (window.innerWidth - 20) / 250))
  unitPadding = Math.floor(Math.max(1, (window.innerWidth - 20) / 1000))
  gridSize = unitWidth + (unitPadding * 2)
}
resize()

onMount(() => {
  resize()
  colorScale = generateColorScale('#f7941d', 'rgb(0%,100%,80%)')
})

function calcSizes (gridSize, unitWidth, unitPadding) {
  sizes.forEach(size => {
    size.size = calcSize(size)
  })
  sizes = sizes
}

$: {
  calcSizes(gridSize, unitWidth, unitPadding)
  console.log(sizes)
}

function calcSize ({ vbytes, value }) {
  if ($settings.vbytes) {
    return 2 * ((byteTxSize(vbytes - 1, Infinity, true) * gridSize / 2) - unitPadding)
  } else {
    return 2 * ((logTxSize(value - 1) * gridSize / 2) - unitPadding)
  }
}

function formatBytes (bytes) {
  const str = integerFormat.format(bytes) + ' vbytes'
  const padded = str.padStart(13, ' ')
  return padded
}

function formatValue (value) {
  const btc = value / 100000000
  const str = (btc < 1) ? btc.toPrecision(1) : `${Math.floor(btc)}`
  const units = str.split('.')[0].length
  const padded = str.padEnd(3 + units, ' ').padStart(6, ' ')
  return padded
}

function generateColorScale (colorA, colorB) {
  const canvas = document.createElement('canvas')
  const width = colorScaleWidth
  canvas.width = width
  canvas.height = 1
  const interpolator = interpolateHcl(colorA, colorB)
  const colorData = new Uint8ClampedArray(width * 4)
  for (let i = 0; i < width; i++) {
    let rgb = color(interpolator(i / width)).rgb()
    colorData[(i * 4)] = rgb.r
    colorData[(i * 4) + 1] = rgb.g
    colorData[(i * 4) + 2] = rgb.b
    colorData[(i * 4) + 3] = 255
  }
  const imageData = new ImageData(colorData, width)
  canvas.getContext("2d").putImageData(imageData, 0, 0)
  const scalePng = canvas.toDataURL()
  canvas.remove()
  return scalePng
}
</script>

<style type="text/scss">
  .legend {
    .square {
      display: block;
      padding: 0;
      background: var(--bold-a);
    }

    .size-legend {
      display: table;
      margin: auto;

      .size-row {
        display: table-row;
        margin: auto;
        padding: 2px 0;

        .square-container {
          display: table-cell;
          vertical-align: middle;
          display: inline-block;
          width: auto;
          margin: .25em 0;
          margin-right: 1em;
          line-height: 100%;
          .square {
            margin-left: auto;
          }
        }
        .value {
          display: table-cell;
          vertical-align: middle;
          line-height: 100%;
          .part.right {
            font-family: monospace;
            margin-left: .25em;
          }
        }
      }
    }

    .color-legend {
      display: flex;
      flex-direction: row;
      align-items: stretch;
      justify-content: center;

      .value {
        font-family: monospace;

        &.left {
          margin-right: .5em;
        }
        &.right {
          margin-left: .5em
        }
      }

      .color-scale-img {
        flex-shrink: 1;
        min-width: 0;
        flex-grow: 1;
      }
    }
  }
</style>

<svelte:window on:resize={resize} />

<div class="legend tab-content">
  {#if $settings.vbytes}
    <h3 class="subheading">Size in vBytes</h3>
  {:else}
    <h3 class="subheading">Total Value</h3>
  {/if}
  <div class="size-legend">
    {#if $settings.vbytes }
      {#each sizes as { size, vbytes } }
        <div class="size-row">
          <span class="square-container"><div class="square" style="width: {size}px; height: {size}px" /></span>
          <span class="value"><span class="part left">&lt;</span><span class="part center">&nbsp;</span><span class="part right">{ formatBytes(vbytes) }</span></span>
        </div>
      {/each}
    {:else}
      {#each sizes as { size, value } }
        <div class="size-row">
          <span class="square-container"><div class="square" style="width: {size}px; height: {size}px" /></span>
          <span class="value"><span class="part left">&lt;</span> <span class="part center">&#8383;</span><span class="part right">{ formatValue(value) }</span></span>
        </div>
      {/each}
    {/if}
  </div>
  <h3 class="subheading">Age in seconds</h3>
  <div class="color-legend">
    <span class="value left">0</span>
    <img src={colorScale} alt="" class="color-scale-img" width="200" height="15">
    <span class="value right">60+</span>
  </div>
</div>
