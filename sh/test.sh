#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
found=0

run_tests() {
    for entry in "$1"/* "$1"/.[!.]* "$1"/..?*; do
        [ -e "$entry" ] || continue
        [ ! -L "$entry" ] || continue

        if [ -d "$entry" ]; then
            run_tests "$entry"
        elif [ -f "$entry" ]; then
            case "$entry" in
                *.test.sh)
                    found=1
                    printf '\nRunning: %s\n' "$entry"

                    if sh -n "$entry" && sh "$entry"; then
                        printf '✅ PASS: %s\n' "$entry"
                    else
                        printf '❌ FAIL: %s\n' "$entry" >&2
                        exit 1
                    fi
                    ;;
            esac
        fi
    done
}

run_tests "$script_dir/tests"

if [ "$found" -eq 0 ]; then
    printf '❌ No shell tests found\n' >&2
    exit 1
fi