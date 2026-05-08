#!/bin/bash

set -euo pipefail

sedi() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

remote=$(git remote get-url origin)
if [[ "$remote" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  username="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
else
  repo=$(basename "$(git rev-parse --show-toplevel)")
  read -rp "GitHub username: " username
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

cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
make all || exit 1

if ! git diff --quiet; then
  echo "pre-commit: files were modified by make all, please stage the changes and commit again"
  exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit

rm -- "$0"
