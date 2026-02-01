/***************************************************************************
 * Copyright (c) 2024 Microsoft Corporation
 *
 * This program and the accompanying materials are made available under the
 * terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT.
 *
 * SPDX-License-Identifier: MIT
 **************************************************************************/

/*
 * Enhanced Linker Script for Cortex-R5 with TCM/DDR Stack Placement
 *
 * This linker script demonstrates proper memory region configuration for
 * Cortex-R5 systems with Tightly-Coupled Memory (TCM) and external DDR.
 *
 * Stack Placement Policy:
 *   - System/ISR stacks (IRQ, FIQ, SYS) in ATCM for deterministic access
 *   - Thread stacks and application data in DDR for abundant capacity
 *
 * Memory Layout:
 *   ATCM: System stacks, critical data (fast, deterministic, scarce)
 *   BTCM: Optional code or data (fast, deterministic, scarce)
 *   DDR:  Application code, data, thread stacks (abundant, higher latency)
 *
 * Adjust ORIGIN and LENGTH values for your specific SoC:
 *   TI TMS570:        ATCM=0x00000000/32KB, BTCM=0x08000000/32KB
 *   Xilinx Zynq MPSoC: ATCM=0x00000000/64KB, BTCM=0x00020000/64KB
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)

/*
 * Stack Size Definitions
 *
 * Adjust these based on your application requirements:
 *   - FIQ_STACK_SIZE: Fast Interrupt stack (typically 512-1024 bytes)
 *   - IRQ_STACK_SIZE: Standard interrupt stack (typically 1024-2048 bytes)
 *   - SYS_STACK_SIZE: System mode stack for nested interrupts (1024-2048 bytes)
 *
 * Total ATCM requirement: ~2560 bytes for stacks + critical data
 */
FIQ_STACK_SIZE = 512;
IRQ_STACK_SIZE = 1024;
SYS_STACK_SIZE = 1024;  /* Only used if TX_ENABLE_IRQ_NESTING is defined */

/*
 * Memory Region Definitions
 *
 * Configure these for your specific Cortex-R5 SoC variant.
 * Check your hardware reference manual for actual memory map.
 */
