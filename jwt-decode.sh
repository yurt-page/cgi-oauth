#!/usr/bin/env bash
# HOW TO USE:
# $ chmod +x jwt-decode.sh
# $ cat id_token.txt | ./jwt-decode.sh

if [ -z $(command -v jq) ]; then
  echo "Error 2: missing jq"
  echo "Please install jq first: https://stedolan.github.io/jq/download/"
  exit 2
fi

if [ -z $(command -v openssl) ]; then
  >&2 echo "Error 2: missing openssl-util"
  exit 2
fi

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

echo -n "${JWT_PAYLOAD}"
