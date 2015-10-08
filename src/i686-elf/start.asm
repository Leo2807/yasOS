; This is the kernel's entry point. We could either call main here,
; or we can use this to setup the stack or other nice stuff, like
; perhaps setting up the GDT and segments. Please note that interrupts
; are disabled at this point: More on interrupts later!
[BITS 32]

; Multiboot macros to make a few lines later more readable
    MULTIBOOT_PAGE_ALIGN	equ 1<<0
    MULTIBOOT_MEMORY_INFO	equ 1<<1
    MULTIBOOT_AOUT_KLUDGE	equ 1<<16
    MULTIBOOT_HEADER_MAGIC	equ 0x1BADB002
    MULTIBOOT_HEADER_FLAGS	equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_AOUT_KLUDGE
    MULTIBOOT_CHECKSUM	equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
    EXTERN code, bss, end

; This is the virtual base address of kernel space. It must be used to convert virtual
; addresses into physical addresses until paging is enabled. Note that this is not
; the virtual address where the kernel image itself is loaded -- just the amount that must
; be subtracted from a virtual address to get a physical address.
KERNEL_VIRTUAL_BASE equ 0xC0000000                  ; 3GB
KERNEL_PAGE_NUMBER equ (KERNEL_VIRTUAL_BASE >> 22)  ; Page directory index of kernel's 4MB PTE.

section .data
align 0x1000
boot_page_directory:
    ; This page directory entry identity-maps the first 4MB of the 32-bit physical address space.
    ; All bits are clear except the following:
    ; bit 7: PS The kernel page is 4MB.
    ; bit 1: RW The kernel page is read/write.
    ; bit 0: P  The kernel page is present.
    ; This entry must be here -- otherwise the kernel will crash immediately after paging is
    ; enabled because it can't fetch the next instruction! It's ok to unmap this page later.
    dd 0x00000083
    times (KERNEL_PAGE_NUMBER - 1) dd 0                 ; Pages before kernel space.
    ; This page directory entry defines a 4MB page containing the kernel.
    dd 0x00000083
    times (1024 - KERNEL_PAGE_NUMBER - 1) dd 0  ; Pages after the kernel image.

section .text

; This part MUST be 4byte aligned, so we solve that issue using 'ALIGN 4'
ALIGN 4
mboot:

    ; This is the GRUB Multiboot header. A boot signature
    dd MULTIBOOT_HEADER_MAGIC
    dd MULTIBOOT_HEADER_FLAGS
    dd MULTIBOOT_CHECKSUM
    
    ; AOUT kludge - must be physical addresses. Make a note of these:
    ; The linker script fills in the data for these ones!
    dd mboot
    dd code
    dd bss
    dd end
    dd start

global start
start:
	; NOTE: Until paging is set up, the code must be position-independent and use physical
    ; addresses, not virtual ones!
    mov ecx, (boot_page_directory - KERNEL_VIRTUAL_BASE)
    mov cr3, ecx                                        ; Load Page Directory Base Register.
 
    mov ecx, cr4
    or ecx, 0x00000010                          ; Set PSE bit in CR4 to enable 4MB pages.
    mov cr4, ecx
 
    mov ecx, cr0
    or ecx, 0x80000000                          ; Set PG bit in CR0 to enable paging.
    mov cr0, ecx
 
    ; Start fetching instructions in kernel space.
    ; Since eip at this point holds the physical address of this command (approximately 0x00100000)
    ; we need to do a long jump to the correct virtual address of StartInHigherHalf which is
    ; approximately 0xC0100000.
    lea ecx, [start_high]
    jmp ecx

start_high:
	; Unmap the identity-mapped first 4MB of physical address space. It should not be needed
    ; anymore.
    mov dword [boot_page_directory], 0
    invlpg [0]
    
    ; NOTE: From now on, paging should be enabled. The first 4MB of physical address space is
    ; mapped starting at KERNEL_VIRTUAL_BASE. Everything is linked to this address, so no more
    ; position-independent code or funny business with virtual-to-physical address translation
    ; should be necessary. We now have a higher-half kernel.
    mov esp, _sys_stack		           ; set up the stack
    push eax                           ; pass Multiboot magic number
	
	; pass Multiboot info structure -- WARNING: This is a physical address and may not be
    ; in the first 4MB!
    push ebx
    
    extern main
    call main
    hlt

; This will set up our new segment registers. We need to do
; something special in order to set CS. We do what is called a
; far jump. A jump that includes a segment as well as an offset.
; This is declared in C as 'extern void gdt_flush();'
global gdt_flush     ; Allows the C code to link to this
extern gp            ; Says that 'gp' is in another file
gdt_flush:
    lgdt [gp]        ; Load the GDT with our '_p' which is a special pointer
    mov ax, 0x10      ; 0x10 is the offset in the GDT to our data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x08:flush2   ; 0x08 is the offset to our code segment: Far jump!
flush2:
    ret               ; Returns back to the C code!

; Loads the IDT defined in 'idtp' into the processor.
; This is declared in C as 'extern void idt_load();'
global idt_load
extern idtp
idt_load:
    lidt [idtp]
    ret


