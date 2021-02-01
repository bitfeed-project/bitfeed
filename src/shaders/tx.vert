// attribute vec2 aVertexPosition;
//
// uniform vec2 uScalingFactor;
// uniform lowp vec4 uGlobalColor;
//
varying lowp vec4 vColor;
//
// void main() {
//   gl_Position = vec4(aVertexPosition * uScalingFactor, 0.0, 1.0);
//   vColor = uGlobalColor;
// }
attribute vec2 spritePosition;  // position of sprite
attribute float spriteAge;
attribute float spriteMode;
uniform vec2 screenSize;        // width/height of screen
uniform float opacityTarget;        // target opacity for fading points
uniform sampler2D colorTexture;

void main() {
  vec4 screenTransform = vec4(2.0 / screenSize.x, -2.0 / screenSize.y, -1.0, 1.0);
  gl_Position = vec4(spritePosition * screenTransform.xy + screenTransform.zw, spriteAge < 400.0 ? 1.0 : 0.0, 1.0);
  if (spriteMode > 0.5) {
    if (spriteAge < 800.0) {
      gl_PointSize = spriteAge * 0.12 + 8.0;
      vColor = vec4(0.97, 0.58, 0.1, 1.0 - ((1.0 - pow(1.0 - (spriteAge * 0.00125), 3.0))));
    } else {
      gl_PointSize = 0.0;
      vColor = vec4(0.97, 0.58, 0.1, 0.0);
    }
  } else {
    if (spriteAge < 400.0) {
      gl_PointSize = 24.0 - (spriteAge * 0.04);
      vColor = vec4(0.97, 0.58, 0.1, (spriteAge * 0.0025));
    } else if (spriteAge < 5400.0) {
      gl_PointSize = 8.0;
      vec4 texel = texture2D(colorTexture, vec2((spriteAge - 400.0) * 0.0002, 0.0));
      vColor = vec4(texel.rgb, 1.0 - ((1.0 - opacityTarget) / 5000.0) * (spriteAge - 400.0));
    } else {
      gl_PointSize = 8.0;
      vColor = vec4(0.0, 1.0, 0.8, opacityTarget);
    }
  }

  // if (spriteMode > 0.5) {
  //   if (spriteAge < 400.0) {
  //     gl_PointSize = spriteAge * 0.06 + 8.0;
  //     vColor = vec4(0.97, 0.58, 0.1, 1.0 - (spriteAge * 0.0025));
  //   } else {
  //     gl_PointSize = 0.0;
  //     vColor = vec4(0.97, 0.58, 0.1, 0.0);
  //   }
  // } else {
  //   if (spriteAge < 400.0) {
  //     gl_PointSize = 16.0 + 24.0 - (spriteAge * 0.04);
  //     vColor = vec4(0.97, 0.58, 0.1, (spriteAge * 0.0025));
  //   } else if (spriteAge < 600.0) {
  //     gl_PointSize = 16.0 + 8.0;
  //     vColor = vec4(0.97 - (0.0045 * (spriteAge - 400.0)), 0.58 + (0.0021 * (spriteAge - 400.0)), 0.1 + (0.0035 * (spriteAge - 400.0)), 1.0);
  //   } else if (spriteAge < 5600.0) {
  //     gl_PointSize = 16.0 + 8.0;
  //     vColor = vec4(0.0, 1.0, (0.00016 * (spriteAge - 600.0)), 1.0 - (0.00004 * (spriteAge - 600.0)));
  //   } else {
  //     gl_PointSize = 16.0 + 8.0;
  //     vColor = vec4(0.0, 1.0, 0.8, 0.8);
  //   }
  // }
}
