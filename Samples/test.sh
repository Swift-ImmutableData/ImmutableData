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
  local versions="16.0 16.1 16.2 16.3 16.4"
  
  for version in ${versions}; do
    export DEVELOPER_DIR="/Applications/Xcode_${version}.app"
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
