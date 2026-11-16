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

rm -- "$0"
