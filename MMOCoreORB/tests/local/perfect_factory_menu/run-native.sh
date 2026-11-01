#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
orb=$(cd -- "$here/../../.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
engine=${PERFECT_MENU_ENGINE_LIBRARY:-$orb/utils/engine3/MMOEngine/lib/unix/libengine3.a}
"${CXX:-c++}" -std=gnu++14 -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -Wno-multichar -Wno-class-memaccess \
 -I "$here/ui_boundary" -I "$orb/utils/engine3/MMOEngine/src" -I "$orb/src" \
 "$here/snapshot_spec.cpp" "$orb/src/server/zone/objects/player/sui/characterbuilderbox/SuiCharacterBuilderBoxImplementation.cpp" "$engine" -llua -lpthread -ldl -lz -lssl -lcrypto -lboost_thread -lboost_atomic -latomic -ldb -o "$build/snapshot_spec"
"$build/snapshot_spec"
