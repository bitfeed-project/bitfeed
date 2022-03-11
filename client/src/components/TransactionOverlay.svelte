<script>
import Overlay from '../components/Overlay.svelte'
import Icon from './Icon.svelte'
import BookmarkIcon from '../assets/icon/cil-bookmark.svg'
import { longBtcFormat, numberFormat, feeRateFormat } from '../utils/format.js'
import { exchangeRates, settings, sidebarToggle, newHighlightQuery, highlightingFull, detailTx, pageWidth } from '../stores.js'
import { formatCurrency } from '../utils/fx.js'
import { hlToHex, mixColor, teal, purple } from '../utils/color.js'
import { SPKToAddress } from '../utils/encodings.js'

function onClose () {
  $detailTx = null
}

function formatBTC (sats) {
  return `₿ ${(sats/100000000).toFixed(8)}`
}

function highlight (query) {
  if (!$highlightingFull && query) {
    $newHighlightQuery = query
    $sidebarToggle = 'search'
  }
}
const rowHeight = 60
let svgWidth = 380
let flowWeight = 60
let triangleWidth = 20
$: {
  if ($pageWidth) {
    if ($pageWidth < 800) {
      svgWidth = Math.max($pageWidth - 420, 120)
      flowWeight = 0.1875 * (svgWidth - 60)
    } else {
      svgWidth = 380
      flowWeight = 60
    }
    if ($pageWidth < 600) {
      triangleWidth = 10
    } else {
      triangleWidth = 20
    }
  }
}

const midColor = hlToHex(mixColor(teal, purple, 1, 3, 2))
let feeColor
$: {
  if ($detailTx && $detailTx.feerate != null) {
    feeColor = hlToHex(mixColor(teal, purple, 1, Math.log2(64), Math.log2($detailTx.feerate)))
  }
}

function expandAddresses(items) {
  return items.map(item => {
    let address = 'unknown'
    if (item.script_pub_key) {
      address = SPKToAddress(item.script_pub_key) || ""
    }
    return {
      ...item,
      address
    }
  })
}

let inputs = []
let outputs = []
$: {
  if ($detailTx && $detailTx.inputs) {
    inputs = expandAddresses($detailTx.inputs)
  } else inputs = []
  if ($detailTx && $detailTx.outputs) {
    outputs = expandAddresses($detailTx.outputs)
  } else outputs = []
}

let sankeyLines
let sankeyHeight
$: {
  if ($detailTx && $detailTx.inputs && $detailTx.outputs) {
    sankeyHeight = Math.max($detailTx.inputs.length, $detailTx.outputs.length + 1) * rowHeight
    sankeyLines = calcSankeyLines($detailTx.inputs, $detailTx.outputs, $detailTx.fee || null, $detailTx.value, sankeyHeight, svgWidth, flowWeight)
  }
}

function calcSankeyLines(inputs, outputs, fee, value, totalHeight, svgWidth, flowWeight) {
  const feeAndOutputs = [{ value: fee }, ...outputs]
  const total = fee + value
  const mergeOffset = (totalHeight - flowWeight) / 2
  let cumThick = 0
  let xOffset = 0

  const inLines = inputs.map((input, index) => {
    const weight = (input.value / total) * flowWeight
    const height = ((index + 0.5) * rowHeight)
    const step = (weight / 2)
    const line = []
    const yOffset = 0.5

    line.push({ x: triangleWidth, y: height })
    line.push({ x: triangleWidth + (0.25 * svgWidth), y: height })
    line.push({ x: 0.375 * svgWidth, y: mergeOffset + cumThick + step + yOffset })
    line.push({ x: (0.5 * svgWidth) + 1, y: mergeOffset + cumThick + step + yOffset })

    const dy = line[1].y - line[2].y
    const dx = line[2].x - line[1].x
    const miterOffset = getMiterOffset(weight, dy, dx)
    xOffset -= miterOffset
    line[1].x -= xOffset
    line[2].x -= xOffset
    xOffset -= miterOffset

    // inLines.push({ line, weight })
    // inLines.push({ line: [{x: line[1].x + miterOffset, y: line[1].y - (weight / 2)}, {x: line[2].x + miterOffset, y: line[2].y - (weight / 2)}], weight: 1})

    cumThick += weight

    return { line, weight, index, total: inputs.length, in: true }
  })
  inLines.forEach(line => {
    line.line[1].x += xOffset
    line.line[2].x += xOffset
  })

  cumThick = 0
  xOffset = 0

  const outLines = feeAndOutputs.map((output, index) => {
    const weight = (output.value / total) * flowWeight
    const height = ((index + 0.5) * rowHeight)
    const step = (weight / 2)
    const line = []
    const yOffset = 0.5

    line.push({ x: (0.5 * svgWidth) - 1, y: mergeOffset + cumThick + step + yOffset })
    line.push({ x: 0.625 * svgWidth, y: mergeOffset + cumThick + step + yOffset })
    line.push({ x: svgWidth - triangleWidth - (0.25 * svgWidth), y: height })
    line.push({ x: svgWidth - triangleWidth, y: height })

    const dy = line[2].y - line[1].y
    const dx = line[2].x - line[1].x
    const miterOffset = getMiterOffset(weight, dy, dx)
    xOffset -= miterOffset
    line[1].x += xOffset
    line[2].x += xOffset
    xOffset -= miterOffset

    // outLines.push({ line, weight })
    // outLines.push({ line: [{x: line[1].x + miterOffset, y: line[1].y - (weight / 2)}, {x: line[2].x + miterOffset, y: line[2].y - (weight / 2)}], weight: 1})

    cumThick += weight

    return { line, weight, index, total: feeAndOutputs.length }
  })
  outLines.forEach(line => {
    line.line[1].x -= xOffset
    line.line[2].x -= xOffset
  })

  return [...inLines, ...outLines].map(line => {
    return {
      points: line.line.map(point => { return `${point.x},${point.y}`}).join(' '),
      weight: line.weight,
      index: line.index,
      total: line.total,
      in: line.in
    }
  })
}

