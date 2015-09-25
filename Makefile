# Most supported architecture is i686-elf
ARCH ?= i686-elf

SRC := $(wildcard src/*.c)

PROJECT := yasOS

all: $(PROJECT).bin

src/arch.h:
	$(file > src/arch.h,#include "$(ARCH)/arch.h")

include src/$(ARCH)/Makefile

.PHONY: all install

install: all
	ifdef DESTDIR
		cp $(PROJECT).bin $(DESTDIR)/boot/
	endif
