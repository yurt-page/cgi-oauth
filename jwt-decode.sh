#!/bin/sh
# Usage: cat /id_token.txt | jwt-decode.sh > jwt_payload.json
# Decode a JWT from stdin

base64url_to_b64()
{
  echo "${1}" | tr -- '-_' '+/'
}

# read the JWT from stdin and split by comma into three variables
IFS='.' read -r JWT_HEADER_B64URL JWT_PAYLOAD_B64URL JWT_SIGNATURE_B64URL

JWT_PAYLOAD_B64=$(base64url_to_b64 "${JWT_PAYLOAD_B64URL}")
JWT_PAYLOAD=$(echo -n "${JWT_PAYLOAD_B64}" | base64 -d)

echo -n "${JWT_PAYLOAD}"
