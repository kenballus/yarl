PYXS = $(wildcard yarl/*.pyx)
SRC = yarl tests

all: test


.install-deps: $(shell find requirements -type f)
	pip install -U -r requirements/dev.txt
	pre-commit install
	@touch .install-deps


.install-cython: requirements/cython.txt
	pip install -r requirements/cython.txt
	touch .install-cython


yarl/%.c: yarl/%.pyx
	python -m cython -3 -o $@ $< -I yarl


.cythonize: .install-cython $(PYXS:.pyx=.c)


cythonize: .cythonize


.develop: .install-deps $(shell find yarl -type f)
	@pip install -e . --config-settings=--pure-python=false
	@touch .develop

fmt:
ifdef CI
	pre-commit run --all-files --show-diff-on-failure
else
	pre-commit run --all-files
endif

lint: fmt

test: lint .develop
	pytest ./tests ./yarl


vtest: lint .develop
	pytest ./tests ./yarl -v


cov: lint .develop
	pytest --cov yarl --cov-report html --cov-report term ./tests/ ./yarl/
	@echo "open file://`pwd`/htmlcov/index.html"


doc: doctest doc-spelling
	make -C docs html SPHINXOPTS="-W -E --keep-going -n"
	@echo "open file://`pwd`/docs/_build/html/index.html"


doctest: .develop
	make -C docs doctest SPHINXOPTS="-W -E --keep-going -n"


doc-spelling:
	make -C docs spelling SPHINXOPTS="-W -E --keep-going -n"
