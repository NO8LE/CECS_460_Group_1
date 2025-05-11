# Makefile for AES SystemC Simulation

# SystemC installation directory
SYSTEMC_HOME ?= /usr/local/systemc-2.3.3

# Compiler and flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall -I$(SYSTEMC_HOME)/include -I./include
LDFLAGS = -L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread

# Source and object files
SRC_DIR = src
TEST_DIR = test
OBJ_DIR = obj
BIN_DIR = bin

# Create directories if they don't exist
$(shell mkdir -p $(OBJ_DIR) $(BIN_DIR))

# Source files
SRC_FILES = $(wildcard $(SRC_DIR)/*.cpp)
TEST_FILES = $(wildcard $(TEST_DIR)/*.cpp)

# Object files
SRC_OBJ = $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRC_FILES))
TEST_OBJ = $(patsubst $(TEST_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(TEST_FILES))

# Targets
all: simulation testbench

simulation: $(BIN_DIR)/aes_simulation
testbench: $(BIN_DIR)/aes_testbench

# Simulation executable
$(BIN_DIR)/aes_simulation: $(OBJ_DIR)/aes_simulation.o
	$(CXX) $^ -o $@ $(LDFLAGS)

# Testbench executable
$(BIN_DIR)/aes_testbench: $(OBJ_DIR)/aes_testbench.o
	$(CXX) $^ -o $@ $(LDFLAGS)

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Compile test files
$(OBJ_DIR)/%.o: $(TEST_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Clean
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

# Run simulation
run_simulation: simulation
	$(BIN_DIR)/aes_simulation

# Run testbench
run_testbench: testbench
	$(BIN_DIR)/aes_testbench

.PHONY: all simulation testbench clean run_simulation run_testbench