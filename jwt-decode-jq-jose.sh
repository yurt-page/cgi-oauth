#!/bin/sh
# Usage: cat /id_token.txt | jwt-decode.sh --no-verify-sig > jwt_payload.json
# Decode a JWT from stdin and verify it's signature with the JWT issuer public key
# HOW TO USE:
# $ chmod +x jwt-decode.sh
# Parse file:
# $ cat id_token.txt | ./jwt-decode.sh
# if signature check failed then error code will be non-zero

if [ -z $(command -v jq) ]; then
  >&2 echo "Error 2: missing jq"
  exit 2
fi

if [ -z $(command -v jose) ]; then
  >&2 echo "Error 2: missing jose"
  exit 2
fi

decode_base64url()
{
  echo "${1}" | tr -- '-_' '+/' | openssl base64 -d -A
}

# read the JWT from stdin and split by comma into three variables
IFS='.' read -r JWT_HEADER_B64URL JWT_PAYLOAD_B64URL JWT_SIGNATURE_B64URL

JWT_PAYLOAD=$(decode_base64url "$JWT_PAYLOAD_B64URL")

if [ "$1" != "--no-verify-sig" ]; then
  # verify signature
  JWT_ISS=$(echo "$JWT_PAYLOAD" | jq -r .iss)
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

echo -n "$JWT_PAYLOAD"
