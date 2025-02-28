#!/bin/bash

set -euox pipefail

build() {
  local package_path="$1"
  
  swift package --package-path ${package_path} reset
  swift package --package-path ${package_path} resolve
  swift build --package-path ${package_path}
}

test() {
  local package_path="$1"
  
  swift package --package-path ${package_path} reset
  swift package --package-path ${package_path} resolve
  swift build --package-path ${package_path}
  swift test --package-path ${package_path}
}

main() {
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta"
  
  for toolchain in $toolchains; do
    sudo xcode-select --switch /Applications/${toolchain}.app
    swift --version
    test AnimalsData
    build AnimalsUI
    test CounterData
    build CounterUI
    test QuakesData
    build QuakesUI
    test Services
  done
  
  sudo xcode-select --reset
}

main
