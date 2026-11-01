#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
orb=$(cd -- "$here/../../.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
engine=${FRS_GM_ENGINE_LIBRARY:-$orb/utils/engine3/MMOEngine/lib/unix/libengine3.a}
"${CXX:-c++}" -std=gnu++14 -Wall -Wextra -Wno-unused -Wno-unused-local-typedefs -Wno-unused-parameter -Wno-sign-compare -Wno-multichar -Wno-class-memaccess \
 -I "$here/boundary" -I "$here" -I "$orb/utils/engine3/MMOEngine/src" -I "$orb/src" \
 "$here/service_spec.cpp" "$orb/src/server/zone/managers/frs/FrsGmEditor.cpp" "$orb/src/server/zone/objects/player/sui/callbacks/FrsGmEditorSuiCallback.cpp" "$engine" \
 -llua -lpthread -ldl -lz -lssl -lcrypto -lboost_thread -lboost_atomic -latomic -ldb -o "$build/service_spec"
"$build/service_spec"
