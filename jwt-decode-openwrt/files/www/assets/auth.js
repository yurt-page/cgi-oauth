function showUserInfo(userInfo) {
    if (userInfo) {
        document.getElementById("notLogged").style.display = "none"
        document.getElementById("userInfo").style.display = "block"
        let elLogin = document.getElementById("login");
        elLogin.innerText = userInfo.sub
        elLogin.href = 'mailto:' + userInfo.email
        document.getElementById("avatar").src = userInfo.picture
        console.log("Finally " + userInfo.sub)
    } else {
        document.getElementById("notLogged").style.display = "block"
        document.getElementById("userInfo").style.display = "none"
        let elLogin = document.getElementById("login");
        elLogin.innerText = ''
        elLogin.href = ''
        document.getElementById("avatar").src = ''
        console.log("No user info")
    }
}

function showAuthProviders(authOpts) {
    let elOauthProviders = document.getElementById("oauthProviders");
    authOpts.providers.forEach(provider => {
        let elProviderLink = document.createElement("button");
        elProviderLink.id = 'authLink' + provider.id
        elProviderLink.dataset.provider = provider.id
        elProviderLink.onclick = oauthLoginStart
        elProviderLink.innerText = 'Login with ' + provider.id

        let elProviderLi = document.createElement("li");
        elProviderLi.appendChild(elProviderLink)
        elOauthProviders.appendChild(elProviderLi)
    })
}

function checkAuth() {
    let userInfo = localStorage.getItem("userInfo")
    if (userInfo) {
        showUserInfo(JSON.parse(userInfo))
    } else {
        // not logged
        showUserInfo(null)
        const oauthRandState = localStorage.getItem("oauthRandState")
        // if we are waiting for the redirect callback
        if (oauthRandState) {
            let responseType = localStorage.getItem("responseType")
            // if id_token was used then all params are passed via hash
            let requestParams = responseType.includes("id_token") ? getRequestHashParams() : getRequestQueryParams()
            console.log(requestParams)
            if (requestParams.error) {
                // callback with error
                console.log(requestParams.error_description)
                console.log(requestParams.error_uri)
                return
            }
            // check state
            if (requestParams.state !== oauthRandState) {
                console.log("Fake oauthRandState")
                return
            } else {
                localStorage.removeItem("oauthRandState")
            }

            let selectedProvider = localStorage.getItem("selectedProvider");
            // responseType" "id_token": id_token from hash
            if (requestParams.id_token) {
                let reqNonce = localStorage.getItem("reqNonce")
                rpcCall("oauth", "authLink", {"provider": selectedProvider, "reqNonce": reqNonce, "idToken": requestParams.id_token}, (userInfo) => {
                    localStorage.setItem("userInfo", JSON.stringify(userInfo))
                    localStorage.setItem("ubusRpcSession", userInfo.ubusRpcSession)
                    localStorage.removeItem("responseType")
                    localStorage.removeItem("reqNonce")
                    showUserInfo(userInfo)
                })
                return;
            }
            // responseType" "code":
            if (requestParams.code) {
                rpcCall("oauth", "authComplete", {"provider": selectedProvider, "code": requestParams.code}, (userInfo) => {
                    localStorage.setItem("userInfo", JSON.stringify(userInfo))
                    localStorage.setItem("ubusRpcSession", userInfo.ubusRpcSession)
                    localStorage.removeItem("responseType")
                    showUserInfo(userInfo)
                })
                return;
            }
        }
        // first page open, show login options
        rpcCall("oauth", "authOpts", {}, (authOpts) => {
            localStorage.setItem("authOpts", JSON.stringify(authOpts))
            showAuthProviders(authOpts);
        })
    }
}

function redirectToOauthProvider(provider, redirectUri, oauthRandState, nonce) {
    let oathUrl = provider.authEndpoint +
        '?response_type=' + provider.responseType +
        '&client_id=' + provider.clientId +
        '&scope=' + encodeURIComponent(provider.scope) +
        '&redirect_uri=' + encodeURIComponent(redirectUri) +
        '&state=' + encodeURIComponent(oauthRandState);
    if (nonce)
        oathUrl += '&nonce=' + encodeURIComponent(nonce)
    console.log(oathUrl)
    window.location.href = oathUrl
}

function performLogin(provider, redirectUri) {
    localStorage.setItem("responseType", provider.responseType)
    const oauthRandState = simpleRandom()
    localStorage.setItem("oauthRandState", oauthRandState)
    if (provider.responseType.includes("id_token")) {
        let reqNonce = simpleRandom()
        localStorage.setItem("reqNonce", reqNonce)
        rpcCall("oauth", "authInit", {"provider": provider.id, "reqNonce": reqNonce}, (authInitResp) => {
            let nonce = authInitResp.nonce
            redirectToOauthProvider(provider, redirectUri, oauthRandState, nonce);
        })
    } else {
        redirectToOauthProvider(provider, redirectUri, oauthRandState, null);
    }
}

function oauthLoginStart(element) {
    let selectedProvider = element.target.dataset.provider;
    localStorage.setItem("selectedProvider", selectedProvider)
    let authOpts = JSON.parse(localStorage.getItem("authOpts"));
    let redirectUri = authOpts.redirectUri
    authOpts.providers.forEach(provider => {
        if (provider.id === selectedProvider) {
            performLogin(provider, redirectUri);
        }
    })
}

function logout() {
    localStorage.removeItem("userInfo")
    localStorage.removeItem("ubusRpcSession")
    showUserInfo(null)
    let authOpts = JSON.parse(localStorage.getItem("authOpts"));
    showAuthProviders(authOpts);
}

document.addEventListener('DOMContentLoaded', function () {
    checkAuth()
})
