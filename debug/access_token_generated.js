'use strict';

mapboxgl.accessToken = getAccessToken();

function getAccessToken() {
    var accessToken = (
        undefined ||
        "pk.eyJ1IjoienN0YWRsZXIiLCJhIjoiY2lvbDc5Zzl6MDAwc3Z2bTZ6NDNybDM3dSJ9.vxR1WVn26mEtpEk9MzdiUA" ||
        getURLParameter('access_token') ||
        localStorage.getItem('accessToken')
    );
    try {
        localStorage.setItem('accessToken', accessToken);
    } catch (_) {}
    return accessToken;
}

function getURLParameter(name) {
    var regexp = new RegExp('[?&]' + name + '=([^&#]*)', 'i');
    var output = regexp.exec(window.location.href);
    return output && output[1];
}
