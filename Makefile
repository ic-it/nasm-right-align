
ASSM=nasm
ASSMFLAGS=-f elf64 -g -F DWARF
DBGR=gdb
DBGR_ARGS= \
	--eval-command="set disassembly-flavor intel" \
	--eval-command="layout asm" \
	--eval-command="layout reg" \
	--eval-command="ref" \
	--eval-command="break _start" \
	--eval-command="run" \
	--eval-command="si"
LINKER=ld


SRC=./src
BIN=./bin
SRCS=$(wildcard $(SRC)/*.asm)
OBJS=$(patsubst $(SRC)/%.asm,$(BIN)/%.o,$(SRCS))

all: $(BIN)/main

$(BIN)/%.o: $(SRC)/%.asm
	@mkdir -p $(BIN)
	$(ASSM) $(ASSMFLAGS) $< -o $@

$(BIN)/main: $(OBJS)
	@mkdir -p $(BIN)
	$(LINKER) -o $@ $^

debug: $(BIN)/main
	$(DBGR) $(DBGR_ARGS) $(BIN)/main --args $(BIN)/main test.txt 

clean:
	rm -f $(BIN)/*

