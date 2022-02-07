#!/bin/ash
# Usage: cat /id_token.txt | jwt-decode.sh --no-verify-sig > jwt_payload.json
. /usr/share/libubox/jshn.sh

base64url_to_b64()
{
  echo "${1}" | tr -- '-_' '+/'
}

# read the JWT from stdin and split by comma into three variables
IFS='.' read -r JWT_HEADER_B64URL JWT_PAYLOAD_B64URL JWT_SIGNATURE_B64URL

JWT_PAYLOAD_B64=$(base64url_to_b64 "${JWT_PAYLOAD_B64URL}")
# if openssl is not installed then install coreutils-base64 and use base64 -d
JWT_PAYLOAD=$(echo -n "${JWT_PAYLOAD_B64}" | openssl base64 -d -A)

if [ "$1" != "--no-verify-sig" ]; then
  # verify signature
  json_init
  json_load "$JWT_PAYLOAD"
  json_get_var JWT_ISS iss

  JWT_HEADER_B64=$(base64url_to_b64 "${JWT_HEADER_B64URL}")
  JWT_SIGNATURE_B64=$(base64url_to_b64 "${JWT_SIGNATURE_B64URL}")

  JWT_HEADER=$(echo -n "${JWT_HEADER_B64}" | openssl base64 -d -A)

  json_init
  json_load "$JWT_HEADER"
  json_get_var JWT_ALG alg
  json_get_var JWT_KID kid

  if [ "${JWT_ALG}" = "RS256" ]; then
    PUB_KEY_FILE="/var/tmp/oauth/$JWT_KID.key.pub.pem"
    if [ ! -f "$PUB_KEY_FILE" ]; then
      >&2 echo "No pub key $JWT_KID"
      if [ "$JWT_ISS" = "https://accounts.google.com" ]; then
        mkdir -p /var/tmp/oauth/
        # use old jwks_url which return certs in PEM format
        OAUTH_CERTS_URL="https://www.googleapis.com/oauth2/v1/certs"
        >&2 echo "Fetch certs $OAUTH_CERTS_URL"
        wget $OAUTH_CERTS_URL -q -O /tmp/jwks.json
        CERT_FILE="/tmp/$JWT_KID.crt"
        jsonfilter -i /tmp/jwks.json -e "@['$JWT_KID']" > "$CERT_FILE"
        rm /tmp/jwks.json
        openssl x509 -pubkey -in "$CERT_FILE" -noout > "$PUB_KEY_FILE"
        rm "$CERT_FILE"
      else
        >&2 echo "Error 4: Unable to get public key"
        exit 4
      fi
    fi
    SIG_FILE=$(mktemp)
    echo -n "$JWT_SIGNATURE_B64" | openssl base64 -d -A > "${SIG_FILE}"
    JWT_BODY=$(echo -n "$JWT_HEADER_B64URL.$JWT_PAYLOAD_B64URL")
    JWT_SIG_VERIFY_ERR=$(echo -n "$JWT_BODY" | openssl dgst -sha256 -verify "${PUB_KEY_FILE}" -signature "${SIG_FILE}")
    JWT_SIG_VERIFY_CODE=$?
    rm "${SIG_FILE}"
    if [ ${JWT_SIG_VERIFY_CODE} -ne 0 ]; then
      >&2 echo "Error 1: Bad Signature: Code $JWT_SIG_VERIFY_CODE $JWT_SIG_VERIFY_ERR"
      exit 1
    fi
  else
    >&2 echo "Error 3: Unsupported signature algorithm $JWT_ALG"
    exit 3
  fi
fi

echo -n "${JWT_PAYLOAD}"
