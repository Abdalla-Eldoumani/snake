# Makefile for Snake AArch64

# Toolchain
AS := gcc
ASFLAGS := -nostdlib -static -g -Wa,-Isrc -o

# Source files
SRC_DIR := src
SOURCES := $(wildcard $(SRC_DIR)/*.s)
EXEC := snake

# Default target
all: $(EXEC)

$(EXEC): $(SOURCES)
	$(AS) $(ASFLAGS) $(EXEC) $(SOURCES)

# Clean up build artifacts
clean:
	rm -f $(EXEC)

.PHONY: all clean 