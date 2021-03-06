// @flow

import {mat4} from 'gl-matrix';

import {
    Uniform1i,
    Uniform1f,
    Uniform2f,
    UniformColor,
    UniformMatrix4f,
    Uniform4f,
    UniformArray4f
} from '../uniform_binding';
import EXTENT from '../../data/extent';
import MercatorCoordinate from '../../geo/mercator_coordinate';

import type Context from '../../gl/context';
import type {UniformValues, UniformLocations} from '../uniform_binding';
import type Tile from '../../source/tile';
import type Painter from '../painter';
import type HillshadeStyleLayer from '../../style/style_layer/hillshade_style_layer';
import type {OverscaledTileID} from '../../source/tile_id';

export type HillshadeUniformsType = {|
    'u_matrix': UniformMatrix4f,
    'u_image': Uniform1i,
    'u_latrange': Uniform2f,
    'u_light': Uniform2f,
    'u_shadow': UniformColor,
    'u_highlight': UniformColor,
    'u_accent': UniformColor,
    'u_zoom': Uniform1f,
    'u_test': Uniform1f,
    'u_azimuth': Uniform1f,
    'u_zenith': Uniform1f,
    'u_brightness': Uniform1f,
    'u_contrast': Uniform1f,
    'u_exposure': Uniform1f,
    'u_zfactor': Uniform1f,
    'u_op_hillshade': Uniform1f,
    'u_op_slope': Uniform1f,
    'u_op_color': Uniform1f,
    'u_glob_brightness': Uniform1f,
    'u_glob_contrast': Uniform1f,
    'u_glob_exposure': Uniform1f,
    'u_glob_ramp': UniformArray4f
|};

export type HillshadePrepareUniformsType = {|
    'u_matrix': UniformMatrix4f,
    'u_image': Uniform1i,
    'u_zoom': Uniform1f
|};

const hillshadeUniforms = (context: Context, locations: UniformLocations): HillshadeUniformsType => ({
    'u_matrix': new UniformMatrix4f(context, locations.u_matrix),
    'u_image': new Uniform1i(context, locations.u_image),
    'u_latrange': new Uniform2f(context, locations.u_latrange),
    'u_light': new Uniform2f(context, locations.u_light),
    'u_shadow': new UniformColor(context, locations.u_shadow),
    'u_highlight': new UniformColor(context, locations.u_highlight),
    'u_accent': new UniformColor(context, locations.u_accent),
    'u_zoom': new Uniform1f(context, locations.u_zoom),
    'u_test': new Uniform1f(context, locations.u_test),
    'u_azimuth': new Uniform1f(context, locations.u_azimuth),
    'u_zenith': new Uniform1f(context, locations.u_zenith),
    'u_brightness': new Uniform1f(context, locations.u_brightness),
    'u_contrast': new Uniform1f(context, locations.u_contrast),
    'u_exposure': new Uniform1f(context, locations.u_exposure),
    'u_zfactor': new Uniform1f(context, locations.u_zfactor),
    'u_op_hillshade': new Uniform1f(context, locations.u_op_hillshade),
    'u_op_slope': new Uniform1f(context, locations.u_op_slope),
    'u_op_color': new Uniform1f(context, locations.u_op_color),
    'u_glob_brightness': new Uniform1f(context, locations.u_glob_brightness),
    'u_glob_contrast': new Uniform1f(context, locations.u_glob_contrast),
    'u_glob_exposure': new Uniform1f(context, locations.u_glob_exposure),
    'u_glob_ramp': new UniformArray4f(context, locations.u_glob_ramp)
});

const hillshadePrepareUniforms = (context: Context, locations: UniformLocations): HillshadePrepareUniformsType => ({
    'u_matrix': new UniformMatrix4f(context, locations.u_matrix),
    'u_image': new Uniform1i(context, locations.u_image),
    'u_zoom': new Uniform1f(context, locations.u_zoom)
});

// Render

// Passe ici des milliers de fois par seconde
// -> A OPTIMISER: Ne pas faire de calculs, tester s'il y a eu du changement, passer le min de variables

console.log('Init render')

var glob_ramp = [0.1, 0.1, 0.5, -5000.0, 0.607, 0.937, 0.949, 0.0, 0.4, 0.55, 0.3, 1.0, 0.9,  0.9, 0.6, 300.0, 0.6,  0.4, 0.3, 2000.0,1.0,  1.0, 1.0, 4000.0, 1.0, 1.0, 1.0, 20000.0];


