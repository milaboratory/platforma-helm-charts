#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${script_dir}"

for chart in charts/*; do
    if [ ! -d "$chart/tests" ]; then
        continue
    fi

    echo "Testing chart ${chart}"
    echo "================================================"
    echo ""
    for test in "$chart/tests"/*; do
        if [ ! -x "$test" ]; then
            continue
        fi

        echo "Running $test"
        echo "================================================"
        echo ""
        "$test"
    done
done
