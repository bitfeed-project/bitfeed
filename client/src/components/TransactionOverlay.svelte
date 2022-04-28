<script>
import Overlay from '../components/Overlay.svelte'
import Icon from './Icon.svelte'
import BookmarkIcon from '../assets/icon/cil-bookmark.svg'
import { longBtcFormat, numberFormat, feeRateFormat, dateFormat } from '../utils/format.js'
import { exchangeRates, settings, sidebarToggle, newHighlightQuery, highlightingFull, detailTx, pageWidth, latestBlockHeight, highlightInOut, loading, urlPath, currentBlock, overlay, explorerBlockData } from '../stores.js'
import { formatCurrency } from '../utils/fx.js'
import { hlToHex, mixColor, teal, purple } from '../utils/color.js'
import { SPKToAddress } from '../utils/encodings.js'
import api from '../utils/api.js'
import { searchTx, searchBlockHash, searchBlockHeight } from '../utils/search.js'
import { fade } from 'svelte/transition'

function onClose () {
  $detailTx = null
  $highlightInOut = null
  $urlPath = "/"
}

function formatBTC (sats) {
  return `₿ ${(sats/100000000).toFixed(8)}`
}

function addToWatchlist (query) {
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

let confirmations = 0
$: {
  if ($detailTx && $detailTx.block && $detailTx.block.height != null && $latestBlockHeight != null) {
    confirmations =  (1 + $latestBlockHeight - $detailTx.block.height)
  }
}

const midColor = hlToHex(mixColor(teal, purple, 1, 3, 2))
let feeColor
$: {
  if ($detailTx && $detailTx.feerate != null) {
    feeColor = hlToHex(mixColor(teal, purple, 1, Math.log2(64), Math.log2($detailTx.feerate)))
  } else {
    feeColor = null
  }
}

function expandAddresses(items, truncate) {
  let truncated = truncate ? items.slice(0,100) : items
  const expanded = truncated.map((item, index) => {
    let address = 'unknown'
    let title = null
    if (item.script_pub_key) {
      address = SPKToAddress(item.script_pub_key) || "unknown"
      if (address === 'OP_RETURN') {
        title = item.script_pub_key.substring(4).match(/../g).reduce((parsed, hexChar) => {
          return parsed + String.fromCharCode(parseInt(hexChar, 16))
        }, "")
      } else if (address === 'P2PK') {
        if (item.script_pub_key.length === 70) title = 'compressed pubkey: ' + item.script_pub_key.substring(2,68)
        else title = 'pubkey: ' + item.script_pub_key.substring(2,132)
      }
    }
    return {
      ...item,
      address,
      title,
      index,
      opreturn: (address === 'OP_RETURN')
    }
  })
  if (truncate && items.length > 100) {
    const remainingCount = items.length - 100
    const remainingValue = items.slice(100).reduce((acc, item) => { return acc + item.value }, 0)
    expanded.push({
      address: `+ ${remainingCount} more`,
      value: remainingValue,
      rest: true
    })
  }
  return expanded
}

let truncate = true
$: {
  if ($detailTx && $detailTx.id) truncate = true
}

let inputs = []
let outputs = []
$: {
  if ($detailTx && $detailTx.inputs) {
    if ($detailTx.isCoinbase) {
      inputs = [{
        address: 'coinbase',
        value: $detailTx.value
      }]
    } else {
      inputs = expandAddresses($detailTx.inputs, truncate)
    }
  } else inputs = []
  if ($detailTx && $detailTx.outputs) {
    if ($detailTx.isCoinbase || !$detailTx.is_inflated || !$detailTx.fee) {
      outputs = expandAddresses($detailTx.outputs, truncate)
    } else {
      outputs = [{address: 'fee', value: $detailTx.fee, fee: true}, ...expandAddresses($detailTx.outputs, truncate)]
    }
  } else outputs = []
}

let highlight = {}
$: {
  if ($highlightInOut && $detailTx && $highlightInOut.txid === $detailTx.id) {
    highlight = {}
    if ($highlightInOut.input != null) highlight.in = parseInt($highlightInOut.input)
    if ($highlightInOut.output != null) highlight.out = parseInt($highlightInOut.output)
  } else {
    highlight = {}
  }
}

let sankeyLines
let sankeyHeight
$: {
  if ($detailTx && inputs && outputs) {
    sankeyHeight = Math.max(inputs.length, outputs.length) * rowHeight
    sankeyLines = calcSankeyLines(inputs, outputs, $detailTx.fee || null, $detailTx.value, sankeyHeight, svgWidth, flowWeight)
  }
}

function calcSankeyLines(inputs, outputs, fee, value, totalHeight, svgWidth, flowWeight) {
  const total = fee + value
  const mergeOffset = (totalHeight - flowWeight) / 2
  let cumThick = 0
  let xOffset = 0
  let maxXOffset = 0

  const inLines = inputs.map((input, index) => {
    if (input.value == null) {
      return { line: [], weight: 0, index, total: inputs.length, in: true }
    } else {
      const weight = (input.value / total) * flowWeight
      const height = ((index + 0.5) * rowHeight)
      const step = (weight / 2)
      const line = []
      const yOffset = 0.5

      line.push({ x: triangleWidth, y: height })
      line.push({ x: triangleWidth + (0.25 * svgWidth), y: height })
      line.push({ x: 0.425 * svgWidth, y: mergeOffset + cumThick + step + yOffset })
      line.push({ x: (0.5 * svgWidth) + 1, y: mergeOffset + cumThick + step + yOffset })

      const dy = line[1].y - line[2].y
      const dx = line[2].x - line[1].x
      const miterOffset = getMiterOffset(weight, dy, dx)
      xOffset += miterOffset
      line[1].x += xOffset
      line[2].x += xOffset
      xOffset += miterOffset
      maxXOffset = Math.max(xOffset, maxXOffset)

      // inLines.push({ line, weight })
      // inLines.push({ line: [{x: line[1].x + miterOffset, y: line[1].y - (weight / 2)}, {x: line[2].x + miterOffset, y: line[2].y - (weight / 2)}], weight: 1})

      cumThick += weight

      return { line, weight, index, total: inputs.length, in: true }
    }
  })
  inLines.forEach(line => {
    if (line.line.length) {
      line.line[1].x -= maxXOffset
      line.line[2].x -= maxXOffset
    }
  })

  cumThick = 0
  xOffset = 0
  maxXOffset = 0

  const outLines = outputs.map((output, index) => {
    const weight = (output.value / total) * flowWeight
    const height = ((index + 0.5) * rowHeight)
    const step = (weight / 2)
    const line = []
    const yOffset = 0.5

    line.push({ x: (0.5 * svgWidth) - 1, y: mergeOffset + cumThick + step + yOffset })
    line.push({ x: 0.575 * svgWidth, y: mergeOffset + cumThick + step + yOffset })
    line.push({ x: svgWidth - triangleWidth - (0.25 * svgWidth), y: height })
    line.push({ x: svgWidth - triangleWidth, y: height })

    const dy = line[2].y - line[1].y
    const dx = line[2].x - line[1].x
    const miterOffset = getMiterOffset(weight, dy, dx)
    xOffset += miterOffset
    line[1].x -= xOffset
    line[2].x -= xOffset
    xOffset += miterOffset
    maxXOffset = Math.max(xOffset, maxXOffset)

    // outLines.push({ line, weight })
    // outLines.push({ line: [{x: line[1].x + miterOffset, y: line[1].y - (weight / 2)}, {x: line[2].x + miterOffset, y: line[2].y - (weight / 2)}], weight: 1})

    cumThick += weight

    return { line, weight, index, total: outputs.length }
  })
  outLines.forEach(line => {
    line.line[1].x += maxXOffset
    line.line[2].x += maxXOffset
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

async function clickItem (item) {
  if (item.rest) {
    truncate = false
  }
}

async function goToInput(e, input) {
  e.preventDefault()
  loading.increment()
  await searchTx(input.prev_txid, null, input.prev_vout)
  loading.decrement()
}

async function goToOutput(e, output) {
  e.preventDefault()
  loading.increment()
  await searchTx(output.spend.txid, output.spend.vin)
  loading.decrement()
}

async function goToBlock(e) {
  e.preventDefault()

  // ignore click if it was triggered while selecting text, or if we don't have a block to go to
  if (!$detailTx || !$detailTx.block || !!window.getSelection().toString()) return

  let hash = $detailTx.block.hash || $detailTx.block.id
  let height = $detailTx.block.height
  if (hash === $currentBlock.id) {
    $overlay = null
  } else if (height == $latestBlockHeight) {
    $explorerBlockData = null
    $overlay = null
  } else if (hash) {
    loading.increment()
    await searchBlockHash($detailTx.block.hash || $detailTx.block.id)
    loading.decrement()
  }
}
</script>

<style type="text/scss">
  .tx-detail {
    width: 100%;
    overflow-x: hidden;
    text-align: left;

    h2 {
      margin: 0 0 1em;
      font-size: 1.2em;
      word-break: break-word;

      .title {
        font-size: 1.25em;
        white-space: nowrap;
      }
    }

    .tx-id {
      font-family: monospace;
      font-size: 0.9em;
      font-weight: 400;
    }

    .icon-button {
      float: right;
      font-size: 1.1em;
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

    .confirmation-badge {
      background: var(--light-good);
      padding: 4px 8px;
      border-radius: 8px;
      float: right;
      margin: 0 5px;
      color: white;
      font-weight: bold;

      &.unconfirmed {
        background: var(--light-ok);
      }
    }

    .pane {
      background: var(--palette-b);
      padding: 16px;
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

        .value.coinbase-sig {
          word-break: break-all;
        }
      }

      &.clickable {
        cursor: pointer;
        user-select: text;
        &:hover {
          background: var(--palette-a);
        }
      }
    }

    .fields {
      align-items: center;
      display: flex;
      flex-direction: row;
      justify-content: center;
      width: auto;
      color: var(--palette-x);

      .operator {
        font-size: 2em;
        color: var(--grey);
        margin: 0 1em;
      }
    }

    .flow-diagram {
      display: grid;
      grid-template-columns: minmax(0px, 1fr) 380px minmax(0px, 1fr);
      padding: 16px 0;

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
          position: relative;
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

          &.clickable {
            cursor: pointer;
          }

          .put-link {
            position: absolute;
            top: 0;
            bottom: 0;
            width: 1.5em;
            display: flex;
            justify-content: center;
            align-items: center;

            .chevron {
              .outline {
                stroke: white;
                stroke-width: 32;
                stroke-linecap: butt;
                stroke-linejoin: miter;
                fill: white;
                fill-opacity: 0;
                transition: fill-opacity 300ms;
              }

              &.right {
                transform: scaleX(-1);
              }
            }

            &:hover {
              .chevron .outline {
                fill-opacity: 1;
              }
            }
          }
        }

        &.inputs {
          .entry {
            align-items: flex-start;
            padding-left: 1.5em;
            &.highlight {
              background: linear-gradient(90deg, var(--bold-a) -100%, transparent 100%);
            }
            &.clickable:hover {
              background: linear-gradient(90deg, var(--palette-e), transparent);
            }
            .address {
              text-align: left;
            }

            .put-link {
              left: 0;
            }
          }
        }

        &.outputs {
          .entry {
            padding-right: 1.5em;
            border-right: solid 1px transparent;
            &.highlight {
              background: linear-gradient(90deg, transparent 0%, var(--bold-a) 200%);
            }
            &.clickable:hover {
              background: linear-gradient(-90deg, var(--palette-e), transparent);
            }

            .put-link {
              right: 0;
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
      .fields {
        flex-direction: column;
      }
    }

    @media (min-width: 411px) and (max-width: 479px) {
      .flow-diagram {
        font-size: 0.7em;
      }
    }

    @media (max-width: 410px) {
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
      <div class="icon-button" class:disabled={$highlightingFull} on:click={() => addToWatchlist($detailTx.id)} title="Add transaction to watchlist">
        <Icon icon={BookmarkIcon}/>
      </div>
      {#if $detailTx.block && $latestBlockHeight != null}
        <span class="confirmation-badge">
          {numberFormat.format(confirmations)} confirmation{confirmations == 1 ? '' : 's'}
        </span>
      {:else}
        <span class="confirmation-badge unconfirmed">
          unconfirmed
        </span>
      {/if}
      <h2><span class="title">{#if $detailTx.isCoinbase }Coinbase{:else}Transaction{/if}</span> <span class="tx-id">{ $detailTx.id }</span></h2>
      {#if $detailTx.block}
        <a class="pane fields clickable" href="/block/{$detailTx.block.hash || $detailTx.block.id}" draggable="false" on:click={goToBlock}>
          <div class="field">
            <span class="label">confirmed</span>
            <span class="value" style="color: {feeColor};">{ dateFormat.format($detailTx.block.time) }</span>
          </div>
          <span class="operator"></span>
          <div class="field">
            <span class="label">block height</span>
            <span class="value" style="color: {feeColor};">{ numberFormat.format($detailTx.block.height) }</span>
          </div>
        </a>
      {/if}
      {#if $detailTx.isCoinbase}
        <div class="pane fields">
          <div class="field">
            <span class="label">block subsidy</span>
            <span class="value">{ formatBTC($detailTx.coinbase.subsidy) }</span>
          </div>
          <span class="operator">+</span>
          <div class="field">
            <span class="label">fees</span>
            <span class="value">{ formatBTC($detailTx.coinbase.fees) }</span>
          </div>
          <span class="operator">=</span>
          <div class="field">
            <span class="label">total reward</span>
            <span class="value">{ formatBTC($detailTx.value) }</span>
          </div>
        </div>

        <div class="pane fields">
          <div class="field">
            <span class="label">coinbase</span>
            <span class="value coinbase-sig">{ $detailTx.coinbase.sigAscii }</span>
          </div>
        </div>
      {:else}
        {#if $detailTx.is_inflated && $detailTx.fee != null && $detailTx.feerate != null}
          <div class="pane fields">
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
        {:else}
        <div class="pane fields">
          <div class="field">
            <span class="label">size</span>
            <span class="value" style="color: {feeColor};">{ numberFormat.format($detailTx.vbytes) } vbytes</span>
          </div>
        </div>
        {/if}

        <div class="pane total-value">
          <div class="field">
            <span class="label">total value</span>
            <span class="value" style="color: {feeColor};">{ formatBTC($detailTx.value) }</span>
          </div>
        </div>
      {/if}

      <div class="pane flow-diagram" style="grid-template-columns: minmax(0px, 1fr) {svgWidth}px minmax(0px, 1fr);">
        <div class="column inputs">
          <p class="header">{$detailTx.inputs.length} input{$detailTx.inputs.length > 1 ? 's' : ''}</p>
          {#each inputs as input, index}
            <div class="entry" class:clickable={input.rest} class:highlight={highlight.in != null && highlight.in === index} on:click={() => clickItem(input)}>
              {#if input.prev_txid }
                <a href="/tx/{input.prev_txid}:{input.prev_vout}" on:click={(e) => goToInput(e, input)} class="put-link" transition:fade|local={{ duration: 200 }}>
                  <svg class="chevron left" height="1.2em" width="1.2em" viewBox="0 0 512 512">
                    <path d="M 107.628,257.54 327.095,38.078 404,114.989 261.506,257.483 404,399.978 327.086,476.89 Z" class="outline" />
                  </svg>
                </a>
              {/if}
              <p class="address" title={input.title || input.address}><span class="truncatable">{input.address.slice(0,-6)}</span><span class="suffix">{input.address.slice(-6)}</span></p>
              <p class="amount">{ input.value == null ? '???' : formatBTC(input.value) }</p>
            </div>
          {/each}
        </div>
        <div class="column diagram">
          {#if sankeyLines && $pageWidth > 410}
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
          <p class="header">{$detailTx.outputs.length} output{$detailTx.outputs.length > 1 ? 's' : ''} {#if $detailTx.fee}+ fee{/if}</p>
          {#each outputs as output}
            <div class="entry" class:clickable={output.rest} class:highlight={highlight.out != null && highlight.out === output.index} on:click={() => clickItem(output)}>
              {#if output.spend}
                <a href="/tx/{output.spend.vin}:{output.spend.txid}" on:click={(e) => goToOutput(e, output)} class="put-link" transition:fade|local={{ duration: 200 }}>
                  <svg class="chevron right" height="1.2em" width="1.2em" viewBox="0 0 512 512">
                    <path d="M 107.628,257.54 327.095,38.078 404,114.989 261.506,257.483 404,399.978 327.086,476.89 Z" class="outline" />
                  </svg>
                </a>
              {/if}
              <p class="address" title={output.title || output.address}><span class="truncatable">{output.address.slice(0,-6)}</span><span class="suffix">{output.address.slice(-6)}</span></p>
              <p class="amount">{ output.value == null ? '???' : formatBTC(output.value) }</p>
            </div>
          {/each}
        </div>
      </div>
    </section>
  {/if}
</Overlay>
