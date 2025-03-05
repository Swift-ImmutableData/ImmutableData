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
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta_2"
  
  for toolchain in ${toolchains}; do
    export DEVELOPER_DIR="/Applications/${toolchain}.app"
    swift --version
    package test
  done
}

main
