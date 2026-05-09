.PHONY: install dry-run doctor deps cleanup cleanup-apply uninstall

install:
	./install

uninstall:
	./uninstall

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
