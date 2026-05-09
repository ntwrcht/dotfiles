.PHONY: install dry-run doctor deps cleanup cleanup-apply

install:
	./install

dry-run:
	./install --dry-run

doctor:
	./doctor

deps:
	brew bundle

cleanup:
	./cleanup-deps

cleanup-apply:
	./cleanup-deps --apply
