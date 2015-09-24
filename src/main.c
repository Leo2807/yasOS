#include "system.h"

unsigned char *memcpy(void *dest, const void *src, int count)
{
	const char *sp = (const char *)src;
	char *dp = (char *)dest;
	
    for(;count > 0; count--) {
		*dp++ = *sp++;
	}
	
	return dest;
}

unsigned char *memset(void *dest, char val, int count)
{
	char *dp = (char*)dest;
    for(;count > 0; count--) {
		*dp++ = val;
	}
	
	return dest;
}

unsigned short *memsetw(void *dest, short val, int count)
{
    short *dp = (short*)dest;
    for(;count > 0; count--) {
		*dp++ = val;
	}
	
	return dest;
}

int strlen(const char *str)
{
    int len = 0;
    while (str[len] != '\0')
		len++;
	
	return len;
}

/* We will use this later on for reading from the I/O ports to get data
*  from devices such as the keyboard. We are using what is called
*  'inline assembly' in these routines to actually do the work */
unsigned char inportb (unsigned short _port)
{
    unsigned char rv;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;
}

/* We will use this to write to I/O ports to send bytes to devices. This
*  will be used in the next tutorial for changing the textmode cursor
*  position. Again, we use some inline assembly for the stuff that simply
*  cannot be done in C */
void outportb (unsigned short _port, unsigned char _data)
{
    __asm__ __volatile__ ("outb %1, %0" : : "dN" (_port), "a" (_data));
}

/* This is a very simple main() function. All it does is sit in an
*  infinite loop. This will be like our 'idle' loop */
void main()
{
	gdt_install();
	
	/* Interrupt/Exception handling */
	idt_install();
	isrs_install();
	irq_install();
	__asm__ __volatile__ ("sti"); 
	
	/* User I/O */
	timer_install();
	init_video();
	
	puts("Hello world!\n");
	
    for (;;);
}