const hillshadeUniformValues = (
    painter: Painter,
    tile: Tile,
    layer: HillshadeStyleLayer
): UniformValues<HillshadeUniformsType> => {
    const shadow     = layer.paint.get("hillshade-shadow-color");
    const highlight  = layer.paint.get("hillshade-highlight-color");
    const accent     = layer.paint.get("hillshade-accent-color");
    const test       = layer.paint.get('hillshade-test');
    const azimuth    = layer.paint.get('hillshade-azimuth');
    const zenith     = layer.paint.get('hillshade-zenith');
    const brightness = layer.paint.get('hillshade-brightness');
    const contrast   = layer.paint.get('hillshade-contrast');
    const exposure   = layer.paint.get('hillshade-exposure');
    const zfactor    = layer.paint.get('hillshade-zfactor');

    const op_hillshade = layer.paint.get('layers-opacityHillshade');
    const op_slope     = layer.paint.get('layers-opacitySlope');
    const op_color     = layer.paint.get('layers-opacityColors');

    const glob_brightness = layer.paint.get('global-brightness');
    const glob_contrast   = layer.paint.get('global-contrast');
    const glob_exposure   = layer.paint.get('global-exposure');

    glob_ramp = layer.paint.get('global-ramp');
    if (glob_ramp === undefined)
      glob_ramp = [0.1, 0.1, 0.5, -5000.0, 0.607, 0.937, 0.949, 0.0, 0.4, 0.55, 0.3, 1.0, 0.9,  0.9, 0.6, 300.0, 0.6,  0.4, 0.3, 2000.0,1.0,  1.0, 1.0, 4000.0, 1.0, 1.0, 1.0, 20000.0];

// console.log(glob_ramp);
// console.log('zoom: '+tile.tileID.overscaledZ+', test: '+test);

    // let azimuthal = layer.paint.get('hillshade-illumination-direction') * (Math.PI / 180);
    // modify azimuthal angle by map rotation if light is anchored at the viewport
    // if (layer.paint.get('hillshade-illumination-anchor') === 'viewport') {
    //     azimuthal -= painter.transform.angle;
    // }
    // 'u_light': [layer.paint.get('hillshade-exaggeration'), azimuthal],
    const align = !painter.options.moving;

    return {
        'u_matrix': painter.transform.calculatePosMatrix(tile.tileID.toUnwrapped(), align),
        'u_image': 0,
        'u_latrange': getTileLatRange(painter, tile.tileID),
        'u_light': 0,
        'u_shadow': shadow,
        'u_highlight': highlight,
        'u_accent': accent,
        'u_zoom': tile.tileID.overscaledZ,
        'u_test': test,
        'u_azimuth': azimuth,
        'u_zenith': zenith,
        'u_brightness': brightness,
        'u_contrast': contrast,
        'u_exposure': exposure,
        'u_zfactor': zfactor,
        'u_op_hillshade': op_hillshade,
        'u_op_slope': op_slope,
        'u_op_color': op_color,
        'u_glob_brightness': glob_brightness,
        'u_glob_contrast': glob_contrast,
        'u_glob_exposure': glob_exposure,
        'u_glob_ramp': glob_ramp
    };
};

// Prepare
// Passe moins souvent que hillshadeUniformValues mais qd même conséquent

const hillshadeUniformPrepareValues = (
    tileID: OverscaledTileID
): UniformValues<HillshadePrepareUniformsType> => {

    const matrix = mat4.create();

    // Flip rendering at y axis.
    mat4.ortho(matrix, 0, EXTENT, -EXTENT, 0, 0, 1);
    mat4.translate(matrix, matrix, [0, -EXTENT, 0]);
// console.log('zoom (prepare): '+tileID.overscaledZ);
// console.log('prepare')

    return {
        'u_matrix': matrix,
        'u_image': 1,
        'u_zoom': tileID.overscaledZ
    };
};

function getTileLatRange(painter: Painter, tileID: OverscaledTileID) {
    // for scaling the magnitude of a points slope by its latitude
    const tilesAtZoom = Math.pow(2, tileID.canonical.z);
    const y = tileID.canonical.y;
    return [
        new MercatorCoordinate(0, y / tilesAtZoom).toLngLat().lat,
        new MercatorCoordinate(0, (y + 1) / tilesAtZoom).toLngLat().lat];
}

export {
    hillshadeUniforms,
    hillshadePrepareUniforms,
    hillshadeUniformValues,
    hillshadeUniformPrepareValues
};
