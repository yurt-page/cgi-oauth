# cgi-oauth
OAuth 2 and OpenID Connect (OIDC) authorization in plain shell scripts. Can be used for small embedded devices like routers with OpenWRT or TV Box with Termux.

Supported providers and grant flows:
* Google: `code` and `id_token` (requires `openssl-utils` or `jose` installed)
* FaceBook `code` and `id_token` (requires `jose` installed)
* GitHub only code flow
* Any correct OIDC server like [KeyCloak](https://www.keycloak.org/)

The Google integration works faster because it can verify `id_token` signature and not perform an additional API call to fetch user details.
But it requires `openssl-utils` package to be installed (1.3Mb).
With `jose` package the `id_token` can be verified for FaceBook and any other providers that have `jwks_uri`. But it also depends on the OpenSSL.

For other providers the `code` flow is used in which it makes an internal server-to-server call.

The `jwt-decode.sh` script uses `jq` utility while the `jwt-decode-openwrt/files/usr/bin/jwt-decode.sh` uses OpenWRT specific [jshn](https://openwrt.org/docs/guide-developer/jshn).
It's better not to use `jq` on OpenWRT because it's quite big.

Supported operating systems and TODO:
* [x] Vanilla OpenWRT on a device with 16 Mb storage. Integrated with rpcd and exposed as `/ubus` api with uhttpd + mod_ubus
* [ ] OpenWRT with lighttpd, BusyBox httpd or any webserver but the `ubus` as a cgi adapter that internally calls the `ubus` command.
* [ ] TurrisOS and GL.iNet
* [ ] For systems without `rpcd` (Ubuntu, Termux) use a dedicated CGI script. Maybe it can imitate the rpcd api but this may be an overkill.
* [ ] jwt-decode RSA check signature without OpenSSL (or at least directly use libopenssl)
* [ ] Convert to C for a best performance (but this may increase size)

## Installation on OpenWRT
Copy the `jwt-decode-openwrt/files` into OpenWRT root `/` and restart `rpcd` daemon:

    scp -r jwt-decode-openwrt/files openwrt:/
    ssh openwrt "/etc/init.d/rpcd restart"


The script for `code` auth uses wget to perform the server-to-server call to validate a token.
But the wget on OpenWRT is a clone of the GNU wget and it doesn't support a custom headers.
The BusyBox wget do support them.

Install GNU wget:

    opkg update
    opkg install wget-ssl

For `id_token` you'll need to install OpenSSL and it will use about 1.3Mb. So check that it's enough of available space:

    df -h | grep /overlay

Then install it:

    opkg install openssl-util

It also will install `libopenssl1.1` and `libopenssl-conf`.

If you can't install the OpenSSL then you must install `base64` from `coreutils-base64` or enable it in BusyBox compile.

### Configure 

* `/etc/auth-config.json` is a file where you configure enabled auth methods. Note: the file's content is seen for everyone.
* `oauth.conf.sh` is file where secret keys are configured. There is also `UBUS_SESSION_GRANTS` where you can configure permissions for the JSON-RPC token.

Then open https://example.com/auth.html in browser.

## TODO
 [ ] Check `exp` field
 [ ] More lightweight grant flow when id_token is kept on UI but a separate signed ticket_token only with `sub` is sent to backend. Thus Backend knows that user is authenticated but don't know any it's details.
 [ ] A native binary which is faster than jose that verifies id_token signature
 [ ] Support of any OIDC server that has /.well-known/openid-configuration

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
* https://github.com/latchset/jose already ported to OpenWRT and has command line tool to verify JWT
* https://github.com/benmcollins/libjwt seems easier to use
* https://jwt.io/libraries many others for C and C++
