#ifdef GL_ES
precision highp float;
#endif

varying vec2 v_pos;

uniform sampler2D u_image;
uniform float u_zoom;
uniform float u_test;

#define PI 3.141592653589793238462

float zenithRad = (90.0 - 45.0) * PI / 180.0;
float azimuthRad = radians(360.0 - 315.0 + 90.0);


void main() {

  vec4 store = texture2D(u_image, v_pos);

  vec2  deriv  = (store.rg - 0.5) * 2.0;
  vec2  deriv2 = ((store.rg * 2.0) - 1.0);
  float elev   = store.b * 20000.0 - 11000.0;


  // Slope
  float slopeRad = atan(sqrt(pow(deriv2.x, 2.0) + pow(deriv2.y, 2.0)));

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


  // Color ramp
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

  vec4 slope_col = vec4(1.0-slopeRad, 1.0-slopeRad, 1.0-slopeRad, 1.0);
  vec4 hill_col  = vec4(hillshade, hillshade, hillshade, 1.0);

//  gl_FragColor = hill_col;
//  gl_FragColor = slope_col;
//  gl_FragColor = color;
    gl_FragColor = mix(hill_col, slope_col, u_test);


//   gl_FragColor = texture2D(u_image, v_pos);

}
