AS ?= nasm
CC ?= $(ARCH)-gcc

LINK := linker.ld
A_SRC := $(wildcard src/$(ARCH)/*.c) $(wildcard src/$(ARCH)/*.asm)

%.o: %.asm
	$(AS) -o $@ $< $(ASFLAGS)

%.o: %.c
	$(CC) -c -ffreestanding -O2 -Wall -Wextra -std=gnu99\
	$(CFLAGS) $(CPPFLAGS)\
	-Isrc $< -o $@

$(PROJECT).bin: $(LINK) $(addsuffix .o, $(basename $(A_SRC) $(SRC))) src/arch.h
	$(CC) -T $(LINK) $(addsuffix .o, $(basename $(A_SRC) $(SRC))) -o $@ \
	-ffreestanding -O2 -nostdlib -lgcc $(LDFLAGS)
