#!/usr/bin/env bash
# HOW TO USE:
# $ chmod +x jwt-decode.sh
# $ ./jwt-decode.sh "<JWT token>"

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

if [ -z $(command -v jq) ]; then
  echo "Error 2: missing jq"
  echo "Please install jq first: https://stedolan.github.io/jq/download/"
  exit 2
fi

clear
input=("${@}")
input=("${input//$'\n'/}")
input=("${input//' '/}")
token=$(IFS=$'\n'; echo "${input[*]}")

echo -e "JWT token:\\n${token}"
IFS='.' read -ra ADDR <<< "$token"
base64 -d <<< "$(padding "${ADDR[0]}")" | jq
base64 -d <<< "$(padding "${ADDR[1]}")" | jq
echo "Signature: ${ADDR[2]}"