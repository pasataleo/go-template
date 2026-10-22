#!/bin/bash

set -euo pipefail

sedi() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Derive owner/repo from the origin remote so this works from worktrees, where
# the checkout directory is named after the branch rather than the repo.
if remote=$(git remote get-url origin 2>/dev/null); then
  remote=${remote%.git}
  repo=${remote##*/}
  owner=${remote%/*}
  username=${owner##*[:/]}
else
  toplevel=$(git rev-parse --show-toplevel)
  repo=$(basename "$toplevel")
  username=$(basename "$(dirname "$toplevel")")
fi
module="github.com/${username}/${repo}"

sedi "s|github.com/pasataleo/go-template|${module}|g" go.mod main.go
sedi "s|go-template|${repo}|" main.go
sedi "s|# go-template|# ${repo}|" README.md

read -rp "Is this an executable or a library? [exe/lib] " project_type

mv .github/workflow-templates .github/workflows

if [[ "${project_type}" == "lib" ]]; then
  rm -f main.go
  rm -rf version/
  sedi 's|go build -o bin/go-template main.go|go build ./...|' Makefile
  rm .github/workflows/release-exe.yml
  mv .github/workflows/release-lib.yml .github/workflows/release.yml
else
  sedi "s|bin/go-template|bin/${repo}|" Makefile
  rm .github/workflows/release-lib.yml
  mv .github/workflows/release-exe.yml .github/workflows/release.yml
fi

# Resolves to the shared hooks directory in both regular clones and worktrees.
hooks=$(git rev-parse --path-format=absolute --git-path hooks)
mkdir -p "$hooks"

cat > "$hooks/pre-commit" << 'HOOK'
#!/bin/bash
set -euo pipefail

# Check exactly what is being committed. If there are unstaged or untracked
# changes, export the index to a temporary directory and check that instead, so
# files left out of the commit can't make the checks pass or fail.
dir=$(pwd)
if ! git diff --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  dir=$(mktemp -d)
  trap 'rm -rf "$dir"' EXIT
  git checkout-index --all --prefix="$dir/"
fi

(cd "$dir" && make all)

# Compare the checked tree against the index to see if make all changed it.
if ! git --work-tree="$dir" diff --quiet ||
   [[ -n "$(git --work-tree="$dir" ls-files --others --exclude-standard)" ]]; then
  echo "pre-commit: make all modified files, please run make all, stage the changes and commit again"
  exit 1
fi
HOOK
chmod +x "$hooks/pre-commit"

rm -- "$0"
