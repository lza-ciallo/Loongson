# Simple Makefile for converting .s assembly files to .txt binary machine code
# Author: Created for LoongArch assembly to binary conversion
# Usage: make -f Makefile [target]

# Configuration
ASM_FILES = $(wildcard *.s)
TXT_FILES = $(ASM_FILES:.s=.txt)
OBJ_FILES = $(ASM_FILES:.s=.o)
ELF_FILES = $(ASM_FILES:.s=.elf)
BIN_FILES = $(ASM_FILES:.s=.bin)

# LoongArch toolchain
AS = loongarch32r-linux-gnusf-as
LD = loongarch32r-linux-gnusf-ld
OBJCOPY = loongarch32r-linux-gnusf-objcopy

# Assembly flags
ASFLAGS = -mabi=ilp32

# Default target
default: all

# Generate all .txt files from .s files
all: $(TXT_FILES)
	@echo "=== All assembly files converted to binary machine code ==="
	@echo "Generated files: $(TXT_FILES)"

# Rule to convert .s -> .o -> .elf -> .bin -> .txt
%.txt: %.bin
	@echo "Converting $< to $@..."
    # (HEX version) 
    # xxd -p -c 4 $< | tr -d '\n' | sed 's/\(........\)/\1\n/g' > $@
    # (Binary version)
	xxd -b -c 4 $< | awk '{print $$2$$3$$4$$5}' | sed 's/ //g' > $@


%.bin: %.elf
	@echo "Extracting binary from $<..."
	$(OBJCOPY) -O binary $< $@

%.elf: %.o
	@echo "Linking $< to $@..."
	$(LD) $< -o $@

%.o: %.s
	@echo "Assembling $< to $@..."
	$(AS) $(ASFLAGS) $< -o $@

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f $(OBJ_FILES) $(ELF_FILES) $(BIN_FILES) $(TXT_FILES)
	@echo "Clean completed."

# Show available .s files
list:
	@echo "Available .s assembly files:"
	@echo "$(ASM_FILES)"
	@echo ""
	@echo "Will generate .txt files:"
	@echo "$(TXT_FILES)"

# Convert specific file (usage: make -f Makefile convert FILE=example.s)
convert:
ifdef FILE
	@if [ -f "$(FILE)" ]; then \
		echo "Converting $(FILE) to $(FILE:.s=.txt)..."; \
		make -f Makefile $(FILE:.s=.txt); \
	else \
		echo "Error: File $(FILE) not found!"; \
		exit 1; \
	fi
else
	@echo "Usage: make -f Makefile convert FILE=filename.s"
endif

# Help information
help:
	@echo "================================================================"
	@echo "=== LoongArch Assembly to Binary Machine Code Converter ==="
	@echo "================================================================"
	@echo "Available targets:"
	@echo "  make -f Makefile          : Convert all .s files to .txt"
	@echo "  make -f Makefile all      : Same as above"
	@echo "  make -f Makefile list     : Show available .s files"
	@echo "  make -f Makefile convert FILE=xxx.s : Convert specific file"
	@echo "  make -f Makefile clean    : Remove all generated files"
	@echo "  make -f Makefile help     : Show this help"
	@echo ""
	@echo "Process: .s -> .o -> .elf -> .bin -> .txt"
	@echo "Output: .txt files contain bin machine code (32 bytes per line)"
	@echo "================================================================"

# Show detailed process for debugging
debug: SHELL:=/bin/bash
debug:
	@echo "=== Debug Information ==="
	@echo "ASM_FILES: $(ASM_FILES)"
	@echo "TXT_FILES: $(TXT_FILES)"
	@echo "OBJ_FILES: $(OBJ_FILES)"
	@echo "ELF_FILES: $(ELF_FILES)"
	@echo "BIN_FILES: $(BIN_FILES)"
	@echo "Toolchain:"
	@echo "  AS: $(AS)"
	@echo "  LD: $(LD)"
	@echo "  OBJCOPY: $(OBJCOPY)"

.PHONY: default all clean list convert help debug
