function getRequestQueryParams() {
    const keyValPairs = location.search.substring(1, location.search.length).split('&')
    const requestQueryParams = {}
    keyValPairs.forEach(keyValPair => {
        const keyAndVal = keyValPair.split('=')
        const key = decodeURIComponent(keyAndVal[0])
        requestQueryParams[key] = decodeURIComponent(keyAndVal[1])
    })
    return requestQueryParams
}

/** Parse hash string */
function getRequestHashParams() {
    var fragmentString = location.hash.substring(1);
    var requestHashParams = {};
    var regex = /([^&=]+)=([^&]*)/g, m;
    while (m = regex.exec(fragmentString)) {
        requestHashParams[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
    }
    return requestHashParams
}

function currentTimestamp() {
    return (new Date()).getTime();
}

function simpleRandom() {
    // just the float rand num as is but remove 0. prefix
    return ("" + Math.random()).substring(2)
}