// given a line weight and corner angle
// return the horizontal distance of a miter from the corner
function getMiterOffset (weight, dy, dx) {
  if (dy != 0) {
    const angle = Math.atan2(dy, dx)
    const u = weight / 2
    const a = 0
    const b = dy / dx
    const c = -u
    const d = -u * (Math.cos(angle) + (b * Math.sin(angle)))
    return (d - c) / (a - b)
  } else return 0
}
</script>

<style type="text/scss">
  .tx-detail {
    width: 100%;
    overflow-x: hidden;
    text-align: left;

    h2 {
      font-size: 1.2em;
      word-break: break-word;
    }

    .tx-id {
      font-family: monospace;
      font-size: 0.9em;
      font-weight: 400;
    }

    .icon-button {
      float: right;
      font-size: 24px;
      margin: 0;
      transition: opacity 300ms, color 300ms, background 300ms;
      background: var(--palette-d);
      color: var(--bold-a);
      cursor: pointer;
      padding: 5px;
      border-radius: 5px;
      &:hover {
        background: var(--palette-e);
      }
      &.disabled {
        color: var(--palette-e);
        background: none;
      }
    }

    .pane {
      background: var(--palette-b);
      padding: .5em 1em;
      border-radius: .5em;
      margin: 0 0 1em;

      .field {
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        align-items: center;

        .label {
          font-size: 0.8em;
          color: var(--grey);
        }
      }
    }

    .fee-calc {
      align-items: center;
      display: flex;
      flex-direction: row;
      justify-content: center;
      width: auto;

      .operator {
        font-size: 2em;
        color: var(--grey);
        margin: 0 1em;
      }
    }

    .flow-diagram {
      display: grid;
      grid-template-columns: minmax(0px, 1fr) 380px minmax(0px, 1fr);

      .header {
        height: 60px;
        font-size: 1.1em;
        font-weight: 800;
        margin: 0;
        text-align: center;
      }

      .column {
        width: 100%;
        margin: 0;

        .entry {
          height: 60px;
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          justify-content: center;
          border-top: solid 1px var(--grey);
          box-sizing: border-box;
          text-align: right;
          width: 100%;
          overflow: hidden;
          &:last-child {
            border-bottom: solid 1px var(--grey);
          }

          .amount, .address {
            margin: 0;
            font-family: monospace;
            font-size: 1.1em;
          }
          .amount {
            white-space: nowrap;
          }
          .address {
            width: 100%;
            text-align: right;
            span {
              overflow: hidden;
              text-overflow: ellipsis;
              display: inline-block;
            }
            .truncatable {
              max-width: calc(100% - 4em);
            }
          }
        }

        &.inputs {
          .entry {
            align-items: flex-start;
            .address {
              text-align: left;
            }
          }
        }
      }

      .sankey {
        margin-top: 60px;

        polyline {
          fill: none;
          stroke-linecap: butt;
          stroke-linejoin: miter;
        }
      }
    }

    @media (max-width: 679px) {
      .fee-calc {
        flex-direction: column;
      }
    }

    @media (max-width: 460px) {
      .flow-diagram {
        display: block;

        .column {
          width: 100%;
          margin: 30px 0;
        }
      }
    }
  }
