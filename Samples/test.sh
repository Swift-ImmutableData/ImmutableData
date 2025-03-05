#!/bin/sh

set -euox pipefail

function package() {
  local subcommand=${1}
  local package_path=${2}
  
  swift package --package-path ${package_path} reset
  swift package --package-path ${package_path} resolve
  swift ${subcommand} --package-path ${package_path} --configuration debug
  swift package --package-path ${package_path} clean
  swift ${subcommand} --package-path ${package_path} --configuration release
  swift package --package-path ${package_path} clean
}

function main() {
  local toolchains="Xcode_16 Xcode_16.1 Xcode_16.2 Xcode_16.3_beta_2"
  
  for toolchain in ${toolchains}; do
    export DEVELOPER_DIR="/Applications/${toolchain}.app"
    swift --version
    package test AnimalsData
    package build AnimalsUI
    package test CounterData
    package build CounterUI
    package test QuakesData
    package build QuakesUI
    package test Services
  done
}

main
