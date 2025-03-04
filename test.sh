#!/bin/sh

set -euox pipefail

package() {
  local subcommand="$1"
  
  swift package reset
  swift package resolve
  swift ${subcommand} --configuration debug
  swift package clean
  swift ${subcommand} --configuration release
  swift package clean
}

main() {
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta"
  
  for toolchain in $toolchains; do
    sudo xcode-select --switch /Applications/${toolchain}.app
    swift --version
    package test
  done
  
  sudo xcode-select --reset
}

main
