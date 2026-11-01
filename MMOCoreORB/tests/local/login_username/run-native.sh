#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
orb=$(cd -- "$here/../../.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
engine=${LOGIN_ENGINE_LIBRARY:-$orb/utils/engine3/MMOEngine/lib/unix/libengine3.a}
"${CXX:-c++}" -std=gnu++14 -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -Wno-multichar -Wno-class-memaccess \
 -I "$orb/utils/engine3/MMOEngine/src" -I "$orb/src" \
 "$here/parse_spec.cpp" "$engine" -llua -lpthread -ldl -lz -lssl -lcrypto -lboost_thread -lboost_atomic -latomic -ldb -o "$build/parse_spec"
"$build/parse_spec"
