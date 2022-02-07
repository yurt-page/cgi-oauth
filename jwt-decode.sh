#!/bin/sh
# Usage: cat /id_token.txt | jwt-decode.sh > jwt_payload.json
# Decode a JWT from stdin

decode_base64url()
{
  echo "${1}" | tr -- '-_' '+/' | base64 -d
}

# read the JWT from stdin and split by comma into three variables
IFS='.' read -r JWT_HEADER_B64URL JWT_PAYLOAD_B64URL JWT_SIGNATURE_B64URL

JWT_PAYLOAD=$(decode_base64url "$JWT_PAYLOAD_B64URL")

echo -n "$JWT_PAYLOAD"
