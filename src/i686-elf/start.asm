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
    dd 0x00000003
    times (KERNEL_PAGE_NUMBER - 1) dd 0x00000002                 ; Pages before kernel space.
    ; This page directory entry defines a 4MB page containing the kernel.
    dd 0x00000003
    times (1024 - KERNEL_PAGE_NUMBER - 1) dd 0x00000002  ; Pages after the kernel image.

align 0x1000
boot_page_table:
	; Maps to the 1st 4MB, will be set up in start
	times 1024 dd 0

; Multiboot passes these on the registers, which we need before we can set up the stack.
global mboot_magic
mboot_magic:
	dd 0
global mboot_info
mboot_info:
	dd 0

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
    dd mboot - 0xC0000000
    dd code - 0xC0000000
    dd bss- 0xC0000000
    dd end - 0xC0000000
    dd start

global start
start equ (_start - 0xC0000000)

global _start
_start:
	; NOTE: Until paging is set up, the code must be position-independent and use physical
    ; addresses, not virtual ones!
    
    ; Save multiboot data
    mov [mboot_info - KERNEL_VIRTUAL_BASE], ebx
    mov [mboot_magic - KERNEL_VIRTUAL_BASE], eax
    
	; Identity maps the boot page table starting at adress 0
	; ---- LOOP ----
    mov eax, 0x0
	mov ebx, 0x000000
	
 .fill_table:
    mov ecx, ebx
    or ecx, 3
    mov [(boot_page_table-KERNEL_VIRTUAL_BASE)+eax*4], ecx
    add ebx, 4096
    inc eax
    cmp eax, 1024
    je .end; - KERNEL_VIRTUAL_BASE
    jmp .fill_table; - KERNEL_VIRTUAL_BASE
 .end:
    ; ---- END OF LOOP ----
    
    ; Install tables
    mov eax, dword boot_page_directory - KERNEL_VIRTUAL_BASE
    
    mov ebx, dword boot_page_table - KERNEL_VIRTUAL_BASE
    or ebx, 0x3
    
    ; We need to do it at 2 locations
    mov [eax], ebx
    mov [eax + ( KERNEL_PAGE_NUMBER )*4], ebx
    
    mov ecx, (boot_page_directory - KERNEL_VIRTUAL_BASE)
    mov cr3, ecx                                        ; Load Page Directory Base Register
 
    mov ecx, cr0
    or ecx, 0x80000000                          ; Set PG bit in CR0 to enable paging.
    mov cr0, ecx
 
    ; Start fetching instructions in kernel space.
    ; Since eip at this point holds the physical address of this command (approximately 0x00100000)
    ; we need to do a long jump to the correct virtual address of start_high which is
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
    
    extern main
    call main
    hlt

; Here is the definition of our BSS section. Right now, we'll use
; it just to store the stack. Remember that a stack actually grows
; downwards, so we declare the size of the data before declaring
; the identifier '_sys_stack'
SECTION .bss
    resb 8192               ; This reserves 8KBytes of memory here
_sys_stack:
