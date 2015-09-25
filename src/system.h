#ifndef __SYSTEM_H
#define __SYSTEM_H

/* MAIN.C */
extern unsigned char *memcpy(void *dest, const void *src, int count);
extern unsigned char *memset(void *dest, char val, int count);
extern unsigned short *memsetw(void *dest, short val, int count);
extern int strlen(const char *str);
extern unsigned char inportb (unsigned short _port);
extern void outportb (unsigned short _port, unsigned char _data);

/* SCRN.C */
extern void cls();
extern void putch(unsigned char c);
extern void puts(char *text);
extern void settextcolor(unsigned char forecolor, unsigned char backcolor);
extern void init_video();

#endif
