OUTPUT_FORMAT(elf32-i386)
ENTRY(start)
SECTIONS
{
 /* The kernel will live at 3GB + 1MB in the virtual
    address space, which will be mapped to 1MB in the
    physical address space. */
  . = 0xC0100000;
   
  .text : AT(ADDR(.text) - 0xC0000000) {
    code = .;
    *(.text)
    *(.rodata*)
  }
  .data ALIGN(0x1000) : AT(ADDR(.data) - 0xC0000000)
  {
    data = .;
    *(.data)
    . = ALIGN(4096);
  }
  .bss : AT(ADDR(.bss) - 0xC0000000)
  {
    bss = .;
    *(.bss)
  }
  end = .;
}
