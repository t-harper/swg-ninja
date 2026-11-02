#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$here/../../.." && pwd)
binary=$(mktemp /tmp/ninja-maintenance-tests.XXXXXX)
trap 'rm -f "$binary"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -pthread -I"$root/src" "$here/gate_spec.cpp" -o "$binary"
"$binary"
