
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
	cd pulp-glue-ostree; pyproject-build -n
	pyproject-build -n

.PHONY: format
format:
	ruff format
	ruff check --fix

.PHONY: lint
lint:
	find tests .ci -name '*.sh' -print0 | xargs -0 shellcheck -x
	ruff format --check --diff
	ruff check --diff
	.ci/scripts/check_cli_dependencies.py
	.ci/scripts/check_click_for_mypy.py
	mypy
	cd pulp-glue-ostree; mypy
	@echo "🙊 Code 🙈 LGTM 🙉 !"

tests/cli.toml:
	cp $@.example $@
	@echo "In order to configure the tests to talk to your test server, you might need to edit $@ ."

.PHONY: test
test: | tests/cli.toml
	python3 -m pytest -v tests pulp-glue-ostree/tests

.PHONY: livetest
livetest: | tests/cli.toml
	python3 -m pytest -v tests pulp-glue-ostree/tests -m live

.PHONY: paralleltest
paralleltest: | tests/cli.toml
	python3 -m pytest -v tests pulp-glue-ostree/tests -m live -n 8

.PHONY: unittest
unittest:
	python3 -m pytest -v tests pulp-glue-ostree/tests -m "not live"

.PHONY: unittest_glue
unittest_glue:
	python3 -m pytest -v pulp-glue-ostree/tests -m "not live"
