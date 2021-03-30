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
  } else if (index < 3.0) {
    // return vec3(0.0, 1.0, 0.8);
    return vec3(0.0, 1.0, 0.0);
  } else {
    return vec3(1.0, 0.078, 0.576);
  }
}

vec3 getColor(float palette, float index) {
  if (palette <= 1.0) {
    vec4 texel = texture2D(colorTexture, vec2(index, 0.0));
    return texel.rgb;
  } else if (palette <= 2.0) {
    return vec3(0.97, 0.58, 0.1);
  } else if (palette <= 3.0) {
    // return vec3(0.0, 1.0, 0.8);
    return vec3(0.0, 1.0, 0.0);
  } else {
    return vec3(1.0, 0.078, 0.576);
  }
}

float interpolateAttribute(vec4 attr) {
  float delta = clamp((now - attr.z) * attr.w, 0.0, 1.0);
  return mix(attr.x, attr.y, delta);
}

void main() {
  vec4 screenTransform = vec4(2.0 / screenSize.x, 2.0 / screenSize.y, -1.0, -1.0);
  // vec4 screenTransform = vec4(1.0 / screenSize.x, 1.0 / screenSize.y, -0.5, -0.5);

  vec2 position = vec2(interpolateAttribute(posX), interpolateAttribute(posY));
  gl_Position = vec4(position * screenTransform.xy + screenTransform.zw, 1.0, 1.0);

  float colorIndex = interpolateAttribute(colors);
  float alpha = interpolateAttribute(alphas);

  if (palettes.y < 1.0 && palettes.x < 1.0) { // start and end in same texture, so interpolate along texture scale
    vec4 texel = texture2D(colorTexture, vec2(colorIndex, 0.0));
    vColor = vec4(texel.rgb, alpha);
  } else { // one or more preset colors, so interpolate rgb directly
    vec3 startColor = getColor(palettes.x, colors.x);
    vec3 endColor = getColor(palettes.y, colors.y);

    float delta = clamp((now - palettes.z) * palettes.w, 0.0, 1.0);
    vec3 color = mix(startColor, endColor, delta);

    vColor = vec4(color, alpha);
  }
}
