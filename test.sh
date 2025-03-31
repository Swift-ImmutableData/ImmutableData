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
  local versions="16.0 16.1 16.2 16.3"
  
  for version in ${versions}; do
    export DEVELOPER_DIR="/Applications/Xcode_${version}.app"
    package test
  done
}

main
