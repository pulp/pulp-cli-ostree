# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains two related Python packages for managing OSTree content in [Pulp](https://pulpproject.org/):

- **`pulp-cli-ostree`** (root): CLI plugin that adds `pulp ostree` subcommands to the `pulp` CLI tool. Built on [Click](https://click.palletsprojects.com/) and the `pulp-cli` framework.
- **`pulp-glue-ostree`** (`pulp-glue-ostree/`): Version-agnostic Python library that talks to the Pulp REST API. Provides context classes consumed by the CLI layer.

The CLI layer (`pulpcore/cli/ostree/`) depends on the glue layer (`pulp-glue-ostree/pulp_glue/ostree/`). Both use Python namespace packages.

## Commands

### Linting
```bash
make lint          # shellcheck + ruff format check + ruff check + mypy (both packages)
make format        # auto-fix with ruff format and ruff check --fix
```

### Testing
```bash
make unittest      # run tests not marked as "live" (no server needed)
make test          # run all tests (requires a running Pulp server)
make livetest      # run only tests marked as "live"
```

To run a single test file or specific test:
```bash
python3 -m pytest -v tests/test_help_pages.py
python3 -m pytest -v tests/test_help_pages.py::test_access_help
python3 -m pytest -v pulp-glue-ostree/tests/
```

Tests require `tests/cli.toml` (copy from `tests/cli.toml.example` and configure for your Pulp instance).

### Building
```bash
make build         # builds both packages with pyproject-build
```

## Architecture

### Two-Layer Design

**Glue layer** (`pulp-glue-ostree/pulp_glue/ostree/context.py`): Defines `PulpEntity*Context` classes that map to Pulp REST API resources. Each class declares:
- `PLUGIN`, `RESOURCE_TYPE`, `HREF`, `ID_PREFIX` — API identifiers
- `NEEDS_PLUGINS` — minimum Pulp plugin version requirements
- `CAPABILITIES` — optional feature flags (e.g., `sync`, `import_all`)
- Custom methods for non-standard API calls (e.g., `import_all`, `import_commits`)

**CLI layer** (`pulpcore/cli/ostree/`): Three modules, one per resource type:
- `repository.py` — `pulp ostree repository` commands (list, show, create, update, destroy, sync, import-all, import-commits, content subcommands)
- `remote.py` — `pulp ostree remote` commands
- `distribution.py` — `pulp ostree distribution` commands

The CLI uses generic command factories from `pulpcore.cli.common.generic` (e.g., `list_command`, `create_command`, `show_command`) to avoid boilerplate. Commands are assembled by calling `repository.add_command(...)` with these factories.

### Plugin Registration

The CLI plugin is registered via an entry point in `pyproject.toml`:
```toml
[project.entry-points."pulp_cli.plugins"]
ostree = "pulpcore.cli.ostree"
```

The `mount()` function in `pulpcore/cli/ostree/__init__.py` is called by the `pulp-cli` framework to attach the `ostree` group to the main CLI.

### Test Structure

- `tests/test_help_pages.py` — unit test (no server) that traverses all CLI commands and verifies `--help` works
- `tests/scripts/pulp_ostree/` — shell scripts for integration tests against a live Pulp server
- `pulp-glue-ostree/tests/` — glue layer tests

Shell test scripts use helper functions from `tests/scripts/config.source` (`expect_succ`, `expect_fail`, `assert`).

## Key Conventions

- Both packages share the same version string (currently `0.7.0.dev`), managed by `bump-my-version` across multiple files.
- Changelog entries go in `CHANGES/` (CLI) or `CHANGES/pulp-glue-ostree/` (glue), using towncrier with types: `feature`, `bugfix`, `removal`, `devel`, `misc`.
- Type checking is strict (`mypy --strict`). Run `mypy` from root for CLI, `cd pulp-glue-ostree; mypy` for glue.
- Line length: 100 characters (ruff).
- Import order enforces `pulp_glue` as a "second-party" section between third-party and first-party.
- Many sections in `pyproject.toml` are managed by cookiecutter templates — comments say "managed by the cookiecutter templates."
