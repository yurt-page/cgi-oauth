// const apiUrl = 'http://192.168.1.1/ubus'
const apiUrl = '/ubus'
var rpcCallId = 1

function rpcCall(service, method, params, callback) {
    let ubusRpcSession = localStorage.getItem("ubusRpcSession")
    if (!ubusRpcSession) {
        ubusRpcSession = '00000000000000000000000000000000'
    }
    let rpcRequestObj = {"jsonrpc": "2.0", "id": rpcCallId, "method": "call", "params": [ubusRpcSession, service, method, params]}
    fetch(apiUrl, {
        method: "POST",
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(rpcRequestObj)
    })
        .then(response => response.json())
        .then(rpcResp => {
            rpcCallId++
            console.log(rpcResp)
            if (rpcResp.error) {
                console.error("Error on RPC call " + rpcResp.error.code + " " + rpcResp.error.message)
            } else {
                var apiRes = rpcResp.result[1];
                if (apiRes.error) { // special case for app level errors
                    alert("Error on RPC call " + apiRes.error.code + " " + apiRes.error.message)
                }
                callback(apiRes)
            }
        })
}

function loginCall(username, password) {
    localStorage.removeItem("ubusRpcSession")
    rpcCall("session", "login", {"username": username, "password": password}, loginCallCb)
}

function loginCallCb(rpcResult) {
    let ubusRpcSession = rpcResult.ubus_rpc_session
    if (ubusRpcSession) {
        localStorage.setItem("ubusRpcSession", ubusRpcSession)
        console.log(ubusRpcSession + ' ' + rpcCallId)
    }
}