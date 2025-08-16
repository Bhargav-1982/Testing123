# ============================================================================
# Compiler settings
CC = gcc
CFLAGS = -std=c17 -Wall -Wextra -Werror -pedantic -g -O0
LDFLAGS = 

# ============================================================================
# Project settings - Student Grade Management System
TARGET = calc
SOURCES = $(wildcard *.c)
HEADERS = $(wildcard *.h)
# ============================================================================
# Build Rules
# ============================================================================

# Default target - builds the grade management system
all: $(TARGET)

# Main build rule - creates the executable
$(TARGET): $(SOURCES) $(HEADERS)
	@echo "Building $(TARGET)..."
	$(CC) $(CFLAGS) $(SOURCES) -o $(TARGET) $(LDFLAGS)
	@echo "Build successful! Run with: ./$(TARGET)"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -f $(TARGET) *.o 
	@echo "Cleanup complete."

# Rebuild everything from scratch
rebuild: clean all

# Show available commands
help:
	@echo "Available commands:"
	@echo "  make           - Build the program"		
	@echo "  make clean     - Remove generated files"
	@echo "  make rebuild   - Clean and build from scratch"

# Declare phony targets
.PHONY: all clean rebuild help
