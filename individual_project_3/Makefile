# SystemC SoC Project Makefile

# Check if SYSTEMC_HOME is set, otherwise provide guidance
ifndef SYSTEMC_HOME
$(warning SYSTEMC_HOME is not set. Please set it to your SystemC installation directory.)
$(warning Example: make SYSTEMC_HOME=/opt/systemc-2.3.3)
endif

# Architecture and OS-specific settings
ARCH = $(shell uname -m)
OS = $(shell uname -s)

# Check for Apple Silicon specifically
ifeq ($(OS),Darwin)
    ifeq ($(shell echo $(ARCH) | grep -E 'arm64|aarch64'),$(ARCH))
        APPLE_SILICON = 1
    endif
endif

# Set library directory based on architecture and OS
ifeq ($(OS),Darwin)
    # macOS specific paths
    ifdef APPLE_SILICON
        # Apple Silicon requires CMake build which uses lib/
        SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib
    else
        # Intel Mac - check if lib directory exists first (CMake build)
        ifneq ($(wildcard $(SYSTEMC_HOME)/lib),)
            SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib
        else
            # Fall back to traditional build path
            SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib-macosx
        endif
    endif
else
    # Linux paths
    ifeq ($(ARCH),x86_64)
        SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib-linux64
    else
        SYSTEMC_LIBDIR ?= $(SYSTEMC_HOME)/lib
    endif
endif

# SystemC paths
SYSTEMC_INCLUDE = $(SYSTEMC_HOME)/include

# Compiler and flags
CXX = g++
CXXFLAGS = -std=c++11 -Wall -I$(SYSTEMC_INCLUDE)

# Add arm64 flag if on Apple Silicon
ifdef APPLE_SILICON
    CXXFLAGS += -arch arm64
endif

LDFLAGS = -L$(SYSTEMC_LIBDIR) -lsystemc -lm

# Add -Wl,-rpath for Linux (not needed for macOS which uses DYLD_LIBRARY_PATH)
ifneq ($(OS),Darwin)
    LDFLAGS += -Wl,-rpath=$(SYSTEMC_LIBDIR)
endif

# Source files and target names
SRCS = task1_alu.cpp task2_fibonacci.cpp task3_shift_register.cpp
TARGETS = task1_alu task2_fibonacci task3_shift_register

# Default target: build all
all: $(TARGETS)

# Individual targets
task1_alu: task1_alu.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

task2_fibonacci: task2_fibonacci.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

task3_shift_register: task3_shift_register.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

# Clean target
clean:
	rm -f $(TARGETS) *.vcd

# Run targets
run_task1: task1_alu
	./task1_alu

run_task2: task2_fibonacci
	./task2_fibonacci

run_task3: task3_shift_register
	./task3_shift_register

# Run all targets
run: run_task1 run_task2 run_task3

# Help target
help:
	@echo "Available targets:"
	@echo "  all         - Build all targets (default)"
	@echo "  task1_alu   - Build ALU task"
	@echo "  task2_fibonacci - Build Fibonacci Generator task"
	@echo "  task3_shift_register - Build Shift Register task"
	@echo "  run_task1   - Run ALU task"
	@echo "  run_task2   - Run Fibonacci Generator task" 
	@echo "  run_task3   - Run Shift Register task"
	@echo "  run         - Run all tasks"
	@echo "  clean       - Remove built targets and VCD files"
	@echo ""
	@echo "Environment variables:"
	@echo "  SYSTEMC_HOME    - Set to your SystemC installation directory"
	@echo "  SYSTEMC_LIBDIR  - Optional: Override the SystemC library directory"

# Set appropriate library path for the OS
ifeq ($(OS),Darwin)
    # macOS uses DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH := $(SYSTEMC_LIBDIR):$(DYLD_LIBRARY_PATH)
else
    # Linux uses LD_LIBRARY_PATH
    export LD_LIBRARY_PATH := $(SYSTEMC_LIBDIR):$(LD_LIBRARY_PATH)
endif

# Phony targets
.PHONY: all clean run run_task1 run_task2 run_task3 help

# Print system information
system-info:
	@echo "System information:"
	@echo "  OS: $(OS)"
	@echo "  Architecture: $(ARCH)"
ifdef APPLE_SILICON
	@echo "  Detected: Apple Silicon (arm64/aarch64)"
	@echo "  NOTE: Apple Silicon requires CMake for SystemC builds"
endif
	@echo "  Using library directory: $(SYSTEMC_LIBDIR)"
	@echo "  SystemC include directory: $(SYSTEMC_INCLUDE)"
	@echo ""
	@echo "Library directory existence check:"
	@if [ -d "$(SYSTEMC_LIBDIR)" ]; then \
		echo "  ✓ Library directory exists"; \
	else \
		echo "  ✗ WARNING: Library directory does not exist"; \
		echo "    Please check your SystemC installation and environment variables"; \
		ifdef APPLE_SILICON \
			echo "    For Apple Silicon, you MUST use CMake to build SystemC"; \
			echo "    See the systemc_installation_guide.md for Apple Silicon instructions"; \
		endif \
	fi
	@echo ""
	@echo "Include directory existence check:"
	@if [ -d "$(SYSTEMC_INCLUDE)" ]; then \
		echo "  ✓ Include directory exists"; \
	else \
		echo "  ✗ WARNING: Include directory does not exist"; \
		echo "    Please check your SystemC installation and environment variables"; \
	fi
	@echo ""
	@echo "If you need help setting up SystemC, see systemc_installation_guide.md"

# Extend help target
help: system-info