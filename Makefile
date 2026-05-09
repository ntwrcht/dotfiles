.PHONY: install dry-run doctor deps

install:
	./install

dry-run:
	./install --dry-run

doctor:
	./doctor

deps:
	brew bundle
