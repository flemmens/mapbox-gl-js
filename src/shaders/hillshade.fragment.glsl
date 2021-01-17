#ifdef GL_ES
precision highp float;
#endif

varying vec2 v_pos;

uniform sampler2D u_image;
uniform float u_zoom;
uniform float u_test;

uniform float u_azimuth;
uniform float u_zenith;

uniform vec2 u_light;
uniform vec4 u_shadow;
uniform vec4 u_highlight;

uniform float u_zfactor;
uniform float u_brightness;
uniform float u_contrast;
uniform float u_exposure;

// global
uniform float u_mixhillslope;
uniform float u_mixcolor;


#define PI 3.141592653589793238462

float zenithRad = (90.0 - u_zenith) * PI / 180.0;
float azimuthRad = radians(360.0 - u_azimuth + 90.0);


// Fonctions d'ajustement

// vec4 adjustBrightness(vec4 color, float value) {
//   return vec4(color.rgb + value, color.a);
// }

// Shader

void main() {

  vec4 store = texture2D(u_image, v_pos);

  vec2  deriv  = ((store.rg - 0.5) * 2.0) * u_zfactor;
  float elev   = store.b * 20000.0 - 11000.0;


  // Slope
  float slopeRad = atan(sqrt(pow(deriv.x, 2.0) + pow(deriv.y, 2.0)));

  // Aspect
  float aspectRad = 9.0;  // rad will never be 9.0 so this means flat

  if (deriv.x != 0.0) {
    aspectRad = atan(deriv.y, -(deriv.x));
    if (aspectRad < 0.0)
      aspectRad = (2.0 * PI) + aspectRad;

  } else if (deriv.y > 0.0)
    aspectRad = PI / 2.0;

  else if (deriv.y < 0.0)
    aspectRad = (2.0 * PI) - (PI / 2.0);


  // Hillshade
  float hillshade = (cos(zenithRad) * cos(slopeRad)) + (sin(zenithRad) * sin(slopeRad) * cos(azimuthRad - aspectRad));


  // Color ramp (ne calculer que si affiché)
  vec4 colours[5];
  colours[0] = vec4(0.1,  0.1, 0.5, 0.0);
  colours[1] = vec4(0.4, 0.55, 0.3, 1.0);
  colours[2] = vec4(0.9,  0.9, 0.6, 500.0);
  colours[3] = vec4(0.6,  0.4, 0.3, 2000.0);
  colours[4] = vec4(1.0,  1.0, 1.0, 4000.0);

  vec4 color = vec4(colours[0].rgb, 1.0);

  for (int n=0; n<5; n++) {
    color.rgb = mix(
      color.rgb,
      colours[n+1].rgb,
      smoothstep( colours[n].a, colours[n+1].a, elev )
    );
  }


  // Valeurs finales

  slopeRad = 1.0-slopeRad;

  // Light/shadow

  // Brightness (-1 to 1)
  hillshade = hillshade + u_brightness;

  // Contrast (-1 to 1)
  hillshade = 0.5 + (1.0 + u_contrast) * (hillshade - 0.5);

  // Exposure (-1 to 1)
  hillshade = (1.0 + u_exposure) * hillshade;

  vec4 slope_col = vec4(slopeRad, slopeRad, slopeRad, 1.0);
  vec4 hill_col  = vec4(hillshade, hillshade, hillshade, 1.0);

//  gl_FragColor = hill_col;
//  gl_FragColor = slope_col;
// color = color + (u_test*2.0)-1.0;
//  gl_FragColor = color;

  // Mixage

  // hillshade / slope
  vec4 mixHillSlope = mix(hill_col, slope_col, u_mixhillslope);

  // colors
  vec4 mixColor = mixHillSlope * color;   // multiply transition


  // Rendu final

  gl_FragColor = mix(mixHillSlope, mixColor, u_mixcolor);
  // gl_FragColor = texture2D(u_image, v_pos);

}
