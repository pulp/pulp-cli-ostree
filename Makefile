PLUGINS=$(notdir $(wildcard pulpcore/cli/*))

info:
	@echo Pulp CLI
	@echo plugins: $(PLUGINS)

black:
	isort .
	cd pulp-glue-ostree; isort .
	black .

lint:
	find . -name '*.sh' -print0 | xargs -0 shellcheck -x
	isort -c --diff .
	cd pulp-glue-ostree; isort -c --diff .
	black --diff --check .
	flake8
	.ci/scripts/check_click_for_mypy.py
	mypy
	cd pulp-glue-ostree; mypy
	@echo "🙊 Code 🙈 LGTM 🙉 !"

tests/cli.toml:
	cp $@.example $@
	@echo "In order to configure the tests to talk to your test server, you might need to edit $@ ."

test: | tests/cli.toml
	pytest -v tests

site:
	mkdocs build

.PHONY: info black lint test
