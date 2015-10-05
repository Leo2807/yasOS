/* Don't put the architecture specific headers in the exported header */
#include "gdt.h"
#include "idt.h"
#include "isrs.h"
#include "irq.h"
#include "timer.h"
#include "paging.h"
/* End */

void arch_init()
{
	
	gdt_install();
	
	/* Interrupt/Exception handling */
	idt_install();
	isrs_install();
	irq_install();
	__asm__ __volatile__ ("sti");
	
	/* Memory */
	paging_install();
	
	timer_install();
}
