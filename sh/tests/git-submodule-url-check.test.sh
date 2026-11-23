#!/bin/sh
set -eu

test_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$test_dir/../git-submodule-url-check.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

parent="$fixture/workspace"
child="$parent/deps/with spaces"

init_repo() {
    git init -q "$1"
    git -C "$1" -c user.name=Fixture \
        -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false \
        commit -qm Initialize --allow-empty
}

expect() {
    parent_before=$(git -C "$parent" config --local --list)
    child_before=$(git -C "$child" config --local --list)

    report=$(sh "$checker" "$parent" library "deps/with spaces")
    if ! printf '%s\n' "$report" | grep -F "$1"; then
        printf '❌ Expected: %s\n%s\n' "$1" "$report" >&2
        exit 1
    fi

    if [ "$parent_before" != "$(git -C "$parent" config --local --list)" ] ||
        [ "$child_before" != "$(git -C "$child" config --local --list)" ]; then
        printf '❌ URL check modified Git configuration\n' >&2
        exit 1
    fi
}

init_repo "$fixture/source"
init_repo "$parent"

git -C "$parent" -c protocol.file.allow=always submodule add -q \
    --name library "$fixture/source" "deps/with spaces"

expect '✅ URL configuration matches .gitmodules'

git -C "$parent" config submodule.library.url "$fixture/stale"
expect '⚠ URL sync needed'

git -C "$parent" config submodule.library.url "$fixture/source"
git -C "$child" remote set-url origin "$fixture/stale"
expect '⚠ URL sync needed'

git -C "$child" remote set-url origin "$fixture/source"
expect '✅ URL configuration matches .gitmodules'

git -C "$parent" config --file .gitmodules \
    submodule.library.url "$fixture/replacement"
expect '⚠ URL sync needed'

git -C "$parent" config --file .gitmodules \
    submodule.library.url ../source
expect '○ Relative URL comparison: not implemented yet'