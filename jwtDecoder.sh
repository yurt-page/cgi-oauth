#!/usr/bin/env bash
# HOW TO USE:
# ~$ chmod +x jwtDecoder.sh
# ~$ ./jwtDecoder.sh "<JWT token>"

padding() {
    # $1: base64 string
    local m p=""
    m=$(( ${#1} % 4 ))
    [[ "$m" == 2 ]] && p="=="
    [[ "$m" == 3 ]] && p="="
    echo "${1}${p}"
}

if [[ -z $(command -v jq) ]]; then
    echo "This script will NOT work on your machine."
    echo "Please install jq using command below:"
    echo "> brew install jq"
    exit 1
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