MEMORY
{
    /* ATCM: Fast, deterministic, scarce (typically 32-64KB)
     * Use for: System stacks, interrupt vectors, critical variables */
    ATCM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K

    /* BTCM: Fast, deterministic, scarce (typically 32-64KB)
     * Use for: Optional - critical code or data */
    BTCM (rwx) : ORIGIN = 0x00080000, LENGTH = 64K

    /* DDR: Abundant, higher latency (typically 256MB - 2GB)
     * Use for: Application code, data, thread stacks */
    DDR (rwx)  : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    /*
     * Interrupt Vector Table - Must be at address 0 or relocatable
     * Placed in ATCM for fast, deterministic interrupt dispatch
     */
    . = 0x00000000;
    .vectors : ALIGN(4)
    {
        KEEP(*reset.o(.text))
        . = ALIGN(4);
    } > ATCM

    /*
     * System Stacks in ATCM
     *
     * Rationale: System and interrupt stacks require deterministic, fast access
     * to minimize interrupt latency and ensure predictable real-time behavior.
     *
     * Stack growth: ARM stacks grow downward (high address to low address)
     * Alignment: 8-byte alignment required by ARM EABI
     */

    /* IRQ Stack - Used by standard interrupt handlers */
    .stack_irq (NOLOAD) : ALIGN(8)
    {
        _stack_irq_start = .;
        . += IRQ_STACK_SIZE;
        _stack_irq_end = .;
    } > ATCM

    /* FIQ Stack - Used by fast interrupt handlers */
    .stack_fiq (NOLOAD) : ALIGN(8)
    {
        _stack_fiq_start = .;
        . += FIQ_STACK_SIZE;
        _stack_fiq_end = .;
    } > ATCM

    /* SYS Stack - Used for nested interrupt support (TX_ENABLE_IRQ_NESTING) */
    .stack_sys (NOLOAD) : ALIGN(8)
    {
        _stack_sys_start = .;
        . += SYS_STACK_SIZE;
        _stack_sys_end = .;
    } > ATCM

    /* Export stack pointers for use in tx_initialize_low_level.S */
    _sp_irq = _stack_irq_end;
    _sp_fiq = _stack_fiq_end;
    _sp_sys = _stack_sys_end;
    _stack_bottom = _stack_irq_start;
    _stack_top = _stack_sys_end;

    /*
     * Code Sections in DDR
     *
     * Application code placed in abundant DDR memory.
     * For performance-critical code, consider placing in BTCM.
     */
    . = ORIGIN(DDR);

    /* Read-only code and constants */
    .text : ALIGN(4)
    {
        *(.text)
        *(.text.*)
        *(.stub)
        *(.gnu.warning)
        *(.gnu.linkonce.t*)
        *(.glue_7t)
        *(.glue_7)
    } > DDR

    .init : ALIGN(4)
    {
        KEEP(*(.init))
    } > DDR

    .fini : ALIGN(4)
    {
        KEEP(*(.fini))
    } > DDR

    .rodata : ALIGN(4)
    {
        *(.rodata)
        *(.rodata.*)
        *(.gnu.linkonce.r*)
    } > DDR

    .rodata1 : ALIGN(4)
    {
        *(.rodata1)
    } > DDR

    /* Exception handling tables */
    .eh_frame_hdr : { *(.eh_frame_hdr) } > DDR
    .eh_frame : { KEEP(*(.eh_frame)) } > DDR
    .gcc_except_table : { *(.gcc_except_table) } > DDR

    _etext = .;
    PROVIDE(etext = .);

    /*
     * Data Sections in DDR
     *
     * Initialized and uninitialized data placed in abundant DDR.
     * Thread stacks will also be allocated from DDR heap space.
     */

    /* Initialized data with load address management */
    .data : ALIGN(4)
    {
        _data_start = .;
        *(.data)
        *(.data.*)
        *(.gnu.linkonce.d*)
        SORT(CONSTRUCTORS)
        _data_end = .;
    } > DDR

    .data1 : ALIGN(4)
    {
        *(.data1)
    } > DDR

    /* C++ constructors/destructors */
    .ctors : ALIGN(4)
    {
        KEEP(*crtbegin.o(.ctors))
        KEEP(*(EXCLUDE_FILE(*crtend.o) .ctors))
        KEEP(*(SORT(.ctors.*)))
        KEEP(*(.ctors))
    } > DDR

    .dtors : ALIGN(4)
    {
        KEEP(*crtbegin.o(.dtors))
        KEEP(*(EXCLUDE_FILE(*crtend.o) .dtors))
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))
    } > DDR

    .jcr : { KEEP(*(.jcr)) } > DDR

    /* Small data sections (for architectures that support it) */
    .sdata : ALIGN(4)
    {
        *(.sdata)
        *(.sdata.*)
        *(.gnu.linkonce.s.*)
    } > DDR

    /* Global Offset Table and dynamic linking */
    .got : { *(.got.plt) *(.got) } > DDR
    .dynamic : { *(.dynamic) } > DDR

    _edata = .;
    PROVIDE(edata = .);

    /* Uninitialized data (BSS) - zeroed at startup */
    __bss_start = .;
    __bss_start__ = .;

    .sbss : ALIGN(4)
    {
        *(.dynsbss)
        *(.sbss)
        *(.sbss.*)
        *(.scommon)
    } > DDR

    .bss : ALIGN(4)
    {
        *(.dynbss)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);
    } > DDR

    _bss_end__ = .;
    __bss_end__ = .;

    /*
     * Heap Area for Dynamic Memory Allocation
     *
     * ThreadX thread stacks will be allocated from this region via
     * byte pools or block pools. This is in DDR for abundant capacity.
     *
     * The _end symbol marks the start of available heap memory.
     */
    _end = .;
    __end__ = .;
    PROVIDE(end = .);

    /* Export for ThreadX: First available memory address */
    _tx_initialize_unused_memory = _end;

    /*
     * Legacy Stack Section (for compatibility with sample_threadx.ld)
     *
     * This provides a fallback stack region in DDR if the ATCM stacks
     * are not properly initialized. Not recommended for production use.
     */
    .stack : ALIGN(8)
    {
        _stack_legacy_bottom = .;
        . += 4096;
        _sp = . - 16;
        _stack_legacy_top = .;
    } > DDR

    /*
     * Debug Sections - Not loaded into target memory
     */

    /* Stabs debugging sections */
    .stab 0 : { *(.stab) }
    .stabstr 0 : { *(.stabstr) }
    .stab.excl 0 : { *(.stab.excl) }
    .stab.exclstr 0 : { *(.stab.exclstr) }
    .stab.index 0 : { *(.stab.index) }
    .stab.indexstr 0 : { *(.stab.indexstr) }
    .comment 0 : { *(.comment) }

    /* DWARF debugging sections */
    .debug 0 : { *(.debug) }
    .line 0 : { *(.line) }
    .debug_srcinfo 0 : { *(.debug_srcinfo) }
    .debug_sfnames 0 : { *(.debug_sfnames) }
    .debug_aranges 0 : { *(.debug_aranges) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    .debug_info 0 : { *(.debug_info) }
    .debug_abbrev 0 : { *(.debug_abbrev) }
    .debug_line 0 : { *(.debug_line) }
    .debug_frame 0 : { *(.debug_frame) }
    .debug_str 0 : { *(.debug_str) }
    .debug_loc 0 : { *(.debug_loc) }
    .debug_macinfo 0 : { *(.debug_macinfo) }
    .debug_weaknames 0 : { *(.debug_weaknames) }
    .debug_funcnames 0 : { *(.debug_funcnames) }
    .debug_typenames 0 : { *(.debug_typenames) }
    .debug_varnames 0 : { *(.debug_varnames) }

    /* Discard unnecessary sections */
    /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}

