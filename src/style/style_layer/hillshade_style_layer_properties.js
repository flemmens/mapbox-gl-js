// This file is generated. Edit build/generate-style-code.js, then run `yarn run codegen`.
// @flow
/* eslint-disable */

import styleSpec from '../../style-spec/reference/latest';

import {
    Properties,
    DataConstantProperty,
    DataDrivenProperty,
    CrossFadedDataDrivenProperty,
    CrossFadedProperty,
    ColorRampProperty
} from '../properties';

import type Color from '../../style-spec/util/color';

import type Formatted from '../../style-spec/expression/types/formatted';

import type ResolvedImage from '../../style-spec/expression/types/resolved_image';


export type PaintProps = {|
    "hillshade-illumination-direction": DataConstantProperty<number>,
    "hillshade-illumination-anchor": DataConstantProperty<"map" | "viewport">,
    "hillshade-exaggeration": DataConstantProperty<number>,
    "hillshade-test": DataConstantProperty<number>,
    "global-mixhillslope": DataConstantProperty<number>,
    "global-mixcolor": DataConstantProperty<number>,
    "hillshade-brightness": DataConstantProperty<number>,
    "hillshade-contrast": DataConstantProperty<number>,
    "hillshade-exposure": DataConstantProperty<number>,
    "hillshade-zfactor": DataConstantProperty<number>,
    "hillshade-azimuth": DataConstantProperty<number>,
    "hillshade-zenith": DataConstantProperty<number>,
    "hillshade-shadow-color": DataConstantProperty<Color>,
    "hillshade-highlight-color": DataConstantProperty<Color>,
    "hillshade-accent-color": DataConstantProperty<Color>,
|};

const paint: Properties<PaintProps> = new Properties({
    "hillshade-illumination-direction": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-illumination-direction"]),
    "hillshade-illumination-anchor": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-illumination-anchor"]),
    "hillshade-exaggeration": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-exaggeration"]),
    "hillshade-test": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-test"]),
    "global-mixhillslope": new DataConstantProperty(styleSpec["paint_hillshade"]["global-mixhillslope"]),
    "global-mixcolor": new DataConstantProperty(styleSpec["paint_hillshade"]["global-mixcolor"]),
    "hillshade-brightness": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-brightness"]),
    "hillshade-contrast": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-contrast"]),
    "hillshade-exposure": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-exposure"]),
    "hillshade-zfactor": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-zfactor"]),
    "hillshade-azimuth": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-azimuth"]),
    "hillshade-zenith": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-zenith"]),
    "hillshade-shadow-color": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-shadow-color"]),
    "hillshade-highlight-color": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-highlight-color"]),
    "hillshade-accent-color": new DataConstantProperty(styleSpec["paint_hillshade"]["hillshade-accent-color"]),
});

// Note: without adding the explicit type annotation, Flow infers weaker types
// for these objects from their use in the constructor to StyleLayer, as
// {layout?: Properties<...>, paint: Properties<...>}
export default ({ paint }: $Exact<{
  paint: Properties<PaintProps>
}>);
