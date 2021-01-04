#ifdef GL_ES
precision highp float;
#endif

uniform float u_fade_t;
uniform float u_opacity;
uniform sampler2D u_image0;
uniform sampler2D u_image1;
varying vec2 v_pos0;
varying vec2 v_pos1;

uniform float u_brightness_low;
uniform float u_brightness_high;

uniform float u_saturation_factor;
uniform float u_contrast_factor;
uniform vec3 u_spin_weights;

uniform float u_zoom;
uniform vec2 u_dimension;

// uniform vec4 u_unpack;
float height(vec2 p) {
  vec4 c = texture2D(u_image0, p);

  return ((
    c.r * 255.0 * 256.0 * 256.0 +
    c.g * 255.0 * 256.0 +
    c.b * 255.0 )
  -100000.0) / 10.0;
}

void main() {

/*
    // read and cross-fade colors from the main and parent tiles
    vec4 color0 = texture2D(u_image0, v_pos0);
    vec4 color1 = texture2D(u_image1, v_pos1);
    if (color0.a > 0.0) {
        color0.rgb = color0.rgb / color0.a;
    }
    if (color1.a > 0.0) {
        color1.rgb = color1.rgb / color1.a;
    }
    vec4 color = mix(color0, color1, u_fade_t);
    color.a *= u_opacity;
    vec3 rgb = color.rgb;

    // spin
    rgb = vec3(
        dot(rgb, u_spin_weights.xyz),
        dot(rgb, u_spin_weights.zxy),
        dot(rgb, u_spin_weights.yzx));

    // saturation
    float average = (color.r + color.g + color.b) / 3.0;
    rgb += (average - rgb) * u_saturation_factor;

    // contrast
    rgb = (rgb - 0.5) * u_contrast_factor + 0.5;

    // brightness
    vec3 u_high_vec = vec3(u_brightness_low, u_brightness_low, u_brightness_low);
    vec3 u_low_vec = vec3(u_brightness_high, u_brightness_high, u_brightness_high);

//    gl_FragColor = vec4(mix(u_high_vec, u_low_vec, rgb) * color.a, color.a);
//    gl_FragColor = vec4(1.0,0.0,0.0,1.0);
*/

  float exaggerationFactor = u_zoom < 2.0 ? 0.4 : u_zoom < 4.5 ? 0.35 : 0.3;
  float exaggeration = u_zoom < 15.0 ? (u_zoom - 15.0) * exaggerationFactor : 0.0;

  float zFactor  = 1.0;
  float uCellSize = pow(2.0, exaggeration + (20.0 - u_zoom));

  float uZenithDeg = 45.0;
  float uAzimuthDeg = 315.0;

  float slopeCoef = 0.7;
  float hillCoef  = 0.8;

  const float PI = 2.0 * asin(1.0);
  float azimuth = uAzimuthDeg;
  float zenithRad = (90.0 - uZenithDeg) * PI / 180.0;
  float azimuthRad = radians(360.0 - azimuth + 90.0);

  float a,b,c,d,e,f,g,h,i;

  // calculer en fonction du zoom et de la taille du canvas
  // vec2 m = 1.0 / vec2(256.0, 256.0);
  vec2 m = 1.0 / vec2(20.0, 20.0);

  // elev matrix
  a = height(v_pos0 + vec2(-m.x, -m.y));
  b = height(v_pos0 + vec2(0, -m.y));
  c = height(v_pos0 + vec2(m.x, -m.y));
  d = height(v_pos0 + vec2(-m.x, 0));
  e = height(v_pos0);
  f = height(v_pos0 + vec2(m.x, 0));
  g = height(v_pos0 + vec2(-m.x, m.y));
  h = height(v_pos0 + vec2(0, m.y));
  i = height(v_pos0 + vec2(m.x, m.y));

  float rateOfChangeX = ((c + (2.0*f) + i) - (a + (2.0*d) + g)) / uCellSize;
  float rateOfChangeY = ((g + (2.0*h) + i) - (a + (2.0*b) + c)) / uCellSize;

  // Slope
  float slopeRad = atan(zFactor * sqrt(pow(rateOfChangeX, 2.0) + pow(rateOfChangeY, 2.0)));

  // Aspect
  float aspectRad = 9.0;
  if (rateOfChangeX != 0.0) {
    aspectRad = atan(rateOfChangeY, -(rateOfChangeX));
    if (aspectRad < 0.0) aspectRad = (2.0 * PI) + aspectRad;
  } else if (rateOfChangeY > 0.0)
    aspectRad = PI / 2.0;
  else if (rateOfChangeY < 0.0)
    aspectRad = (2.0 * PI) - (PI / 2.0);

  // Hillshade
  float hillshade = (cos(zenithRad) * cos(slopeRad)) + (sin(zenithRad) * sin(slopeRad) * cos(azimuthRad - aspectRad));


  // Valeurs finales

  float slope_val = slopeRad * slopeCoef;
  float hill_val  = (1.0 - hillshade) * hillCoef;


  // color ramp
  vec4 colours[5];
  colours[0] = vec4(0.1,  0.1, 0.5, 0.0);
  colours[1] = vec4(0.4, 0.55, 0.3, 1.0);
  colours[2] = vec4(0.9,  0.9, 0.6, 500.0);
  colours[3] = vec4(0.6,  0.4, 0.3, 2000.0);
  colours[4] = vec4(1.0,  1.0, 1.0, 4000.0);

  vec4 color = vec4(colours[0].rgb, 1.0);

	for (int n=0; n<4; n++) {
		color.rgb = mix(
			color.rgb,
			colours[n+1].rgb,
			smoothstep( colours[n].a, colours[n+1].a, height(v_pos0) )
		);
	}
	gl_FragColor = color;
  gl_FragColor = mix(color, vec4(0.0, 0.0, 0.0, hill_val), 0.2);

  gl_FragColor = mix(gl_FragColor, vec4(0.0, 0.0, 0.0, slope_val), u_contrast_factor);

  gl_FragColor = vec4(0.0, 0.0, 0.0, slope_val);
//  gl_FragColor = vec4(0.0, 0.0, 0.0, hill_val);

// gl_FragColor = color; // couleur de la rampe

gl_FragColor = texture2D(u_image0, v_pos0); // couleur d'origine


#ifdef OVERDRAW_INSPECTOR
    gl_FragColor = vec4(1.0);
#endif
}
