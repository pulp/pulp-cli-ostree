
GLUE_PLUGINS=$(notdir $(wildcard pulp-glue-ostree/pulp_glue/*))
CLI_PLUGINS=$(notdir $(wildcard pulpcore/cli/*))

info:
	@echo Pulp glue
	@echo plugins: $(GLUE_PLUGINS)
	@echo Pulp CLI
	@echo plugins: $(CLI_PLUGINS)

build:
	cd pulp-glue-ostree; pyproject-build -n
	pyproject-build -n

black:
	isort .
	cd pulp-glue-ostree; isort .
	black .

lint:
	find tests .ci -name '*.sh' -print0 | xargs -0 shellcheck -x
	isort -c --diff .
	cd pulp-glue-ostree; isort -c --diff .
	black --diff --check .
	flake8
	.ci/scripts/check_click_for_mypy.py
	MYPYPATH=pulp-glue-ostree mypy
	cd pulp-glue-ostree; mypy
	@echo "🙊 Code 🙈 LGTM 🙉 !"

tests/cli.toml:
	cp $@.example $@
	@echo "In order to configure the tests to talk to your test server, you might need to edit $@ ."

test: | tests/cli.toml
	pytest -v tests
.PHONY: build info black lint test
