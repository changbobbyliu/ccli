#!/bin/sh
set -eu

parent=$(git -C "$1" rev-parse --show-toplevel)
path=$2
declared=$3

branch=$(git -C "$parent" symbolic-ref --quiet --short HEAD || :)
remote=
if [ -n "$branch" ]; then
    remote=$(git -C "$parent" config \
        --get "branch.$branch.remote" || :)
fi

if [ -z "$remote" ]; then
    remote=origin
    if [ "$(git -C "$parent" remote | wc -l)" -eq 1 ]; then
        remote=$(git -C "$parent" remote)
    fi
fi

base=$(git -C "$parent" config --get "remote.$remote.url" || :)
[ -n "$base" ] || base=$parent

format=$(git -C "$parent" rev-parse --show-object-format)
oid=$(git -C "$parent/$path" rev-parse HEAD)

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# Isolate all subsequent Git operations from the inspected repository.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
unset GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

git init -q --template= --object-format="$format" "$scratch"
mkdir -p "$scratch/$path"
git init -q --template= --object-format="$format" "$scratch/$path"

git -C "$scratch" config remote.origin.url "$base"
git -C "$scratch" config --file .gitmodules submodule.probe.path "$path"
git -C "$scratch" config --file .gitmodules submodule.probe.url "$declared"
git -C "$scratch" config submodule.probe.url pending
git -C "$scratch" config submodule.probe.active true
git -C "$scratch/$path" config remote.origin.url pending

git -C "$scratch" update-index --add --cacheinfo 160000 "$oid" "$path"
git -C "$scratch" submodule sync -- ":(literal)$path" >/dev/null

git -C "$scratch" config --get submodule.probe.url
git -C "$scratch/$path" config --get remote.origin.url
