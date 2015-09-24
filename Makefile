AS ?= nasm

vpath %.c src
vpath %.asm src
vpath %.o src

all: yasOS.bin

%.o: %.asm
	$(AS) -o $@ $< $(ASFLAGS)

%.o: %.c
	$(CC) -c -ffreestanding -O2 -Wall -Wextra -std=gnu99 $(CFLAGS) $(CPPFLAGS) $< -o $@
 
yasOS.bin: linker.ld main.o start.o scrn.o gdt.o idt.o isrs.o irq.o timer.o
	$(CC) -T $^ -o $@ -ffreestanding -O2 -nostdlib -lgcc

.PHONY: all
