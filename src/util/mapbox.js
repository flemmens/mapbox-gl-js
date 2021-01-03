// @flow

import config from './config';

import browser from './browser';
import window from './window';
import webpSupported from './webp_supported';
import {createSkuToken, SKU_ID} from './sku_token';
import {version as sdkVersion} from '../../package.json';
import {uuid, validateUuid, storageAvailable, b64DecodeUnicode, b64EncodeUnicode, warnOnce, extend} from './util';
import {postData, ResourceType} from './ajax';

import type {RequestParameters} from './ajax';
import type {Cancelable} from '../types/cancelable';
import type {TileJSON} from '../types/tilejson';

type ResourceTypeEnum = $Keys<typeof ResourceType>;
export type RequestTransformFunction = (url: string, resourceType?: ResourceTypeEnum) => RequestParameters;

type UrlObject = {|
    protocol: string,
    authority: string,
    path: string,
    params: Array<string>
|};

export class RequestManager {
    _skuToken: string;
    _skuTokenExpiresAt: number;
    _transformRequestFn: ?RequestTransformFunction;

    constructor(transformRequestFn?: RequestTransformFunction) {
        this._transformRequestFn = transformRequestFn;
        this._createSkuToken();
    }

    _createSkuToken() {
        const skuToken = createSkuToken();
        this._skuToken = skuToken.token;
        this._skuTokenExpiresAt = skuToken.tokenExpiresAt;
    }

    _isSkuTokenExpired(): boolean {
        return Date.now() > this._skuTokenExpiresAt;
    }

    transformRequest(url: string, type: ResourceTypeEnum) {
        if (this._transformRequestFn) {
            return this._transformRequestFn(url, type) || {url};
        }

        return {url};
    }

    normalizeSpriteURL(url: string, format: string, extension: string, accessToken?: string): string {
console.log('1. sprite:'+url)
        const urlObject = parseUrl(url);
        if (!isMapboxURL(url)) {
            urlObject.path += `${format}${extension}`;
            return formatUrl(urlObject);
        }
        urlObject.path = `/styles/v1${urlObject.path}/sprite${format}${extension}`;
console.log('2. sprite:'+this._makeAPIURL(urlObject, accessToken))
        return this._makeAPIURL(urlObject, accessToken);
    }

    _makeAPIURL(urlObject: UrlObject, accessToken: string | null | void): string {
        const help = 'See https://www.mapbox.com/api-documentation/#access-tokens-and-token-scopes';
        const apiUrlObject = parseUrl(config.API_URL);
        urlObject.protocol = apiUrlObject.protocol;
        urlObject.authority = apiUrlObject.authority;

        if (apiUrlObject.path !== '/') {
            urlObject.path = `${apiUrlObject.path}${urlObject.path}`;
        }

        if (!config.REQUIRE_ACCESS_TOKEN) return formatUrl(urlObject);

        accessToken = accessToken || config.ACCESS_TOKEN;
/*
        if (!accessToken)
            throw new Error(`An API access token is required to use Mapbox GL. ${help}`);
        if (accessToken[0] === 's')
            throw new Error(`Use a public access token (pk.*) with Mapbox GL, not a secret access token (sk.*). ${help}`);
*/
        urlObject.params = urlObject.params.filter((d) => d.indexOf('access_token') === -1);
        urlObject.params.push(`access_token=${accessToken}`);

        return formatUrl(urlObject);
    }
}

function isMapboxURL(url: string) {
    return url.indexOf('mapbox:') === 0;
}

function getAccessToken(params: Array<string>): string | null {
    for (const param of params) {
        const match = param.match(/^access_token=(.*)$/);
        if (match) {
            return match[1];
        }
    }
    return null;
}

const urlRe = /^(\w+):\/\/([^/?]*)(\/[^?]+)?\??(.+)?/;

function parseUrl(url: string): UrlObject {
    const parts = url.match(urlRe);
    if (!parts) {
        throw new Error('Unable to parse URL object');
    }
    return {
        protocol: parts[1],
        authority: parts[2],
        path: parts[3] || '/',
        params: parts[4] ? parts[4].split('&') : []
    };
}

