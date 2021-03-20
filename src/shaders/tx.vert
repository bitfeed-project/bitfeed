varying lowp vec4 vColor;

// each attribute contains [x: startValue, y: endValue, z: startTime, w: rate]
// shader interpolates between start and end values at the given rate, from the given time
attribute vec4 posX;
attribute vec4 posY;
attribute vec4 colors;
attribute vec4 palettes;
attribute vec4 alphas;

uniform vec2 screenSize;
uniform float now;
uniform sampler2D colorTexture;

vec3 selectPalette(float index) {
  if (index < 2.0) {
    return vec3(0.97, 0.58, 0.1);
  } else {
    // return vec3(0.0, 1.0, 0.8);
    return vec3(0.0, 1.0, 0.0);
  }
}

float interpolateAttribute(vec4 attr) {
  float delta = clamp((now - attr.z) * attr.w, 0.0, 1.0);
  return mix(attr.x, attr.y, delta);
}

void main() {
  vec4 screenTransform = vec4(2.0 / screenSize.x, 2.0 / screenSize.y, -1.0, -1.0);
  // vec4 screenTransform = vec4(1.0 / screenSize.x, 1.0 / screenSize.y, -0.5, -0.0);

  vec2 position = vec2(interpolateAttribute(posX), interpolateAttribute(posY));
  gl_Position = vec4(position * screenTransform.xy + screenTransform.zw, 1.0, 1.0);

  float colorIndex = interpolateAttribute(colors);
  float alpha = interpolateAttribute(alphas);
  if (palettes.y < 1.0) { // texture color
    vec4 texel = texture2D(colorTexture, vec2(colorIndex, 0.0));
    vColor = vec4(texel.rgb, alpha);
  } else { // preset color
    vec3 startColor = selectPalette(palettes.x);
    vec3 endColor = selectPalette(palettes.y);
    vec3 color = mix(startColor, endColor, colorIndex);
    vColor = vec4(color, alpha);
  }
}
