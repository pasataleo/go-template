# go-template

A template repository for Go projects. Requires macOS or Linux.

## Setup

After creating a new repository from this template, run:

```sh
./setup.sh
```

This will:

- Update the Go module path to match your repository name
- Configure the project as an executable or library
- Install a git pre-commit hook that runs `make all` against the staged changes and fails if it modifies any files
- Set up the release workflow for the chosen project type
- Delete itself

## Make targets

- `make all` — run tidy, generate, fmt, lint, test, and build
- `make tidy` — run `go mod tidy`
- `make generate` — run `go generate ./...`
- `make fmt` — run `go fmt ./...`
- `make lint` — run golangci-lint, installing the pinned version if needed
- `make test` — run `go test ./...`
- `make build` — build the binary (or verify compilation for libraries); local builds report version `dev`

## Releasing

`CHANGELOG.md` keeps the notes for every release, newest first. Each release has its own `# vX.Y.Z` section; start a new one by copying the commented-out section template to the top of the file.

Once the section for the release is merged, tag the commit:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow runs the build checks, then creates a GitHub release using the notes under the matching heading in `CHANGELOG.md`. It fails if that section is missing or contains only comments.
