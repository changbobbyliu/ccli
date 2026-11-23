#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script="$script_dir/../git-submodule-status-check.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

init_repo() {
    git init -q "$1"
    git -C "$1" config user.name "Fixture"
    git -C "$1" config user.email "fixture@example.invalid"
    git -C "$1" -c commit.gpgsign=false commit -qm "Initialize" --allow-empty
}

init_repo "$fixture/source"
init_repo "$fixture/other workspace"

git -C "$fixture/other workspace" -c protocol.file.allow=always \
    submodule add -q "$fixture/source" "packages/other module"
git -C "$fixture/other workspace/packages/other module" \
    config protocol.file.allow always
git -C "$fixture/other workspace" -c commit.gpgsign=false \
    commit -qam "Add module"

report=$(sh "$script" "$fixture/other workspace")
printf '%s\n' "$report" | grep -F '✅ Up to date'
printf '%s\n' "$report" | grep -F 'packages/other module'
if printf '%s\n' "$report" | grep -q '^[?][?] '; then
    printf 'FAIL: clean fixture reported untracked files\n' >&2
    exit 1
fi

printf 'local work\n' > "$fixture/other workspace/packages/other module/note.txt"
report=$(sh "$script" "$fixture/other workspace")
printf '%s\n' "$report" | grep -F '?? note.txt'

git -C "$fixture/other workspace/packages/other module" add note.txt
report=$(sh "$script" "$fixture/other workspace")
printf '%s\n' "$report" | grep -F 'A  note.txt'

if printf '%s\n' "$report" | grep -Eq '^(diff --git |@@ )'; then
    printf '❌ Status unexpectedly contains file patches\n' >&2
    exit 1
fi

git -C "$fixture/other workspace/packages/other module" \
    -c user.name=Fixture \
    -c user.email=fixture@example.invalid \
    -c commit.gpgsign=false \
    commit -qm "Fixture module change"

report=$(sh "$script" "$fixture/other workspace")
printf '%s\n' "$report" | grep -F '> Fixture module change'

git -C "$fixture/other workspace" add "packages/other module"
report=$(sh "$script" "$fixture/other workspace")
printf '%s\n' "$report" | grep -F '> Fixture module change'

mkdir "$fixture/other workspace/child"
report=$(cd "$fixture/other workspace/child" && sh "$script")
printf '%s\n' "$report" | grep -F 'packages/other module'

printf 'PASS: clean, untracked, staged, and caller-directory checks\n'
