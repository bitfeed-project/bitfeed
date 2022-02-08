<script>
  import { onMount } from 'svelte'
  import vertShaderSrc from '../shaders/tx.vert'
  import fragShaderSrc from '../shaders/tx.frag'
  import TxSprite from '../models/TxSprite.js'
  import { color, hcl } from 'd3-color'
  import { darkMode, frameRate, avgFrameRate, nativeAntialias, settings, devSettings } from '../stores.js'
  import config from '../config.js'

  let canvas
  let gl
  let animationFrameRequest
  let simulateAntialiasing = false
  let autoSetGraphicsMode = false
  let displayWidth
  let displayHeight
  let shaderProgram
  let aspectRatio
  let sceneScale = [1.0, 1.0]
  let pointArray
  let debugPointArray

  let lastTime = performance.now()
  let rawFrameRate = 0
  const frameRateSamples = Array(60).fill(60)
  const frameRateReducer = (acc, rate) => { return acc + rate }
  let frameRateSampleIndex = 0

  const nullPointArray = new Float32Array()

  // Props
  export let controller
  export let running = false

  // Shader attributes
  // each attribute (except index) contains [x: startValue, y: endValue, z: startTime, w: rate]
  // shader interpolates between start and end values at the given rate, from the given time
  const attribs = {
    offset: { type: 'FLOAT', count: 2, pointer: null },
    posX: { type: 'FLOAT', count: 4, pointer: null },
    posY: { type: 'FLOAT', count: 4, pointer: null },
    posR: { type: 'FLOAT', count: 4, pointer: null },
    hues: { type: 'FLOAT', count: 4, pointer: null },
    lights: { type: 'FLOAT', count: 4, pointer: null },
    alphas: { type: 'FLOAT', count: 4, pointer: null }
  }
  // Auto-calculate the number of bytes per vertex based on specified attributes
  const stride = Object.values(attribs).reduce((total, attrib) => {
    return total + (attrib.count * 4)
  }, 0)
  // Auto-calculate vertex attribute offsets
  for (let i = 0, offset = 0; i < Object.keys(attribs).length; i++) {
    let attrib = Object.values(attribs)[i]
    attrib.offset = offset
    offset += (attrib.count * 4)
  }

  // Color map texture
  let colorTexture

  // Computed
  $: {
    if (running) run()
  }

  $: {
    simulateAntialiasing = !$nativeAntialias && $settings.fancyGraphics
    resizeCanvas()
  }

  function windowReady () {
    resizeCanvas()
  }

  function resizeCanvas () {
    // var rect = canvas.parentNode.getBoundingClientRect()
    if (canvas) {
      displayWidth = window.innerWidth
      displayHeight = window.innerHeight
      if (simulateAntialiasing) {
        canvas.width = displayWidth * 2
        canvas.height = displayHeight * 2
      } else {
        canvas.width = displayWidth
        canvas.height = displayHeight
      }
      if (gl) gl.viewport(0, 0, canvas.width, canvas.height)
    } else {
      setTimeout(resizeCanvas, 500)
    }
  }

  function getTxPointArray () {
    if (controller) {
      return controller.getVertexData()
      // return new Float32Array(
      //   controller.getScenes().flatMap(scene => scene.getVertexData())
      // )
    } else return new Float32Array()
  }

  function getDebugTxPointArray () {
    if (controller && $devSettings.layoutHints) {
      return controller.getDebugVertexData()
      // return new Float32Array(
      //   controller.getScenes().flatMap(scene => scene.getVertexData())
      // )
    } else return new Float32Array()
  }

  function compileShader(src, type) {
    let shader = gl.createShader(type)

    gl.shaderSource(shader, src)
    gl.compileShader(shader)

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.log(`Error compiling ${type === gl.VERTEX_SHADER ? "vertex" : "fragment"} shader:`)
      console.log(gl.getShaderInfoLog(shader))
    }
    return shader
  }

  function buildShaderProgram(shaderInfo) {
    let program = gl.createProgram()

    shaderInfo.forEach(function(desc) {
      let shader = compileShader(desc.src, desc.type)
      if (shader) {
        gl.attachShader(program, shader)
      }
    })

    gl.linkProgram(program)

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.log("Error linking shader program:")
      console.log(gl.getProgramInfoLog(program))
    }

    return program
  }

  function run (now) {
    if (!now) {
      now = performance.now()
    }
    // /* RESET DRAWING AREA */

    /* LOAD VERTEX DATA */
    pointArray = getTxPointArray()
    if (config.layoutHints) {
      debugPointArray = getDebugTxPointArray()
      const combinedArray = new Float32Array(pointArray.length + debugPointArray.length)
      combinedArray.set(pointArray, 0)
      combinedArray.set(debugPointArray, pointArray.length)
      pointArray = combinedArray
    }

    /* SET UP SHADER UNIFORMS */
    // screen dimensions
    gl.uniform2f(gl.getUniformLocation(shaderProgram, 'screenSize'), displayWidth, displayHeight)
    // frame timestamp
    gl.uniform1f(gl.getUniformLocation(shaderProgram, 'now'), now)
    gl.uniform1i(gl.getUniformLocation(shaderProgram, 'colorTexture'), 0);

    /* SET UP SHADER ATTRIBUTES */
    Object.keys(attribs).forEach((key, i) => {
      gl.vertexAttribPointer(attribs[key].pointer,
          attribs[key].count,  // number of primitives in this attribute
          gl[attribs[key].type],  // type of primitive in this attribute (e.g. gl.FLOAT)
          false, // never normalised
          stride,   // distance between values of the same attribute
          attribs[key].offset);  // offset of the first value
    })

    if (pointArray.length) {
      gl.bufferData(gl.ARRAY_BUFFER, pointArray, gl.DYNAMIC_DRAW)
      gl.drawArrays(gl.TRIANGLES, 0, pointArray.length / TxSprite.vertexSize)
    }

    const rawFrameRate = (1000 / (now - lastTime)) + 0.075
    frameRateSamples[frameRateSampleIndex++] = rawFrameRate
    if (frameRateSampleIndex >= frameRateSamples.length) frameRateSampleIndex = 0
    const rawAvgFrameRate = frameRateSamples.reduce(frameRateReducer, 0) / frameRateSamples.length
    // rawFrameRate = Math.max(1, (rawFrameRate * 0.8) + (0.2 * (1 / (frameTime / 1000))))
    if (rawAvgFrameRate < 45 && !autoSetGraphicsMode) {
      autoSetGraphicsMode = true
      $settings.fancyGraphics = false
    }
    frameRate.set(rawFrameRate)
    avgFrameRate.set(rawAvgFrameRate)
    lastTime = now

    /* LOOP */
    if (running) {
      // if (animationFrameRequest) {
      //   cancelAnimationFrame(animationFrameRequest)
      //   animationFrameRequest = null
      // }
      animationFrameRequest = requestAnimationFrame(run)
    }
  }

  function computeColorTextureData(width, height) {
    return [...Array(Math.floor(height)).keys()].flatMap(row => {
      return [...Array(width).keys()].flatMap(step => {
        let rgb = color(hcl((row/height) * 360, 78.225, (step / width) * 150)).rgb()
        return [
          rgb.r,
          rgb.g,
          rgb.b,
          255
        ]
      })
    })
  }

  // Precomputes an 2d color texture projected from HCL space with chroma=78.225
  // transitions between points in this space are much more aesthetically pleasing than RGB interpolations
  function loadColorTexture(gl, width, height) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);

    const colorData = computeColorTextureData(width, height)

    const level = 0;
    const internalFormat = gl.RGBA;
    const border = 0;
    const srcFormat = gl.RGBA;
    const srcType = gl.UNSIGNED_BYTE;
    const pixels = new Uint8Array(
      colorData
    )

    gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                  width, height, border, srcFormat, srcType,
                  pixels);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

    return texture;
  }

  function initCanvas () {
    $nativeAntialias = gl.getContextAttributes().antialias

    gl.clearColor(0.0, 0.0, 0.0, 0.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    const shaderSet = [
      {
        type: gl.VERTEX_SHADER,
        src: vertShaderSrc
      },
      {
        type: gl.FRAGMENT_SHADER,
        src: fragShaderSrc
      }
    ]

    shaderProgram = buildShaderProgram(shaderSet)

    gl.useProgram(shaderProgram)

    // Set up alpha blending
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

    colorTexture = loadColorTexture(gl, 512, 512);

    const glBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer)

    /* SET UP SHADER UNIFORMS */
    // Color mapping textures
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, colorTexture)

    /* SET UP SHADER ATTRIBUTES */
    Object.keys(attribs).forEach((key, i) => {
      attribs[key].pointer = gl.getAttribLocation(shaderProgram, key)
      gl.enableVertexAttribArray(attribs[key].pointer);
    })

    running = true
  }

  function handleContextLost(event) {
    console.log('webgl context lost')
    event.preventDefault()
    cancelAnimationFrame(animationFrameRequest)
    animationFrameRequest = null
    running = false
  }

  function handleContextRestored(event) {
    console.log('webgl context restored')
    initCanvas()
    running = true
  }

  onMount(() => {
    canvas.addEventListener("webglcontextlost", handleContextLost, false)
    canvas.addEventListener("webglcontextrestored", handleContextRestored, false)
    gl = canvas.getContext('webgl')
    initCanvas()
  })
</script>

<style type="text/scss">
.tx-scene {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  /* pointer-events: none; */
  overflow: hidden;

  &.sim-antialias {
    transform: scale(0.5);
    transform-origin: top left;
  }
}
</style>

<svelte:window on:resize={resizeCanvas} on:load={windowReady} />

<canvas
  class="tx-scene"
  class:sim-antialias={simulateAntialiasing}
  bind:this={canvas}
></canvas>
