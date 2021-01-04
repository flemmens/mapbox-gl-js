#ifdef GL_ES
precision highp float;
#endif

varying vec2 v_pos;

uniform sampler2D u_image;
uniform float u_zoom;

#define PI 3.141592653589793238462

float zenithRad = (90.0 - 45.0) * PI / 180.0;
float azimuthRad = radians(360.0 - 315.0 + 90.0);

float u_dimension = 260.0;

float getElevation(vec2 coord) {
    // Décodage de la valeur RGB et convertissage en mètres

    vec4 c = texture2D(u_image, coord);

    return ((
      c.r * 255.0 * 256.0 * 256.0 +
      c.g * 255.0 * 256.0 +
      c.b * 255.0 )
    -100000.0) / 10.0;

    // return -10000.0 + ((c.r * 256.0 * 256.0 + c.g * 256.0 + c.b) * 0.1);
}

void main() {

    float epsilon = 1.0 / u_dimension;

    float a = getElevation(v_pos + vec2(-epsilon, -epsilon));
    float b = getElevation(v_pos + vec2(0, -epsilon));
    float c = getElevation(v_pos + vec2(epsilon, -epsilon));
    float d = getElevation(v_pos + vec2(-epsilon, 0));
    float e = getElevation(v_pos);
    float f = getElevation(v_pos + vec2(epsilon, 0));
    float g = getElevation(v_pos + vec2(-epsilon, epsilon));
    float h = getElevation(v_pos + vec2(0, epsilon));
    float i = getElevation(v_pos + vec2(epsilon, epsilon));

    // Here we divide the x and y slopes by 8 * pixel size
    // where pixel size (aka meters/pixel) is:
    // circumference of the world / (pixels per tile * number of tiles)
    // which is equivalent to: 8 * 40075016.6855785 / (512 * pow(2, u_zoom))
    // which can be reduced to: pow(2, 19.25619978527 - u_zoom).
    // We want to vertically exaggerate the hillshading because otherwise
    // it is barely noticeable at low zooms. To do this, we multiply this by
    // a scale factor that is a function of zooms below 15, which is an arbitrary
    // that corresponds to the max zoom level of Mapbox terrain-RGB tiles.
    // See nickidlugash's awesome breakdown for more info:
    // https://github.com/mapbox/mapbox-gl-js/pull/5286#discussion_r148419556
/*
    float exaggerationFactor = u_zoom < 2.0 ? 0.4 : u_zoom < 4.5 ? 0.35 : 0.3;
    float exaggeration = u_zoom < 15.0 ? (u_zoom - 15.0) * exaggerationFactor : 0.0;
    float exag = pow(2.0, exaggeration + (19.25619978527 - u_zoom));
*/

    float exaggerationFactor = u_zoom < 2.0 ? 0.4 : u_zoom < 4.5 ? 0.35 : 0.3;
    float exaggeration = u_zoom < 15.0 ? (u_zoom - 15.0) * exaggerationFactor : 0.0;
    float exag = pow(2.0, exaggeration + (19.25619978527 - u_zoom));

    // exag = 8.0 * 40075016.6855785 / (512.0 * pow(2.0, u_zoom));
    exag = pow(2.0, ((u_zoom - 12.0) * exaggerationFactor) + (19.25619978527 - u_zoom));

    vec2 deriv = vec2(
        (c + f + f + i) - (a + d + d + g),
        (g + h + h + i) - (a + b + b + c)
    ) / exag;

    // on utilise rg pour stocker la valeur du slope et b pour l'élévation du pixel central
    vec4 store = vec4(deriv / 2.0 + 0.5, (e+11000.0)/20000.0, 1.0);

    gl_FragColor = store;







/*
    vec2 deriv2 = ((store.rg * 2.0) - 1.0);

//    gl_FragColor = clamp(vec4(deriv.x / 2.0 + 0.5, deriv.y / 2.0 + 0.5, 1.0, 1.0), 0.0, 1.0);

    gl_FragColor = vec4( (deriv+110000.0)/200000.0 , (e+11000.0)/20000.0, 1.0);


/*
//    gl_FragColor.rg = vec2(deriv / 2.0 + 0.5);
//    gl_FragColor = vec4(deriv.x, deriv.y, 0.0, 0.0);

    float slopeRad = atan(sqrt(pow(deriv2.x, 2.0) + pow(deriv2.y, 2.0)));


    // ATTENTION ! Redessine plusieurs fois une même tile si en cache => ne pas utiliser de transparent

    vec4 slope_col = vec4(1.0-slopeRad, 1.0-slopeRad, 1.0-slopeRad, 1.0);

    gl_FragColor = slope_col;
//    gl_FragColor = vec4(0.0, 0.0, 0.0, slopeRad);


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

    vec4 hill_col = vec4(hillshade, hillshade, hillshade, 1.0);


    // color ramp
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
  			smoothstep( colours[n].a, colours[n+1].a, e )
  		);
  	}
  	gl_FragColor = color;


  gl_FragColor = mix(hill_col, slope_col, 0.5);

// gl_FragColor = vec4(0.0,0.0,1.0,1.0); // test blue
// gl_FragColor = texture2D(u_image, v_pos);
gl_FragColor = slope_col;


float slopeRad = atan(sqrt(pow(deriv2.x, 2.0) + pow(deriv2.y, 2.0)));
vec4 slope_col = vec4(1.0-slopeRad, 1.0-slopeRad, 1.0-slopeRad, 1.0);
gl_FragColor = slope_col;
*/

#ifdef OVERDRAW_INSPECTOR
  gl_FragColor = vec4(1.0,0.0,0.0,1.0);
#endif
}