</style>

<Overlay name="tx" on:close={onClose}>
  {#if $detailTx}
    <section class="tx-detail">
      <div class="icon-button" class:disabled={$highlightingFull} on:click={() => highlight($detailTx.id)} title="Add transaction to watchlist">
        <Icon icon={BookmarkIcon}/>
      </div>
      <h2>Transaction <span class="tx-id">{ $detailTx.id }</span></h2>
      <div class="pane fee-calc">
        <div class="field">
          <span class="label">fee</span>
          <span class="value" style="color: {feeColor};">{ numberFormat.format($detailTx.fee) } sats</span>
        </div>
        <span class="operator">/</span>
        <div class="field">
          <span class="label">size</span>
          <span class="value" style="color: {feeColor};">{ numberFormat.format($detailTx.vbytes) } vbytes</span>
        </div>
        <span class="operator">=</span>
        <div class="field">
          <span class="label">fee rate</span>
          <span class="value" style="color: {feeColor};">{ numberFormat.format($detailTx.feerate.toFixed(2)) } sats/vbyte</span>
        </div>
      </div>

      <div class="pane total-value">
        <div class="field">
          <span class="label">Total value</span>
          <span class="value" style="color: {feeColor};">{ formatBTC($detailTx.value) }</span>
        </div>
      </div>

      <h2>Inputs &amp; Outputs</h2>
      <div class="pane flow-diagram" style="grid-template-columns: minmax(0px, 1fr) {svgWidth}px minmax(0px, 1fr);">
        <div class="column inputs">
          <p class="header">{$detailTx.inputs.length} input{$detailTx.inputs.length > 1 ? 's' : ''}</p>
          {#each inputs as input}
            <div class="entry">
              <p class="address" title={input.address}><span class="truncatable">{input.address.slice(0,-6)}</span><span class="suffix">{input.address.slice(-6)}</span></p>
              <p class="amount">{ formatBTC(input.value) }</p>
            </div>
          {/each}
        </div>
        <div class="column diagram">
          {#if sankeyLines && $pageWidth > 460}
            <svg class="sankey" height="{sankeyHeight}px" width="{svgWidth}px">
              <defs>
                {#each sankeyLines as line, index}
                  <linearGradient id="lg{index}" x1="0%" y1="0%" x2="100%" y2="0%">
                    {#if line.in}
                      <stop offset="0%"   stop-color={hlToHex(mixColor(teal, purple, 0, Math.max(1,line.total-1), line.index))}/>
                      <stop offset="100%" stop-color={midColor}/>
                    {:else}
                      <stop offset="0%" stop-color={midColor}/>
                      <stop offset="100%"   stop-color={hlToHex(mixColor(purple, teal, 0, Math.max(1,line.total-1), line.index))}/>
                    {/if}
                  </linearGradient>
                {/each}
              </defs>
              {#each sankeyLines as line, index }
                <polyline points="{line.points}" stroke="url(#lg{index})" style="stroke-width: {line.weight + 1}px;" />
                {#if line.in}
                  <polyline points="0,{line.index * 60} {triangleWidth},{(line.index * 60 )+ 30} 0,{(line.index * 60) + 60}" stroke="var(--grey)" style="stroke-width: 1px;" />
                {:else}
                  <polyline points="{svgWidth},{line.index * 60} {svgWidth - triangleWidth},{(line.index * 60 )+ 30} {svgWidth},{(line.index * 60) + 60}" stroke="var(--grey)" style="stroke-width: 1px;" />
                {/if}
              {/each}
            </svg>
          {/if}
        </div>
        <div class="column outputs">
          <p class="header">{$detailTx.outputs.length} output{$detailTx.outputs.length > 1 ? 's' : ''}</p>
          <div class="entry fee">
            <p class="address">fee</p>
            <p class="amount">{ formatBTC($detailTx.fee) }</p>
          </div>
          {#each outputs as output}
            <div class="entry">
              <p class="address" title={output.address}><span class="truncatable">{output.address.slice(0,-6)}</span><span class="suffix">{output.address.slice(-6)}</span></p>
              <p class="amount">{ formatBTC(output.value) }</p>
            </div>
          {/each}
        </div>
      </div>
    </section>
  {/if}
</Overlay>