/*
 * Memory Usage Summary (typical values):
 *
 * ATCM Usage:
 *   - Interrupt vectors:     ~256 bytes
 *   - IRQ stack:            1024 bytes
 *   - FIQ stack:             512 bytes
 *   - SYS stack:            1024 bytes (if nesting enabled)
 *   - Total:                ~2816 bytes (leaves ~62KB for other uses)
 *
 * DDR Usage:
 *   - Application code:     Varies
 *   - Initialized data:     Varies
 *   - BSS (zeroed data):    Varies
 *   - Thread stacks:        Allocated dynamically from heap
 *   - Heap:                 Remaining DDR space after _end
 *
 * Thread Stack Allocation:
 *   Thread stacks are allocated from DDR heap space using ThreadX
 *   byte pools (tx_byte_pool_create) or block pools. Each thread
 *   receives its own stack in DDR, ensuring abundant capacity and
 *   efficient use of scarce ATCM resources.
 *
 * Performance Considerations:
 *   - System/ISR stacks in ATCM: ~1-2 cycle access (deterministic)
 *   - Thread stacks in DDR: ~10-100 cycle access (cache-dependent)
 *   - Context switch overhead: Dominated by register save/restore (~100-200 cycles)
 *   - Interrupt latency: ATCM stacks provide 1-2 microsecond improvement
 *
 * MPU Configuration Required:
 *   - Region 0: ATCM (RW, Non-cacheable, Non-shareable)
 *   - Region 1: BTCM (RW, Non-cacheable, Non-shareable)
 *   - Region 2: DDR (RW, Cacheable Write-back, Shareable for SMP)
 *   See readme_threadx.txt Section 8.5 for detailed MPU setup.
 */
