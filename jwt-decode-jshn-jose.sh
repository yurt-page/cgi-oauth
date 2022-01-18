#!/bin/ash
# Usage: cat /id_token.txt | jwt-decode.sh --no-verify-sig > jwt_payload.json
. /usr/share/libubox/jshn.sh

base64_padding()
{
  local len=$(( ${#1} % 4 ))
  local padded_b64=''
  if [ ${len} = 2 ]; then
    padded_b64="${1}=="
  elif [ ${len} = 3 ]; then
    padded_b64="${1}="
  else
    padded_b64="${1}"
  fi
  echo -n "$padded_b64"
}

base64url_to_b64()
{
  base64_padding "${1}" | tr -- '-_' '+/'
}

# read the JWT from stdin and split by comma into three variables
IFS='.' read -r JWT_HEADER_B64URL JWT_PAYLOAD_B64URL JWT_SIGNATURE_B64URL

JWT_PAYLOAD_B64=$(base64url_to_b64 "${JWT_PAYLOAD_B64URL}")
JWT_PAYLOAD=$(echo -n "${JWT_PAYLOAD_B64}" | openssl base64 -d -A)

if [ "$1" != "--no-verify-sig" ]; then
  JWT_HEADER_B64=$(base64url_to_b64 "${JWT_HEADER_B64URL}")
  JWT_SIGNATURE_B64=$(base64url_to_b64 "${JWT_SIGNATURE_B64URL}")

  JWT_HEADER=$(echo -n "${JWT_HEADER_B64}" | openssl base64 -d -A)

  json_init
  json_load "$JWT_HEADER"
  json_get_var JWT_ALG alg
  json_get_var JWT_KID kid
  json_init
  json_load "$JWT_PAYLOAD"
  json_get_var JWT_ISS iss

  # verify signature
  AUTH_PROVIDER=""
  OAUTH_CERTS_URL=""
  if [ "$JWT_ISS" = "https://accounts.google.com" ]; then
    AUTH_PROVIDER="google"
    OAUTH_CERTS_URL="https://www.googleapis.com/oauth2/v3/certs"
  elif [ "$JWT_ISS" = "https://www.facebook.com" ]; then
    AUTH_PROVIDER="facebook"
    OAUTH_CERTS_URL="https://www.facebook.com/.well-known/oauth/openid/jwks/"
  else
    >&2 echo "Error 4: Unsupported provider"
    exit 4
  fi
  JWKS_FILE="/tmp/oauth-$AUTH_PROVIDER.jwks.json"
  wget "$OAUTH_CERTS_URL" -q -N -O $JWKS_FILE
  FULL_JWS=$(echo -n "$JWT_HEADER_B64URL.$JWT_PAYLOAD_B64URL.$JWT_SIGNATURE_B64URL")
  JWT_SIG_VERIFY_ERR=$(echo -n "$FULL_JWS" | jose jws ver -i - -k $JWKS_FILE)
  JWT_SIG_VERIFY_CODE=$?
  if [ ${JWT_SIG_VERIFY_CODE} -ne 0 ]; then
    >&2 echo "Error 1: Bad Signature: Code $JWT_SIG_VERIFY_CODE $JWT_SIG_VERIFY_ERR"
    exit 1
  fi
fi

echo -n "${JWT_PAYLOAD}"
