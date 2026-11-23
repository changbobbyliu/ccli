
#!/bin/sh
set -eu

test_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script="$test_dir/../git-submodule-status-check.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

commit() {
    git -C "$1" -c user.name=Fixture \
        -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false \
        commit -qm "$2" --allow-empty
}

expect() {
    report=$(sh "$script" "$1")
    if ! printf '%s\n' "$report" | grep -F "$2"; then
        printf '❌ Expected: %s\n%s\n' "$2" "$report" >&2
        exit 1
    fi
}

git init --bare -q "$fixture/remote.git"
git init -q -b trunk "$fixture/seed"
commit "$fixture/seed" Initialize
git -C "$fixture/seed" remote add origin "$fixture/remote.git"
git -C "$fixture/seed" push -qu origin trunk

git clone -q --branch trunk "$fixture/remote.git" "$fixture/local"
git clone -q --branch trunk "$fixture/remote.git" "$fixture/behind"

expect "$fixture/local" '✅ Up to date'

commit "$fixture/local" 'Local change'
expect "$fixture/local" '↑ 1 ahead  ↓ 0 behind'

commit "$fixture/seed" 'Remote change'
git -C "$fixture/seed" push -q origin trunk

expect "$fixture/behind" '↑ 0 ahead  ↓ 1 behind'
expect "$fixture/local" '↑ 1 ahead  ↓ 1 behind'

git -C "$fixture/local" branch --unset-upstream
expect "$fixture/local" '○ No upstream configured'

git -C "$fixture/local" checkout -q --detach
expect "$fixture/local" '○ Remote comparison unavailable: detached HEAD'
git -C "$fixture/local" checkout -q trunk

git -C "$fixture/local" branch \
    --set-upstream-to=origin/trunk >/dev/null
git -C "$fixture/local" remote set-url origin "$fixture/missing.git"
expect "$fixture/local" '❌ Remote status unknown: fetch failed'
