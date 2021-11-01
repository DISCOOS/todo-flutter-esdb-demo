# Default host IP
HOST = 0.0.0.0

# Detect operating system in Makefile.
ifeq ($(OS),Windows_NT)
	OSNAME = WIN32
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSNAME = LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSNAME = OSX
		# Mac OSX workaround
		HOST = host.docker.internal
	endif
endif

.PHONY: \
	configure certs models action test doc release

.SILENT: \
	configure certs models action test doc release

configure:
	dart pub global activate pub_release
	dart pub global activate critical_test
	dart pub global activate dcli
	dart pub global activate eventstore_client_test

certs:
	esdbtcli certs --out test

models:
	echo "Generating models..."; \
	flutter pub run build_runner build --delete-conflicting-outputs; \
	echo "[✓] Generating models complete."


test:
	if [ ! -d test/certs ]; then esdbtcli certs --out test; fi
	dart test -j 1

release:
	echo 'Release to pub.dev...'
	pub_release --no-test
