
SRC = "./src"
CXX = gcc
OUT = "./out"
NASM = "./nasm"

build:
	@mkdir -p $(OUT)
	$(CXX) -o $(OUT)/main $(SRC)/main.c


generate-nasm-code:
	@mkdir -p $(NASM)
	$(CXX) -S -o $(NASM)/main.s $(SRC)/main.c
