
GLUE_PLUGINS=$(notdir $(wildcard pulp-glue-ostree/src/pulp_glue/*))
CLI_PLUGINS=$(notdir $(wildcard src/pulpcore/cli/*))

.PHONY: info
info:
	@echo Pulp glue
	@echo plugins: $(GLUE_PLUGINS)
	@echo Pulp CLI
	@echo plugins: $(CLI_PLUGINS)

.PHONY: build
build:
	uv build --all

.PHONY: _format
_format:
	ruff format
	ruff check --select I --fix

.PHONY: format
format:
	uv run --isolated --group lint $(MAKE) _format

.PHONY: _autofix
_autofix:
	ruff check --fix

.PHONY: autofix
autofix:
	uv lock
	uv run --isolated --group lint $(MAKE) _autofix

.PHONY: _lint
_lint:
	find tests .ci -name '*.sh' -print0 | xargs -0 shellcheck -x
	ruff format --check --diff
	ruff check
	.ci/scripts/check_cli_dependencies.py
	.ci/scripts/check_click_for_mypy.py
	mypy
	cd pulp-glue-ostree; mypy
	@echo "🙊 Code 🙈 LGTM 🙉 !"

.PHONY: lint
lint:
	uv lock --check
	uv run --isolated --group lint $(MAKE) _lint

tests/cli.toml:
	cp $@.example $@
	@echo "In order to configure the tests to talk to your test server, you might need to edit $@ ."

.PHONY: _test
_test: | tests/cli.toml
	pytest -v tests pulp-glue-ostree/tests

.PHONY: test
test:
	uv run $(MAKE) _test

.PHONY: _livetest
_livetest: | tests/cli.toml
	pytest -v tests pulp-glue-ostree/tests -m live

.PHONY: livetest
livetest:
	uv run $(MAKE) _livetest

.PHONY: _paralleltest
_paralleltest: | tests/cli.toml
	pytest -v tests pulp-glue-ostree/tests -m live -n 8

.PHONY: paralleltest
paralleltest:
	uv run $(MAKE) _paralleltest

.PHONY: _unittest
_unittest:
	pytest -v tests pulp-glue-ostree/tests -m "not live"

.PHONY: unittest
unittest:
	uv run $(MAKE) _unittest

.PHONY: _unittest_glue
_unittest_glue:
	pytest -v pulp-glue-ostree/tests -m "not live"

.PHONY: unittest_glue
unittest_glue:
	uv run $(MAKE) _unittest_glue
