function getRequestQueryParams() {
    let keyValPairs = location.search.substring(1, location.search.length).split('&')
    let requestQueryParams = {}
    keyValPairs.forEach(keyValPair => {
        let keyAndVal = keyValPair.split('=')
        let key = decodeURIComponent(keyAndVal[0])
        requestQueryParams[key] = decodeURIComponent(keyAndVal[1])
    })
    return requestQueryParams
}

/** Parse hash string */
function getRequestHashParams() {
    let fragmentString = location.hash.substring(1)
    let requestHashParams = {}
    let regex = /([^&=]+)=([^&]*)/g
    let m
    while (m = regex.exec(fragmentString)) {
        requestHashParams[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
    }
    return requestHashParams
}

function currentTimestamp() {
    return (new Date()).getTime()
}

function simpleRandom() {
    let buf = new Uint32Array(1)
    window.crypto.getRandomValues(buf)
    let b64encoded = btoa(buf)
    return b64encoded.replace(/=/g, '')
}
