[arg("repo", long="repo", help="Repository path; defaults to the caller's checkout")]
[arg("action", pattern="status", help="Operation to perform")]
[doc("Inspect local changes and fetch upstream ahead/behind counts")]
[no-cd]
submodule action repo=invocation_directory():
    @sh {{ quote(source_directory() / "sh/git-submodule-status-check.sh") }} {{ quote(repo) }}

[doc("Run all shell tests recursively under sh/tests/")]
test:
    @sh {{ quote(source_directory() / "sh/test.sh") }}
