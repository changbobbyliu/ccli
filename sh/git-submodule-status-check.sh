#!/bin/sh
set -eu

root=$(git -C "${1:-.}" rev-parse --show-toplevel)
cd "$root"

printf 'Repository: %s\n' "$root"

printf '\nWorking tree (empty means clean):\n'
git status --short --untracked-files=all --ignore-submodules=none

printf '\nRecursive submodule pins:\n'
git submodule status --recursive

printf '\nUnstaged submodule changes:\n'
git --no-pager diff --submodule=log

printf '\nStaged submodule changes:\n'
git --no-pager diff --cached --submodule=log

printf '\nInitialized submodule working trees:\n'
git submodule foreach --recursive '
    git status --short --untracked-files=all --ignore-submodules=none
'

printf '\nRemote comparison and URL-sync detection: not implemented yet.\n'
