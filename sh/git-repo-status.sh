#!/bin/sh
set -eu

report_remote() {
    branch=$(git symbolic-ref --quiet --short HEAD || :)
    printf '\n%s · %s' "$1" "${branch:-detached HEAD}"

    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        printf '\n  ○ No commits yet\n'
        return
    fi

    if [ -z "$branch" ]; then
        printf '\n  ○ Remote comparison unavailable: detached HEAD\n'
        return
    fi

    remote=$(git config --get "branch.$branch.remote" || :)
    merge=$(git config --get "branch.$branch.merge" || :)
    if [ -z "$remote" ] || [ -z "$merge" ]; then
        printf '\n  ○ No upstream configured\n'
        return
    fi

    if [ "$remote" != "." ]; then
        if ! git fetch --quiet --prune --no-recurse-submodules -- "$remote"; then
            printf '\n  ❌ Remote status unknown: fetch failed\n'
            return
        fi
    fi

    if ! upstream=$(git rev-parse --abbrev-ref --symbolic-full-name \
        '@{upstream}' 2>/dev/null); then
        printf '\n  ○ Upstream branch unavailable\n'
        return
    fi
    printf ' → %s\n' "$upstream"

    if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
        printf '  ○ Counts unavailable: shallow history\n'
        return
    fi

    counts=$(git rev-list --left-right --count "HEAD...$upstream")
    read -r ahead behind <<EOF
$counts
EOF

    if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
        printf '  ✅ Up to date\n'
    else
        printf '  ↑ %s ahead  ↓ %s behind\n' "$ahead" "$behind"
    fi
}

report_remote "${1:-workspace}"

changes=$(git status --short --untracked-files=all --ignore-submodules=none)
if [ -n "$changes" ]; then
    printf '  ⚠ Local file changes:\n%s\n' "$changes"
else
    printf '  ✅ Working tree clean\n'
fi

# git --no-pager diff --submodule=log
# git --no-pager diff --cached --submodule=log