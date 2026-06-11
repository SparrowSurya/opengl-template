# -----------------------------------------------------------------------------
# CMake wrapper
#
# Targets:
#   make            Build debug
#   make debug      Build debug
#   make release    Build release
#   make run        Build debug and run
#   make run-release Build release and run
#   make configure  Configure debug preset
#   make rebuild    Clean and rebuild debug
#   make rebuild-release Clean and rebuild release
#   make clean      Remove build directory
# -----------------------------------------------------------------------------

.PHONY: all debug release run run-release \
        configure configure-release \
        rebuild rebuild-release clean

DEBUG_PRESET   := default
RELEASE_PRESET := release

DEBUG_BIN      := build/app
RELEASE_BIN    := build/app

all: debug

# Configure only
configure:
	cmake --preset $(DEBUG_PRESET)

configure-release:
	cmake --preset $(RELEASE_PRESET)

# Build
debug: configure
	cmake --build --preset $(DEBUG_PRESET)

release: configure-release
	cmake --build --preset $(RELEASE_PRESET)

# Run
run: debug
	./$(DEBUG_BIN)

run-release: release
	./$(RELEASE_BIN)

# Force a complete rebuild
rebuild: clean debug

rebuild-release: clean release

# Clean everything
clean:
	rm -rf build