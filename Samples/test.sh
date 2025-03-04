#!/bin/sh

set -euox pipefail

package() {
  local subcommand="$1"
  local package_path="$2"
  
  swift package --package-path ${package_path} reset
  swift package --package-path ${package_path} resolve
  swift ${subcommand} --package-path ${package_path} --configuration debug
  swift package --package-path ${package_path} clean
  swift ${subcommand} --package-path ${package_path} --configuration release
  swift package --package-path ${package_path} clean
}

main() {
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta"
  
  for toolchain in $toolchains; do
    sudo xcode-select --switch /Applications/${toolchain}.app
    swift --version
    package test AnimalsData
    package build AnimalsUI
    package test CounterData
    package build CounterUI
    package test QuakesData
    package build QuakesUI
    package test Services
  done
  
  sudo xcode-select --reset
}

main
