#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test_dir="$script_dir/tests"

if [ ! -d "$test_dir" ] ||
    ! find "$test_dir" -type f -name '*.test.sh' -print | grep -q .; then
    printf '❌ No shell tests found\n' >&2
    exit 1
fi

find "$test_dir" -type f -name '*.test.sh' -exec sh -c '
    failed=0

    for test_file do
        printf "\nRunning: %s\n" "$test_file"

        if sh "$test_file"; then
            printf "✅ PASS: %s\n" "$test_file"
        else
            printf "❌ FAIL: %s\n" "$test_file" >&2
            failed=1
        fi
    done

    exit "$failed"
' sh {} +