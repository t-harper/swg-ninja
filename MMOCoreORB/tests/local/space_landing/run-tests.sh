#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
orb=$(cd -- "$here/../../.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
flags=()
if [[ "${SPACE_LANDING_BASELINE_TASK:-0}" == 1 ]]; then
  flags+=(-DSPACE_LANDING_BASELINE_TASK)
fi
"${CXX:-c++}" "${flags[@]}" -std=c++17 -Wall -Wextra -Werror -pedantic \
  -I "$here/stubs" -I "${LANDING_SOURCE_ROOT:-$orb/src}" \
  "$here/test_store_ship.cpp" -o "$build/test_store_ship"
"$build/test_store_ship"
