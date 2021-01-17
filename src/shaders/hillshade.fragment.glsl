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

// layers
uniform float u_op_hillshade;
uniform float u_op_slope;
uniform float u_op_color;

// global
uniform float u_glob_exposure;
uniform float u_glob_contrast;
uniform float u_glob_brightness;

// ramp
uniform vec4 u_glob_ramp[99];

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

/*
  vec4 colours[99];
  vec3 color = colours[0].rgb;

  for (int n=0; n<5; n++) {
    color = mix(
      color,
      colours[n+1].rgb,
      smoothstep( colours[n].a, colours[n+1].a, elev )
    );
  }
*/

  float elev_start = -11000.0;
  float elev_end = elev_start;

  vec3 colorA = u_glob_ramp[0].rgb;
  vec3 colorB = colorA;

  for(int n=0; n<99; n++) {
    elev_end = u_glob_ramp[n].a;
    colorB = u_glob_ramp[n].rgb;

    if (elev_end > elev)          // Attention, on ne vérifie pas la validité du tableau, doit être fait avant !
      break;
    else {
      elev_start = elev_end;
      colorA = colorB;
    }
  }

  float m = (elev - elev_start) / (elev_end - elev_start);
  vec3 color = mix(colorA, colorB, m);


  // Valeurs finales

  slopeRad = 1.0-slopeRad;

  // Light/shadow

  // Brightness (-1 to 1)
  hillshade = hillshade + u_brightness;

  // Contrast (-1 to 1)
  hillshade = 0.5 + (1.0 + u_contrast) * (hillshade - 0.5);

  // Exposure (-1 to 1)
  hillshade = (1.0 + u_exposure) * hillshade;



  // Opacity hillshade / slope

  vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
  vec4 slope_col = vec4(slopeRad, slopeRad, slopeRad, 1.0);
  vec4 hill_col  = vec4(hillshade, hillshade, hillshade, 1.0);

  float a = mix(1.0, slopeRad, u_op_slope);
  float b = mix(1.0, hillshade, u_op_hillshade);
  float c = a*b;
  vec3 comb = vec3(c,c,c);

  // colors
  vec3 mixColor = comb * color;   // multiply transition
  vec3 final = mix(comb, mixColor, u_op_color);
  // vec3 final = mix(comb, color, u_op_color);

  // Global adjustements

  // Brightness (-1 to 1)
  final = final + u_glob_brightness;

  // Contrast (-1 to 1)
  final = 0.5 + (1.0 + u_glob_contrast) * (final - 0.5);

  // Exposure (-1 to 1)
  final = (1.0 + u_glob_exposure) * final;


  // Rendu final

  gl_FragColor = vec4(final, 1.0);
  // gl_FragColor = texture2D(u_image, v_pos);

}
