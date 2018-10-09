#!/usr/bin/env bash
# HOW TO USE:
# ~$ wget "https://gist.githubusercontent.com/KevCui/767ebcdf8afb1df2a2abb4e95d9a70e3/raw/82427e0e6d2894d9dfd65b2e72e79ddf5fc7f44d/jwtDecoder.sh"
# ~$ chmod +x jwtDecoder.sh
# ~$ ./jwtDecoder.sh "<JWT token>"

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
for i in "${ADDR[@]}"; do
    echo "$i" | base64 -d 2> /dev/null | jq '.' 2> /dev/null
done