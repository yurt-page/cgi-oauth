# cgi-oauth
OAuth 2 and OpenID Connect (OIDC) authorization in plain shell scripts. Can be used for small embedded devices like routers with OpenWrt or TV Box with Termux.

Supported providers and grant flows:
* Google: `code` and `id_token` (requires `openssl-utils` or `jose` installed)
* FaceBook `code` and `id_token` (requires `jose` installed)
* GitHub only `code` flow
* Any correct OIDC server like [KeyCloak](https://www.keycloak.org/)

The Google integration works faster because it can verify `id_token` signature and not perform an additional API call to fetch user details.
But it requires `openssl-utils` package to be installed (1.3Mb).
With `jose` package the `id_token` can be verified for FaceBook and any other providers that have `jwks_uri`. But it also depends on the OpenSSL library.

For other providers like GitHub the `code` flow is used in which it makes an internal server-to-server call.

* The `jwt-decode-jq-*.sh` scripts uses `jq` utility while the `jwt-decode-jshn-*.sh` uses OpenWrt specific [jshn](https://OpenWrt.org/docs/guide-developer/jshn).
* It's better not to use `jq` on OpenWrt because it's quite big. But this is the only option for others OS like Ubuntu or Termux.
* The `jwt-decode-*-jose.sh` scripts use `jose` utility and are most advanced and supports Facebook by `id_token`.
* The `jwt-decode-*-openssl.sh` scripts use just plain `openssl` utility and can work only with Google.

So in short for OpenWrt device use `jwt-decode-jshn-jose.sh` and for Ubuntu,Termux use `jwt-decode-jq-jose.sh`.
For the OpenWrt tiny 4mb devices you can't install the OpenSSL so use only `code` flow and `jwt-decode.sh`.
But you must install `base64` from `coreutils-base64` or enable it in BusyBox compile.

## Installation on OpenWrt
Copy the `jwt-decode-openwrt/files` into OpenWrt root `/` and restart `rpcd` daemon:

    scp -r jwt-decode-OpenWrt/files openwrt:/
    ssh openwrt "/etc/init.d/rpcd restart"


The script for `code` auth uses wget to perform the server-to-server call to validate a token.
But the wget on OpenWrt is a clone of the GNU wget and it doesn't support a custom headers.
The BusyBox wget do support them.

Install GNU wget:

    opkg update
    opkg install wget-ssl

For `id_token` you'll need to install OpenSSL and it will use about 1.3Mb. So check that it's enough of available space:

    df -h | grep /overlay

Then install it:

    opkg install openssl-util

It also will install `libopenssl1.1` and `libopenssl-conf`.

To use jose install it with `opkg install jose`. It will also install `libjose` and `jansson` JSON parsing lib.

Then copy the desired script variant:

    scp jwt-decode-jshn-jose.sh openwrt:/usr/bin/jwt-decode.sh

Make it executable:

    chmod +x /usr/bin/jwt-decode.sh

### Configure 

* `/etc/auth-config.json` is a file where you configure enabled auth methods. Note: the file's content is seen for everyone.
* `oauth.conf.sh` is file where secret keys are configured. There is also `UBUS_SESSION_GRANTS` where you can configure permissions for the JSON-RPC token.

Then open https://example.com/auth.html in browser.

## Supported operating systems

* [x] Vanilla OpenWrt on a device with 16 Mb storage. Integrated with rpcd and exposed as `/ubus` api with uhttpd + mod_ubus
* [x] OpenWrt with lighttpd, BusyBox httpd or any webserver but the `ubus` as a [cgi adapter](https://github.com/yurt-page/cgi-ubus) that internally calls the `ubus` command.
* [ ] TurrisOS and GL.iNet (should work but not tested)
* [ ] For systems without `rpcd` (Ubuntu, Termux) use a dedicated CGI script. Maybe it can imitate the rpcd api but this may be an overkill.

## TODO

 * [ ] Check `exp` field
 * [ ] Read configs from UCI 
 * [ ] More lightweight grant flow when id_token is kept on UI but a separate signed ticket_token only with `sub` is sent to backend. Thus Backend knows that user is authenticated but don't know any it's details.
 * [ ] A native binary which is faster than jose that verifies id_token signature.
 * [ ] jwt-decode RSA check signature without OpenSSL tool (or at least directly use libopenssl). OpenWwt switched to WolfSSL.
 * [ ] Convert `rpcd/oauth` to C for best performance (but this may increase size)
 * [ ] Support of any OIDC server that has `/.well-known/openid-configuration`. Automatically download JWKS.
 * [ ] Support for Tor hidden services with `.onion` domain.
 * [ ] Alternative website to download JWKS: FB JWKS link doesn't support cache (by ETag or Last-Modified)

## License
[0BDSD](https://opensource.org/licenses/0BSD) (similar to Public Domain)

## See also

Also related and may be useful:
* https://github.com/emcrisostomo/jwt-cli A shell (zsh) library to decode JWT tokens. It's more verbose, ueses jq and coreutils base64 or openssl
* https://willhaley.com/blog/generate-jwt-with-bash/
* https://www.jvt.me/posts/2019/06/13/pretty-printing-jwt-openssl/
* https://dev.to/milolav/oauth2-certificate-authentication-in-bash-script-3b1e  RFC7521 client_assertion for Microsoft Graph and for Google APIs.
* https://gist.github.com/rolandyoung/176dd310a6948e094be6 Here is an example with verifying a signature
* https://github.com/Moodstocks/moodstocks-api-clients/blob/master/bash/base64url.sh An example of base64 URL encode/decode


### C libraries that may be used
* https://github.com/latchset/jose already ported to OpenWrt and has command line tool to verify JWT
* https://github.com/benmcollins/libjwt seems easier to use
* https://jwt.io/libraries many others for C and C++

## Implicit Grant Flow for authentication on both Client UI and Back End by OIDC id_token verification
The Implicit grant flow was intended for authorizing of clients which can't store the `client_secret` like SPA.
It was considered like not very safe and some Auth Services like GitHub doesn't even support it.
OIDC added `id_token` which is a signed JWT (JWS) that contains a user info.
If we just need for an authentication it's now possible to request the only `response_type=id_token` i.e. we are don't interested in getting the `access_token`.
Anybody can verify that the token was issued by the Auth Server and it wasn't changed.
We may also ask to include our own `nonce` into the `id_token` and thus we may protect from reusing the `id_token` twice.
This gives us an ability to use the `id_token` for server validation.
To explain the flow let's take for example a Google:
1. On UI a User press Login button
2. UI asks a server for the `nonce`, server generates it, stores and returns to UI. For example `gNNMgg`.
3. Now UI redirects a User Agent to Auth Server with the received `nonce`, a random `state` and `response_type=id_token`
4. The User authorizes the Client (app) on the Auth Service and redirected back to the Client UI and an `id_token` is passed in a hash `#` part of URL.
5. The UI checks that `state` is the same as it generated on step 3.
6. The UI now have the User details but Server is not. So UI sends the received `id_token` to a Client Server.
7. The Client Server verifies the `id_token` signature with a public JWKS of the Auth Server.
8. To avoid submitting of someone else's stolen `id_token` the Client Server is also verifies that its own the generated `nonce` is the same as included into the `id_token`.

The key advantage of the flow is that the Client Server doesn't have to perform a side channel request to the Auth Server as it needs in the Authorization Code flow.
This not only improves a performance but also allows to decouple Client Server from Auth Service.
For example the Client Server can't connect for the Auth Service because of connectivity problems.
Or if the AS is blocked in the Client Server country (e.g. Yandex and VK.com in Ukraine, Google in China, Twitter in Nigeria etc.).
Another reason if the Client Server wants to hide its IP from the Auth Service e.g. this a Tor Hidden Service with .onion domain.
The Client Server anyway have to periodically fetch the JWKS of the AS but this can be done by a secure channels (e.g. by the same Tor network).
Now it's possible to block any outgoing connections from the Client Server that significantly improves safety.

I have a plan to improve it a little. In my case the Client Server doesn't need to know any personal user details except of its `sub` i.e. uniq id.
But UI still needs some basic fields like `name` and `picture` to show on UI.
So I think to create an AS that will return a separate token `id_token_short` which will contain only the `nonce` and `sub`.
In fact that may be not a JSON token but a simply encrypted string with coma separated sub and nonce.
Thus, it will be shorter an easier to parse on backend.
