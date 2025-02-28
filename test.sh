#!/bin/bash

set -euox pipefail

main() {
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta"
  
  for toolchain in $toolchains; do
    sudo xcode-select --switch /Applications/${toolchain}.app
    swift --version
    swift package reset
    swift package resolve
    swift build
    swift test
  done
  
  sudo xcode-select --reset
}

main
