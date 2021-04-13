<script>
  import { onMount } from 'svelte'
  import vertShaderSrc from '../shaders/tx.vert'
  import fragShaderSrc from '../shaders/tx.frag'
  import { interpolateHcl } from 'd3-interpolate'
  import { color } from 'd3-color'
  import { darkMode } from '../stores.js'

  export let txs = []
  let canvas
  let gl
  let shaderProgram
  let aspectRatio
  let sceneScale = [1.0, 1.0]
  let lastTime = 0.0

  const baseTime = performance.now()

  // Vertex information
  let pointArray

  // Shader uniforms

  // Shader attributes
  const attribs = {
    startTime: { type: 'FLOAT', count: 1, pointer: null },
    zIndex: { type: 'FLOAT', count: 1, pointer: null },
    speed: { type: 'FLOAT', count: 1, pointer: null },
    positions: { type: 'FLOAT', count: 4, pointer: null },
    sizes: { type: 'FLOAT', count: 2, pointer: null },
    colors: { type: 'FLOAT', count: 2, pointer: null },
    palettes: { type: 'FLOAT', count: 2, pointer: null },
    alphas: { type: 'FLOAT', count: 2, pointer: null }
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

  export let running = false

  $: {
    if (running) run()
  }

  function getTxPointArray () {
    return new Float32Array(txs.flatMap(tx => {
      return [
        tx.last - baseTime,
        tx.status === 'mempool' ? 0.0 : 1.0,
        tx.v,
        tx.from.x,
        tx.from.y,
        tx.to.x,
        tx.to.y,
        tx.from.r,
        tx.to.r,
        tx.from.c,
        tx.to.c,
        tx.from.p,
        tx.to.p,
        tx.from.a,
        tx.to.a,
      ]
    }))
  }

  function resizeCanvas () {
    var rect = canvas.parentNode.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height
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

  function run () {
    /* RESET DRAWING AREA */
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.clearColor(0.0, 0.0, 0.0, 0.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    /* LOAD VERTEX DATA */
    pointArray = getTxPointArray()
    const glBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer)
    if (pointArray.length) {
      gl.bufferData(gl.ARRAY_BUFFER, pointArray, gl.DYNAMIC_DRAW)
    }

    /* SET UP SHADER UNIFORMS */
    // screen dimensions
    gl.uniform2f(gl.getUniformLocation(shaderProgram, 'screenSize'), canvas.width, canvas.height)
    // frame timestamp
    const now = performance.now() - baseTime
    gl.uniform1f(gl.getUniformLocation(shaderProgram, 'now'), now)
    // gl.uniform1f(gl.getUniformLocation(shaderProgram, 'opacityTarget'), $darkMode ? 0.1 : 0.4)
    // Color mapping textures
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, colorTexture)
    gl.uniform1i(gl.getUniformLocation(shaderProgram, 'colorTexture'), 0);

    /* SET UP SHADER ATTRIBUTES */
    Object.keys(attribs).forEach((key, i) => {
      attribs[key].pointer = gl.getAttribLocation(shaderProgram, key)
      gl.enableVertexAttribArray(attribs[key].pointer);
      gl.vertexAttribPointer(attribs[key].pointer,
          attribs[key].count,  // number of primitives in this attribute
          gl[attribs[key].type],  // type of primitive in this attribute (e.g. gl.FLOAT)
          false, // never normalised
          stride,   // distance between values of the same attribute
          attribs[key].offset);  // offset of the first value
    })

    /* DRAW */
    gl.drawArrays(gl.POINTS, 0, pointArray.length / 3)

    /* LOOP */
    window.requestAnimationFrame(currentTime => {
      lastTime = currentTime
      if (running) run()
    })
  }

  // Creates a width x 1 pixel texture representing a colour gradient
  // and loads it into the webgl context
  // (used for precomputing a nice interpolation between rgb colours across HCL space)
  function loadColorTexture(gl, colorA, colorB, width) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);

    const interpolator = interpolateHcl(colorA, colorB)

    const colors = [...Array(width).keys()].flatMap(step => {
      let rgb = color(interpolator(step / width)).rgb()
      return [
        rgb.r,
        rgb.g,
        rgb.b,
        255
      ]
    })

    const level = 0;
    const internalFormat = gl.RGBA;
    const height = 1;
    const border = 0;
    const srcFormat = gl.RGBA;
    const srcType = gl.UNSIGNED_BYTE;
    const pixels = new Uint8Array(
      colors
    )

    gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                  width, height, border, srcFormat, srcType,
                  pixels);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

    return texture;
  }

  onMount(() => {
    resizeCanvas()
    gl = canvas.getContext('webgl')

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

    colorTexture = loadColorTexture(gl, '#f7941d', 'rgb(0%,100%,80%)', 500);

    running = true
  })

  function canvasClick (e) {
    let rect = canvas.getBoundingClientRect()
    let x = e.clientX - rect.left
    let y = e.clientY - rect.top
    dispatch('makeTx', { x, y })
  }
</script>

<style>
.tx-layer {
  position: absolute;
  left: 0;
  right: 0;
  top: -5px;
  bottom: 0;
  pointer-events: none;
  overflow: hidden;
}
</style>

<svelte:window on:resize={resizeCanvas} />

<canvas
  class="tx-layer"
  bind:this={canvas}
  on:click={canvasClick}
></canvas>
