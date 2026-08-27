#!/bin/sh

set -euox pipefail

function package() {
  local subcommand=${1}
  
  swift package reset
  swift package resolve
  swift ${subcommand} --configuration debug
  swift package clean
  swift ${subcommand} --configuration release
  swift package clean
}

function main() {
  local versions="26.0 26.1 26.2 26.3 26.4 26.5 26.6"
  
  for version in ${versions}; do
    export DEVELOPER_DIR="/Applications/Xcode_${version}.app"
    package test
  done
}

main
