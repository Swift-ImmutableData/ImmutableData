#!/bin/bash

set -eu

main() {
  toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta"
  
  for toolchain in $toolchains; do
    sudo xcode-select --switch /Applications/${toolchain}.app
    swift --version
    swift package resolve
    swift test
    swift package reset
  done
  
  sudo xcode-select --reset
}

main
