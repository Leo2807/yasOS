AS ?= nasm
CC ?= $(ARCH)-gcc

LINK := src/$(ARCH)/linker.ld
A_SRC := $(wildcard src/$(ARCH)/*.c) $(wildcard src/$(ARCH)/*.asm)
A_OBJ := $(addsuffix .o, $(basename $(A_SRC)))
A_HEA := $(addsuffix .h, $(basename $(wildcard src/$(ARCH)/*.c)))

%.o: %.asm
	$(AS) -o $@ $< $(ASFLAGS)

%.o: %.c $(A_HEA) $(HEA)
	@echo $<
	$(CC) -c -ffreestanding -O2 -Wall -Wextra -std=gnu99\
	$(CFLAGS) $(CPPFLAGS)\
	-I $(dir $<) -I src $< -o $@

$(PROJECT).bin: $(LINK) $(A_OBJ) $(OBJ) $(A_HEA) $(HEA) src/arch.h
	$(CC) -T $(LINK) $(addsuffix .o, $(basename $(A_SRC) $(SRC))) -o $@ \
	-ffreestanding -O2 -nostdlib -lgcc $(LDFLAGS)
