# Most supported architecture is i686-elf
ARCH ?= i686-elf

SRC := $(wildcard src/*.c)
OBJ := $(addsuffix .o, $(basename $(SRC)))
HEA := $(addsuffix .h, $(basename $(SRC)))
HEA += src/arch.h

PROJECT := yasOS

all: $(PROJECT).bin

# Headers with user config
src/arch.h:
	rm -rf arch.h
	echo \#include \"$(ARCH)/arch.h\" > src/arch.h
	
# Platform independent rules
%.h: %.c
	rm -f $@
	python3 mkheader.py $< $@

include src/$(ARCH)/Makefile

install: all
	ifdef DESTDIR
		cp $(PROJECT).bin $(DESTDIR)/boot/
	endif

clean:
	rm -rf $(OBJ) $(A_OBJ)
	
headerclean:
	rm -rf $(HEA) $(A_HEA)
	
realclean: clean headerclean ;

.PHONY: all install clean headerclean
