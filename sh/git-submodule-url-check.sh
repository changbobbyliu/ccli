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

case "$declared" in
    ./*|../*)
        printf '  ○ Relative URL comparison: not implemented yet\n'
        exit 0
        ;;
esac

registered=$(git -C "$parent" config --local \
    --get "submodule.$name.url" || :)

if [ -z "$registered" ]; then
    printf '  ○ Submodule URL not registered; initialization needed\n'
    exit 0
fi

branch=$(git -C "$child" symbolic-ref --quiet --short HEAD || :)
remote=origin
if [ -n "$branch" ]; then
    remote=$(git -C "$child" config \
        --get "branch.$branch.remote" || printf 'origin')
fi

actual=$(git -C "$child" config --get "remote.$remote.url" || :)

if [ "$declared" = "$registered" ] && [ "$declared" = "$actual" ]; then
    printf '  ✅ URL configuration matches .gitmodules\n'
else
    printf '  ⚠ URL sync needed: %s\n' "$path"
    printf '    Run from the workspace root: git submodule sync --recursive\n'
fi
