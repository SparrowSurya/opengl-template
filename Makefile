# ─────────────────────────────────────────────────────────────────────────────
# Thin wrapper around CMake.  Targets:
#   make           → configure (debug) + build
#   make release   → configure (release) + build
#   make run       → build (debug) + run binary
#   make clean     → remove build/
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: all release run clean

BINARY := build/app

all: $(BINARY)

$(BINARY):
	cmake --preset default
	cmake --build --preset default

release:
	cmake --preset release
	cmake --build --preset release

run: all
	./$(BINARY)

clean:
	rm -rf build/