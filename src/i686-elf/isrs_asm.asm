
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
