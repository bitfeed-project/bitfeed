<script>
import { onMount } from 'svelte'
import { logTxSize } from '../utils/misc.js'
import { interpolateHcl } from 'd3-interpolate'
import { color } from 'd3-color'

const sizeValues = [
  { val: 1000000, size: null },
  { val: 10000000, size: null },
  { val: 100000000, size: null },
  { val: 1000000000, size: null },
  { val: 10000000000, size: null }
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

function calcSizeValues (gridSize, unitWidth, unitPadding) {
  sizeValues.forEach(sizeVal => {
    sizeVal.size = calcSize(sizeVal.val)
  })
  sizeValues = sizeValues
}

$: {
  calcSizeValues(gridSize, unitWidth, unitPadding)
}

function calcSize (value) {
  return 2 * ((logTxSize(value - 1) * gridSize / 2) - unitPadding)
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
    padding: .5em;

    .square {
      display: block;
      padding: 0;
      background: var(--bold-a);
    }

    h3 {
      font-size: 1rem;
      font-weight: normal;
      margin: 0 0 .5rem;
      text-align: center;
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

<div class="legend">
  <h3 class="subheading">Total Value</h3>
  <div class="size-legend">
    {#each sizeValues as { size, val } }
      <div class="size-row">
        <span class="square-container"><div class="square" style="width: {size}px; height: {size}px" /></span>
        <span class="value"><span class="part left">&lt;</span> <span class="part center">&#8383;</span><span class="part right">{ formatValue(val) }</span></span>
      </div>
    {/each}
  </div>
  <h3 class="subheading">Age in seconds</h3>
  <div class="color-legend">
    <span class="value left">0</span>
    <img src={colorScale} alt="" class="color-scale-img">
    <span class="value right">60+</span>
  </div>
</div>