function formatUrl(obj: UrlObject): string {
    const params = obj.params.length ? `?${obj.params.join('&')}` : '';
    return `${obj.protocol}://${obj.authority}${obj.path}${params}`;
}

const telemEventKey = 'mapbox.eventData';

function parseAccessToken(accessToken: ?string) {
    if (!accessToken) {
        return null;
    }

    const parts = accessToken.split('.');
    if (!parts || parts.length !== 3) {
        return null;
    }

    try {
        const jsonData = JSON.parse(b64DecodeUnicode(parts[1]));
        return jsonData;
    } catch (e) {
        return null;
    }
}

type TelemetryEventType = 'appUserTurnstile' | 'map.load';

class TelemetryEvent {
    eventData: any;
    anonId: ?string;
    queue: Array<any>;
    type: TelemetryEventType;
    pendingRequest: ?Cancelable;
    _customAccessToken: ?string;

    constructor(type: TelemetryEventType) {
        this.type = type;
        this.anonId = null;
        this.eventData = {};
        this.queue = [];
        this.pendingRequest = null;
    }

    getStorageKey(domain: ?string) {
        const tokenData = parseAccessToken(config.ACCESS_TOKEN);
        let u = '';
        if (tokenData && tokenData['u']) {
            u = b64EncodeUnicode(tokenData['u']);
        } else {
            u = config.ACCESS_TOKEN || '';
        }
        return domain ?
            `${telemEventKey}.${domain}:${u}` :
            `${telemEventKey}:${u}`;
    }

    fetchEventData() {
        const isLocalStorageAvailable = storageAvailable('localStorage');
        const storageKey = this.getStorageKey();
        const uuidKey = this.getStorageKey('uuid');

        if (isLocalStorageAvailable) {
            //Retrieve cached data
            try {
                const data = window.localStorage.getItem(storageKey);
                if (data) {
                    this.eventData = JSON.parse(data);
                }

                const uuid = window.localStorage.getItem(uuidKey);
                if (uuid) this.anonId = uuid;
            } catch (e) {
                warnOnce('Unable to read from LocalStorage');
            }
        }
    }

    saveEventData() {
        const isLocalStorageAvailable = storageAvailable('localStorage');
        const storageKey =  this.getStorageKey();
        const uuidKey = this.getStorageKey('uuid');
        if (isLocalStorageAvailable) {
            try {
                window.localStorage.setItem(uuidKey, this.anonId);
                if (Object.keys(this.eventData).length >= 1) {
                    window.localStorage.setItem(storageKey, JSON.stringify(this.eventData));
                }
            } catch (e) {
                warnOnce('Unable to write to LocalStorage');
            }
        }

    }

    processRequests(_: ?string) {}

    /*
    * If any event data should be persisted after the POST request, the callback should modify eventData`
    * to the values that should be saved. For this reason, the callback should be invoked prior to the call
    * to TelemetryEvent#saveData
    */
    postEvent(timestamp: number, additionalPayload: {[_: string]: any}, callback: (err: ?Error) => void, customAccessToken?: ?string) {
        if (!config.EVENTS_URL) return;
        const eventsUrlObject: UrlObject = parseUrl(config.EVENTS_URL);
        eventsUrlObject.params.push(`access_token=${customAccessToken || config.ACCESS_TOKEN || ''}`);

        const payload: Object = {
            event: this.type,
            created: new Date(timestamp).toISOString(),
            sdkIdentifier: 'mapbox-gl-js',
            sdkVersion,
            skuId: SKU_ID,
            userId: this.anonId
        };

        const finalPayload = additionalPayload ? extend(payload, additionalPayload) : payload;
        const request: RequestParameters = {
            url: formatUrl(eventsUrlObject),
            headers: {
                'Content-Type': 'text/plain' //Skip the pre-flight OPTIONS request
            },
            body: JSON.stringify([finalPayload])
        };

        this.pendingRequest = postData(request, (error) => {
            this.pendingRequest = null;
            callback(error);
            this.saveEventData();
            this.processRequests(customAccessToken);
        });
    }

