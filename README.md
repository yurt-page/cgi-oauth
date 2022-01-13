# cgi-oauth
OAuth 2 OIDC.

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

Supported operating systems:
* done: Vanilla OpenWRT on a device with 16 Mb storage. Integrated with rpcd and exposed as `/ubus` api with uhttpd + mod_ubus
* OpenWRT with lighttpd, BusyBox httpd or any webserver but the `ubus` as a cgi adapter that internally calls the `ubus` command.
* TurrisOS and Gl.inet
* For systems without `rpcd` (Ubuntu, Termux) use a dedicated CGI script. Maybe it can imitate the rpcd api but this may be an overkill. 

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