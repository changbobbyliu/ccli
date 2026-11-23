#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(git -C "${1:-.}" rev-parse --show-toplevel)
cd "$root"

CCLI_REPO_REPORTER="$script_dir/git-repo-status.sh"
export CCLI_REPO_REPORTER

CCLI_URL_CHECKER="$script_dir/git-submodule-url-check.sh"
export CCLI_URL_CHECKER

sh "$CCLI_REPO_REPORTER" workspace

git submodule foreach --quiet --recursive '
    sh "$CCLI_REPO_REPORTER" "$displaypath"

    sh "$CCLI_URL_CHECKER" "$toplevel" "$name" "$sm_path"
    
    git -C "$toplevel" --no-pager diff \
        --submodule=log --ignore-submodules=dirty \
        -- ":(literal)$sm_path"

    git -C "$toplevel" --no-pager diff --cached \
        --submodule=log --ignore-submodules=dirty \
        -- ":(literal)$sm_path"
'

printf '\nSubmodule pin issues (empty means none):\n'
git submodule status --recursive | sed -n '/^[-+U]/p'