global isr0
global isr1
global isr2
global isr3
global isr4
global isr5
global isr6
global isr7
global isr8
global isr9
global isr10
global isr11
global isr12
global isr13
global isr14
global isr15
global isr16
global isr17
global isr18
global isr19
global isr20
global isr21
global isr22
global isr23
global isr24
global isr25
global isr26
global isr27
global isr28
global isr29
global isr30
global isr31

;  0: Divide By Zero Exception
isr0:
    cli
    push byte 0    ; A normal ISR stub that pops a dummy error code to keep a
                   ; uniform stack frame
    push byte 0
    jmp isr_common_stub

;  1: Debug Exception
isr1:
    cli
    push byte 0
    push byte 1
    jmp isr_common_stub
    
isr2:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr3:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr4:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr5:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr6:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr7:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

;  8: Double Fault Exception (With Error Code!)
isr8:
    cli
    push byte 8        ; Note that we DON'T push a value on the stack in this one!
                   ; It pushes one already! Use this type of stub for exceptions
                   ; that pop error codes!
    jmp isr_common_stub

isr9:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr10:
	cli
	push byte 0
	
	jmp isr_common_stub

isr11:
	cli
	push byte 0
	
	jmp isr_common_stub

isr12:
	cli
	push byte 0
	
	jmp isr_common_stub
	
isr13:
	cli
	push byte 0
	
	jmp isr_common_stub
	
isr14:
	cli
	push byte 0
	
	jmp isr_common_stub

isr15:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr16:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr17:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr18:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr19:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr20:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr21:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr22:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr23:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr24:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr25:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr26:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr27:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr28:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr29:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr30:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

isr31:
	cli
	push byte 0
	push byte 1
	jmp isr_common_stub

; We call a C function in here. We need to let the assembler know
; that '_fault_handler' exists in another file
extern fault_handler

; This is our common ISR stub. It saves the processor state, sets
; up for kernel mode segments, calls the C-level fault handler,
; and finally restores the stack frame.
isr_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10   ; Load the Kernel Data Segment descriptor!
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp   ; Push us the stack
    push eax
    mov eax, fault_handler
    call eax       ; A special call, preserves the 'eip' register
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8     ; Cleans up the pushed error code and pushed ISR number
    iret           ; pops 5 things at once: CS, EIP, EFLAGS, SS, and ESP!

; Define IRQs
global irq0
global irq1
global irq2
global irq3
global irq4
global irq5
global irq6
global irq7
global irq8
global irq9
global irq10
global irq11
global irq12
global irq13
global irq14
global irq15

; Create IRQ stubs

; 32: IRQ0
irq0:
    cli
    push byte 0    ; Note that these don't push an error code on the stack:
                   ; We need to push a dummy error code
    push byte 32
    jmp irq_common_stub

; 33: IRQ1
irq1:
    cli
    push byte 0
    push byte 33
    jmp irq_common_stub

; 34: IRQ2
irq2:
    cli
    push byte 0
    push byte 34
    jmp irq_common_stub

; 35: IRQ3
irq3:
    cli
    push byte 0
    push byte 35
    jmp irq_common_stub

; 36: IRQ4
irq4:
    cli
    push byte 0
    push byte 36
    jmp irq_common_stub

; 37: IRQ5
irq5:
    cli
    push byte 0
    push byte 37
    jmp irq_common_stub

; 38: IRQ6
irq6:
    cli
    push byte 0
    push byte 38
    jmp irq_common_stub

; 39: IRQ7
irq7:
    cli
    push byte 0
    push byte 39
    jmp irq_common_stub

; 40: IRQ8
irq8:
    cli
    push byte 0
    push byte 40
    jmp irq_common_stub

; 41: IRQ9
irq9:
    cli
    push byte 0
    push byte 41
    jmp irq_common_stub

; 42: IRQ10
irq10:
    cli
    push byte 0
    push byte 42
    jmp irq_common_stub

; 43: IRQ11
irq11:
    cli
    push byte 0
    push byte 43
    jmp irq_common_stub

; 44: IRQ12
irq12:
    cli
    push byte 0
    push byte 44
    jmp irq_common_stub

; 45: IRQ13
irq13:
    cli
    push byte 0
    push byte 45
    jmp irq_common_stub

; 46: IRQ14
irq14:
    cli
    push byte 0
    push byte 46
    jmp irq_common_stub

; 47: IRQ15
irq15:
    cli
    push byte 0
    push byte 47
    jmp irq_common_stub

extern irq_handler

; This is a stub that we have created for IRQ based ISRs. This calls
; '_irq_handler' in our C code. We need to create this in an 'irq.c'
irq_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp
    push eax
    mov eax, irq_handler
    call eax
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8
    iret

; Here is the definition of our BSS section. Right now, we'll use
; it just to store the stack. Remember that a stack actually grows
; downwards, so we declare the size of the data before declaring
; the identifier '_sys_stack'
SECTION .bss
    resb 8192               ; This reserves 8KBytes of memory here
_sys_stack:
