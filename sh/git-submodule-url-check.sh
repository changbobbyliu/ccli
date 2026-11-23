#!/bin/sh
set -eu

parent=$1
name=$2
path=$3
child="$parent/$path"

declared=$(git config --file "$parent/.gitmodules" \
    --get "submodule.$name.url" || :)

if [ -z "$declared" ]; then
    printf '  ❌ Submodule URL missing from .gitmodules\n'
    exit 0
fi

expected_parent=$declared
expected_child=$declared

case "$declared" in
    ./*|../*)
        script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

        if ! resolved=$(sh "$script_dir/git-submodule-url-resolve.sh" \
            "$parent" "$path" "$declared"); then
            printf '  ❌ URL comparison unavailable: resolution failed\n'
            exit 0
        fi

        expected_parent=$(printf '%s\n' "$resolved" | sed -n '1p')
        expected_child=$(printf '%s\n' "$resolved" | sed -n '2p')
        ;;
esac

registered=$(git -C "$parent" config --local \
    --get "submodule.$name.url" || :)

if [ -z "$registered" ]; then
    printf '  ○ Submodule URL not registered; initialization needed\n'
    exit 0
fi

branch=$(git -C "$child" symbolic-ref --quiet --short HEAD || :)
remote=
if [ -n "$branch" ]; then
    remote=$(git -C "$child" config \
        --get "branch.$branch.remote" || :)
fi

if [ -z "$remote" ]; then
    remote=origin
    if [ "$(git -C "$child" remote | wc -l)" -eq 1 ]; then
        remote=$(git -C "$child" remote)
    fi
fi

actual=$(git -C "$child" config --get "remote.$remote.url" || :)

if [ "$expected_parent" = "$registered" ] &&
    [ "$expected_child" = "$actual" ]; then
    printf '  ✅ URL configuration matches .gitmodules\n'
else
    printf '  ⚠ URL sync needed: %s\n' "$path"
    printf '    Run from the workspace root: git submodule sync --recursive\n'
fi