    queueRequest(event: number | {id: number, timestamp: number}, customAccessToken?: ?string) {
        this.queue.push(event);
        this.processRequests(customAccessToken);
    }
}

export class MapLoadEvent extends TelemetryEvent {
    +success: {[_: number]: boolean};
    skuToken: string;

    constructor() {
        super('map.load');
        this.success = {};
        this.skuToken = '';
    }

    postMapLoadEvent(tileUrls: Array<string>, mapId: number, skuToken: string, customAccessToken: string) {
        //Enabled only when Mapbox Access Token is set and a source uses
        // mapbox tiles.
        this.skuToken = skuToken;

        if (config.EVENTS_URL &&
            customAccessToken || config.ACCESS_TOKEN &&
            Array.isArray(tileUrls) &&
            tileUrls.some(url => isMapboxURL(url))) {
            this.queueRequest({id: mapId, timestamp: Date.now()}, customAccessToken);
        }
    }

    processRequests(customAccessToken?: ?string) {
        if (this.pendingRequest || this.queue.length === 0) return;
        const {id, timestamp} = this.queue.shift();

        // Only one load event should fire per map
        if (id && this.success[id]) return;

        if (!this.anonId) {
            this.fetchEventData();
        }

        if (!validateUuid(this.anonId)) {
            this.anonId = uuid();
        }

        this.postEvent(timestamp, {skuToken: this.skuToken}, (err) => {
            if (!err) {
                if (id) this.success[id] = true;
            }
        }, customAccessToken);
    }
}

export class TurnstileEvent extends TelemetryEvent {
    constructor(customAccessToken?: ?string) {
        super('appUserTurnstile');
        this._customAccessToken = customAccessToken;
    }

    postTurnstileEvent(tileUrls: Array<string>, customAccessToken?: ?string) {
        //Enabled only when Mapbox Access Token is set and a source uses
        // mapbox tiles.
        if (config.EVENTS_URL &&
            config.ACCESS_TOKEN &&
            Array.isArray(tileUrls) &&
            tileUrls.some(url => isMapboxURL(url))) {
            this.queueRequest(Date.now(), customAccessToken);
        }
    }

    processRequests(customAccessToken?: ?string) {
        if (this.pendingRequest || this.queue.length === 0) {
            return;
        }

        if (!this.anonId || !this.eventData.lastSuccess || !this.eventData.tokenU) {
            //Retrieve cached data
            this.fetchEventData();
        }

        const tokenData = parseAccessToken(config.ACCESS_TOKEN);
        const tokenU = tokenData ? tokenData['u'] : config.ACCESS_TOKEN;
        //Reset event data cache if the access token owner changed.
        let dueForEvent = tokenU !== this.eventData.tokenU;

        if (!validateUuid(this.anonId)) {
            this.anonId = uuid();
            dueForEvent = true;
        }

        const nextUpdate = this.queue.shift();
        // Record turnstile event once per calendar day.
        if (this.eventData.lastSuccess) {
            const lastUpdate = new Date(this.eventData.lastSuccess);
            const nextDate = new Date(nextUpdate);
            const daysElapsed = (nextUpdate - this.eventData.lastSuccess) / (24 * 60 * 60 * 1000);
            dueForEvent = dueForEvent || daysElapsed >= 1 || daysElapsed < -1 || lastUpdate.getDate() !== nextDate.getDate();
        } else {
            dueForEvent = true;
        }

        if (!dueForEvent) {
            return this.processRequests();
        }

        this.postEvent(nextUpdate, {"enabled.telemetry": false}, (err) => {
            if (!err) {
                this.eventData.lastSuccess = nextUpdate;
                this.eventData.tokenU = tokenU;
            }
        }, customAccessToken);
    }
}

const turnstileEvent_ = new TurnstileEvent();
export const postTurnstileEvent = turnstileEvent_.postTurnstileEvent.bind(turnstileEvent_);

const mapLoadEvent_ = new MapLoadEvent();
export const postMapLoadEvent = mapLoadEvent_.postMapLoadEvent.bind(mapLoadEvent_);
