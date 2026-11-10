#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")"
action_dir="$PWD/.precision-test-v1.0.9"
source_dir="$(git rev-parse --show-toplevel)"
if [[ ! -d "$action_dir" ]]; then
    git clone --depth 1 --branch v1.0.9 https://github.com/lb-actions/precision-test.git "$action_dir"
fi
test "$(git -C "$action_dir" describe --tags --exact-match HEAD)" = v1.0.9
if ! test -f "$action_dir/dist/index.js"; then
    sed -n '/^runs:/,$p' "$action_dir/action.yml"
    echo "Expected plugin entry dist/index.js is missing." >&2
    exit 1
fi
output_dir="$(mktemp -d "$PWD/map-result.XXXXXX")"
echo "Output: $output_dir"
env \
    "GITHUB_WORKSPACE=$source_dir" \
    "GITHUB_ACTION_PATH=$action_dir" \
    "INPUT_REPO=sglang" \
    "INPUT_BUILD-MAP=true" \
    "INPUT_SOURCE-DIR=$source_dir" \
    "INPUT_COVERAGE-DIR=$PWD/coverage-smoke" \
    "INPUT_MAP-FILE=$output_dir/test_case_map.json" \
    "INPUT_MIN-AFFECTED=1" \
    "INPUT_DEDUP=false" \
    "INPUT_ENABLE-LINE-MATCH=true" \
    "INPUT_ENABLE-FUNCTION-MATCH=true" \
    "INPUT_SKIP-IMPORTS=false" \
    node "$action_dir/dist/index.js" 2>&1 | tee "$output_dir/build-map.log"
python3 -m json.tool "$output_dir/test_case_map.json" > "$output_dir/test_case_map.pretty.json"
