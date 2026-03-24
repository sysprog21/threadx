@/***************************************************************************
@ * Copyright (c) 2024 Microsoft Corporation 
@ * 
@ * This program and the accompanying materials are made available under the
@ * terms of the MIT License which is available at
@ * https://opensource.org/licenses/MIT.
@ * 
@ * SPDX-License-Identifier: MIT
@ **************************************************************************/
@
@
@/**************************************************************************/
@/**************************************************************************/
@/**                                                                       */ 
@/** ThreadX Component                                                     */ 
@/**                                                                       */
@/**   Initialize                                                          */
@/**                                                                       */
@/**************************************************************************/
@/**************************************************************************/
@
@
@#define TX_SOURCE_CODE
@
@
@/* Include necessary system files.  */
@
@#include "tx_api.h"
@#include "tx_initialize.h"
@#include "tx_thread.h"
@#include "tx_timer.h"

    .arm

SVC_MODE        =       0xD3                    @ Disable IRQ/FIQ SVC mode
IRQ_MODE        =       0xD2                    @ Disable IRQ/FIQ IRQ mode
FIQ_MODE        =       0xD1                    @ Disable IRQ/FIQ FIQ mode
SYS_MODE        =       0xDF                    @ Disable IRQ/FIQ SYS mode
FIQ_STACK_SIZE  =       512                     @ FIQ stack size
IRQ_STACK_SIZE  =       1024                    @ IRQ stack size
SVC_STACK_SIZE  =       1024                    @ SVC stack size (for VFP preemption)
SYS_STACK_SIZE  =       1024                    @ System stack size
@
@/**************************************************************************/
@/*                                                                        */
@/*  GIC (Generic Interrupt Controller) Register Definitions               */
@/*                                                                        */
@/*  Reference: ARM GIC Architecture Specification (IHI 0048B)             */
@/*                                                                        */
@/*  GIC Base Address Discovery:                                           */
@/*  Option 1: Read CBAR (Configuration Base Address Register) via         */
@/*            MRC p15, 4, r0, c15, c0, 0  (if implemented)                */
@/*            GICD is at CBAR + 0x1000, GICC is at CBAR + 0x2000          */
@/*  Option 2: Platform-specific (defined below for Zynq UltraScale+ RPU)  */
@/*                                                                        */
@/**************************************************************************/
@
#ifdef TX_ENABLE_GIC_SUPPORT
@
@/* GIC base addresses for Xilinx Zynq UltraScale+ RPU (Cortex-R5F)        */
@/* Override these for other platforms via -DTX_GIC_DISTRIBUTOR_BASE=...   */
@
#ifndef TX_GIC_DISTRIBUTOR_BASE
#define TX_GIC_DISTRIBUTOR_BASE     0xF9000000  @ GICD base for ZynqMP RPU
#endif
#ifndef TX_GIC_CPU_INTERFACE_BASE
#define TX_GIC_CPU_INTERFACE_BASE   0xF9001000  @ GICC base for ZynqMP RPU
#endif
@
@/* GIC Distributor Register Offsets (from GICD base)                      */
@
GICD_CTLR       =       0x000                   @ Distributor Control Register
GICD_TYPER      =       0x004                   @ Interrupt Controller Type
GICD_IIDR       =       0x008                   @ Distributor Implementer ID
GICD_IGROUPR    =       0x080                   @ Interrupt Group Registers (n*4)
GICD_ISENABLER  =       0x100                   @ Interrupt Set-Enable (n*4)
GICD_ICENABLER  =       0x180                   @ Interrupt Clear-Enable (n*4)
GICD_ISPENDR    =       0x200                   @ Interrupt Set-Pending (n*4)
GICD_ICPENDR    =       0x280                   @ Interrupt Clear-Pending (n*4)
GICD_ISACTIVER  =       0x300                   @ Interrupt Set-Active (n*4)
GICD_ICACTIVER  =       0x380                   @ Interrupt Clear-Active (n*4)
GICD_IPRIORITYR =       0x400                   @ Interrupt Priority (n*4, byte access)
GICD_ITARGETSR  =       0x800                   @ Interrupt Processor Targets (n*4)
GICD_ICFGR      =       0xC00                   @ Interrupt Configuration (n*4)
GICD_SGIR       =       0xF00                   @ Software Generated Interrupt
@
@/* GIC CPU Interface Register Offsets (from GICC base)                    */
@
GICC_CTLR       =       0x00                    @ CPU Interface Control Register
GICC_PMR        =       0x04                    @ Interrupt Priority Mask
GICC_BPR        =       0x08                    @ Binary Point Register
GICC_IAR        =       0x0C                    @ Interrupt Acknowledge Register
GICC_EOIR       =       0x10                    @ End of Interrupt Register
GICC_RPR        =       0x14                    @ Running Priority Register
GICC_HPPIR      =       0x18                    @ Highest Priority Pending Interrupt
GICC_IIDR       =       0xFC                    @ CPU Interface Implementer ID
@
@/* GIC Configuration Constants                                            */
@
GIC_DEFAULT_PRIO =      0x80                    @ Default priority (mid-range)
GIC_PRIO_MASK    =      0xFF                    @ Accept all priorities
GIC_BPR_VALUE    =      0x03                    @ Binary point (no preemption groups)
@
@/* Maximum interrupt count for handler table                              */
@
#ifndef TX_GIC_MAX_INTERRUPTS
#define TX_GIC_MAX_INTERRUPTS       192         @ Default for ZynqMP (32 SGI/PPI + 160 SPI)
#endif
@
@/**************************************************************************/
@/*  GIC Deferred EOI Support                                              */
@/*                                                                        */
@/*  When TX_GIC_DEFERRED_EOI is defined, EOIR is written in               */
@/*  tx_thread_context_restore.S AFTER CPSID, not here in the IRQ handler. */
@/*  This closes the race window for level-triggered interrupts.           */
@/*                                                                        */
@/*  CONSTRAINTS: Single-core only, NOT compatible with IRQ nesting.       */
@/**************************************************************************/
@
#ifdef TX_GIC_DEFERRED_EOI
#ifdef TX_ENABLE_IRQ_NESTING
#error "TX_GIC_DEFERRED_EOI is not compatible with TX_ENABLE_IRQ_NESTING"
#endif
#endif
@
#endif /* TX_ENABLE_GIC_SUPPORT */
@
@
    .global     _tx_thread_system_stack_ptr
    .global     _tx_initialize_unused_memory
    .global     _tx_thread_context_save
    .global     _tx_thread_context_restore
    .global     _tx_timer_interrupt
    .global     _end
    .global     _sp
    .global     _stack_bottom

@
@
@/* Define the 16-bit Thumb mode veneer for _tx_initialize_low_level for
@   applications calling this function from to 16-bit Thumb mode.  */
@
    .text
    .align 2
    .thumb
    .global $_tx_initialize_low_level
    .type   $_tx_initialize_low_level,function
$_tx_initialize_low_level:
     BX        pc                               @ Switch to 32-bit mode
     NOP                                        @ 
    .arm
     STMFD     sp!, {lr}                        @ Save return address
     BL        _tx_initialize_low_level         @ Call _tx_initialize_low_level function
     LDMFD     sp!, {lr}                        @ Recover saved return address
     BX        lr                               @ Return to 16-bit caller
@
@
    .text
    .align 2
@/**************************************************************************/ 
@/*                                                                        */ 
@/*  FUNCTION                                               RELEASE        */ 
@/*                                                                        */ 
@/*    _tx_initialize_low_level                          Cortex-R5/GNU     */ 
@/*                                                           6.1          */
@/*  AUTHOR                                                                */
@/*                                                                        */
@/*    William E. Lamie, Microsoft Corporation                             */
@/*                                                                        */
@/*  DESCRIPTION                                                           */
@/*                                                                        */ 
@/*    This function is responsible for any low-level processor            */ 
@/*    initialization, including setting up interrupt vectors, setting     */ 
@/*    up a periodic timer interrupt source, saving the system stack       */ 
@/*    pointer for use in ISR processing later, and finding the first      */ 
@/*    available RAM memory address for tx_application_define.             */ 
@/*                                                                        */ 
@/*  INPUT                                                                 */ 
@/*                                                                        */ 
@/*    None                                                                */ 
@/*                                                                        */ 
@/*  OUTPUT                                                                */ 
@/*                                                                        */ 
@/*    None                                                                */ 
@/*                                                                        */ 
@/*  CALLS                                                                 */ 
@/*                                                                        */ 
@/*    None                                                                */ 
@/*                                                                        */ 
@/*  CALLED BY                                                             */ 
@/*                                                                        */ 
@/*    _tx_initialize_kernel_enter           ThreadX entry function        */ 
@/*                                                                        */ 
@/*  RELEASE HISTORY                                                       */ 
@/*                                                                        */ 
@/*    DATE              NAME                      DESCRIPTION             */
@/*                                                                        */
@/*  09-30-2020     William E. Lamie         Initial Version 6.1           */
@/*                                                                        */
@/**************************************************************************/
@VOID   _tx_initialize_low_level(VOID)
@{
    .global _tx_initialize_low_level
    .type   _tx_initialize_low_level,function
_tx_initialize_low_level:
@
@    /* We must be in SVC mode at this point!  */
@
@    /* Setup various stack pointers.  */
@    /* CRITICAL: Initialize top-to-bottom to match linker script memory layout */
@    /* Memory layout (ATCM): IRQ (low) → FIQ → SYS → SVC (high) */
@    /* Initialization order: SVC (high) → SYS → FIQ → IRQ (low) */
@
    LDR     r1, =_stack_top                     @ Start at top of ATCM (SVC end)
@
@    /* Setup SVC stack (highest address) - CRITICAL for VFP alignment */
@
    LDR     r2, =SVC_STACK_SIZE                 @ Pickup SVC stack size
    MOV     r0, #SVC_MODE                       @ Build SVC mode CPSR
    MSR     CPSR_c, r0                          @ Enter SVC mode (control field only)
    ISB                                         @ Instruction barrier after mode change
    BIC     r1, r1, #7                          @ Ensure 8-byte alignment for VFP operations
    MOV     sp, r1                              @ Setup SVC stack pointer (CRITICAL for VFP)
    SUB     r1, r1, r2                          @ Move down to SYS top

#ifdef TX_ENABLE_IRQ_NESTING
@
@    /* Setup the system mode stack for nested interrupt support  */
@
    LDR     r2, =SYS_STACK_SIZE                 @ Pickup stack size
    MOV     r3, #SYS_MODE                       @ Build SYS mode CPSR
    MSR     CPSR_c, r3                          @ Enter SYS mode (control field only)
    ISB                                         @ Instruction barrier after mode change
    BIC     r1, r1, #7                          @ Ensure 8-byte alignment
    MOV     sp, r1                              @ Setup SYS stack pointer
    SUB     r1, r1, r2                          @ Move down to FIQ top
#else
@
@    /* Skip SYS stack setup but reserve space to match linker layout */
@
    LDR     r2, =SYS_STACK_SIZE                 @ Pickup stack size
    SUB     r1, r1, r2                          @ Skip over SYS region (maintain layout)
#endif
@
@    /* Setup FIQ stack */
@
    LDR     r2, =FIQ_STACK_SIZE                 @ Pickup stack size
    MOV     r0, #FIQ_MODE                       @ Build FIQ mode CPSR
    MSR     CPSR_c, r0                          @ Enter FIQ mode (control field only)
    ISB                                         @ Instruction barrier after mode change
    BIC     r1, r1, #7                          @ Ensure 8-byte alignment
    MOV     sp, r1                              @ Setup FIQ stack pointer
    SUB     r1, r1, r2                          @ Move down to IRQ top
@
@    /* Setup IRQ stack (lowest address) */
@
    LDR     r2, =IRQ_STACK_SIZE                 @ Pickup IRQ stack size
    MOV     r0, #IRQ_MODE                       @ Build IRQ mode CPSR
    MSR     CPSR_c, r0                          @ Enter IRQ mode (control field only)
    ISB                                         @ Instruction barrier after mode change
    BIC     r1, r1, #7                          @ Ensure 8-byte alignment
    MOV     sp, r1                              @ Setup IRQ stack pointer
    SUB     r3, r1, r2                          @ Calculate bottom of IRQ stack
@
@    /* Verify stack does not overflow into other memory.  */
@
    LDR     r2, =_stack_bottom                  @ Pickup stack bottom
    CMP     r3, r2                              @ Compare the current stack end with the bottom
_stack_error_loop:                  
    BLT     _stack_error_loop                   @ If the IRQ stack exceeds the stack bottom, just sit here!
@
@    /* Save the system stack pointer.  */
@    _tx_thread_system_stack_ptr = (VOID_PTR) (sp);
@
    LDR     r2, =_tx_thread_system_stack_ptr    @ Pickup stack pointer
    STR     r1, [r2]                            @ Save the system stack
@
@    /* Save the first available memory address.  */
@    _tx_initialize_unused_memory =  (VOID_PTR) _end;
@
    LDR     r1, =_end                           @ Get end of non-initialized RAM area
    LDR     r2, =_tx_initialize_unused_memory   @ Pickup unused memory ptr address
    ADD     r1, r1, #8                          @ Increment to next free word
    STR     r1, [r2]                            @ Save first free memory address
@
@    /* Setup Timer for periodic interrupts.  */
@
@    /* Done, return to caller.  */
@
#ifdef __THUMB_INTERWORK
    BX      lr                                  @ Return to caller
#else
    MOV     pc, lr                              @ Return to caller
#endif
@}
@
@
#ifdef TX_ENABLE_GIC_SUPPORT
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_initialize                               Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    This function initializes the GIC distributor and CPU interface.    */
@/*    Call this function before enabling interrupts.                      */
@/*                                                                        */
@/*    Reference: ARM GIC Architecture Specification (IHI 0048B)           */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    None                                                                */
@/*                                                                        */
@/*  OUTPUT                                                                */
@/*                                                                        */
@/*    None                                                                */
@/*                                                                        */
@/*  CALLS                                                                 */
@/*                                                                        */
@/*    None                                                                */
@/*                                                                        */
@/*  CALLED BY                                                             */
@/*                                                                        */
@/*    Application startup code (before ThreadX starts)                    */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_initialize
    .type   _tx_gic_initialize, %function
_tx_gic_initialize:
    PUSH    {r4-r7, lr}                         @ Save callee-saved registers
@
@   /* Load GIC base addresses */
@
    LDR     r4, =TX_GIC_DISTRIBUTOR_BASE        @ r4 = GICD base
    LDR     r5, =TX_GIC_CPU_INTERFACE_BASE      @ r5 = GICC base
@
@   /*------------------------------------------------------------------------*/
@   /* Step 1: Disable distributor while configuring                         */
@   /*------------------------------------------------------------------------*/
@
    MOV     r0, #0
    STR     r0, [r4, #GICD_CTLR]                @ Disable distributor
    DSB                                         @ Ensure write completes
    ISB                                         @ Sync pipeline before proceeding
@
@   /*------------------------------------------------------------------------*/
@   /* Step 2: Read GICD_TYPER to determine number of interrupt lines        */
@   /*         IT_LINES_NUMBER (bits 4:0) = (N+1)*32, max 1020 interrupts    */
@   /*------------------------------------------------------------------------*/
@
    LDR     r0, [r4, #GICD_TYPER]               @ Read GICD_TYPER
    AND     r6, r0, #0x1F                       @ Extract IT_LINES_NUMBER
    ADD     r6, r6, #1                          @ N+1
    LSL     r6, r6, #5                          @ (N+1)*32 = total interrupt count
@
@   /*------------------------------------------------------------------------*/
@   /* Step 3: Disable all interrupts (write 0xFFFFFFFF to GICD_ICENABLER)   */
@   /*------------------------------------------------------------------------*/
@
    MOV     r1, r4
    ADD     r1, r1, #GICD_ICENABLER             @ r1 = &GICD_ICENABLER[0]
    MOV     r2, r6                              @ r2 = interrupt count
    MVN     r0, #0                              @ r0 = 0xFFFFFFFF
_gic_disable_loop:
    STR     r0, [r1], #4                        @ Disable 32 interrupts, advance ptr
    SUBS    r2, r2, #32                         @ Decrement counter
    BGT     _gic_disable_loop                   @ Continue if more interrupts
@
@   /*------------------------------------------------------------------------*/
@   /* Step 4: Clear all pending interrupts (write 0xFFFFFFFF to GICD_ICPENDR)*/
@   /*------------------------------------------------------------------------*/
@
    MOV     r1, r4
    ADD     r1, r1, #GICD_ICPENDR               @ r1 = &GICD_ICPENDR[0]
    MOV     r2, r6                              @ r2 = interrupt count
_gic_clear_pending_loop:
    STR     r0, [r1], #4                        @ Clear pending for 32 interrupts
    SUBS    r2, r2, #32                         @ Decrement counter
    BGT     _gic_clear_pending_loop             @ Continue if more interrupts
@
@   /*------------------------------------------------------------------------*/
@   /* Step 5: Clear all active interrupts (write 0xFFFFFFFF to GICD_ICACTIVER)*/
@   /*------------------------------------------------------------------------*/
@
    MOV     r1, r4
    ADD     r1, r1, #GICD_ICACTIVER             @ r1 = &GICD_ICACTIVER[0]
    MOV     r2, r6                              @ r2 = interrupt count
_gic_clear_active_loop:
    STR     r0, [r1], #4                        @ Clear active for 32 interrupts
    SUBS    r2, r2, #32                         @ Decrement counter
    BGT     _gic_clear_active_loop              @ Continue if more interrupts
@
@   /*------------------------------------------------------------------------*/
@   /* Step 6: Set default priority for all interrupts (GICD_IPRIORITYR)     */
@   /*         Priority registers are byte-accessible                        */
@   /*------------------------------------------------------------------------*/
@
    MOV     r1, r4
    ADD     r1, r1, #GICD_IPRIORITYR            @ r1 = &GICD_IPRIORITYR[0]
    MOV     r2, r6                              @ r2 = interrupt count
    LDR     r0, =0x80808080                     @ Default priority 0x80 for 4 IRQs
_gic_priority_loop:
    STR     r0, [r1], #4                        @ Set priority for 4 interrupts
    SUBS    r2, r2, #4                          @ Decrement counter
    BGT     _gic_priority_loop                  @ Continue if more interrupts
@
@   /*------------------------------------------------------------------------*/
@   /* Step 7: Set CPU target to CPU0 for all SPIs (GICD_ITARGETSR)          */
@   /*         SGI/PPI (0-31) targets are read-only, skip them               */
@   /*         Target registers are byte-accessible (CPU bitmask)            */
@   /*------------------------------------------------------------------------*/
@
    MOV     r1, r4
    ADD     r1, r1, #GICD_ITARGETSR
    ADD     r1, r1, #32                         @ Skip SGI/PPI (first 32 bytes)
    SUB     r2, r6, #32                         @ r2 = SPI count (total - 32)
    CMP     r2, #0
    BLE     _gic_target_done                    @ No SPIs to configure
    LDR     r0, =0x01010101                     @ Target CPU0 for 4 IRQs
_gic_target_loop:
    STR     r0, [r1], #4                        @ Set target for 4 interrupts
    SUBS    r2, r2, #4                          @ Decrement counter
    BGT     _gic_target_loop                    @ Continue if more interrupts
_gic_target_done:
@
@   /*------------------------------------------------------------------------*/
@   /* Step 8: Set interrupt configuration (GICD_ICFGR)                      */
@   /*         SGI (0-15): always edge-triggered                             */
@   /*         PPI (16-31): typically level-sensitive (platform-specific)    */
@   /*         SPI (32+): typically level-sensitive (platform-specific)      */
@   /*         Each 2-bit field: 0=level, 2=edge                             */
@   /*------------------------------------------------------------------------*/
@
@   /* Skip detailed ICFGR configuration - platform-specific                 */
@   /* Applications should configure per-interrupt as needed                 */
@
@   /*------------------------------------------------------------------------*/
@   /* Step 9: Initialize GIC CPU Interface                                  */
@   /*------------------------------------------------------------------------*/
@
@   /* Disable CPU interface while configuring */
    MOV     r0, #0
    STR     r0, [r5, #GICC_CTLR]                @ Disable CPU interface
    DSB
@
@   /* Set priority mask to accept all priorities (0xFF) */
    MOV     r0, #GIC_PRIO_MASK                  @ 0xFF = accept all priorities
    STR     r0, [r5, #GICC_PMR]                 @ Write to GICC_PMR
@
@   /* Set binary point for no priority grouping */
    MOV     r0, #GIC_BPR_VALUE                  @ 0x03 = no preemption groups
    STR     r0, [r5, #GICC_BPR]                 @ Write to GICC_BPR
@
@   /*------------------------------------------------------------------------*/
@   /* Step 10: Enable distributor and CPU interface                         */
@   /*------------------------------------------------------------------------*/
@
@   /* Enable distributor (Group 0 and Group 1) */
    MOV     r0, #0x03                           @ Enable Group 0 + Group 1
    STR     r0, [r4, #GICD_CTLR]                @ Enable distributor
    DSB                                         @ Ensure distributor enable completes
    ISB                                         @ Sync before enabling CPU interface
@
@   /* Enable CPU interface */
@   /* Bit 0: EnableGrp0, Bit 1: EnableGrp1, Bit 2: AckCtl                   */
    MOV     r0, #0x07                           @ Enable both groups + AckCtl
    STR     r0, [r5, #GICC_CTLR]                @ Enable CPU interface
    DSB
    ISB
@
    POP     {r4-r7, pc}                         @ Return
@
@
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_enable_irq                               Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    Enable a specific interrupt in the GIC distributor.                 */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    r0 = Interrupt ID (0-1019)                                          */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_enable_irq
    .type   _tx_gic_enable_irq, %function
_tx_gic_enable_irq:
    LDR     r1, =TX_GIC_DISTRIBUTOR_BASE
    ADD     r1, r1, #GICD_ISENABLER             @ r1 = &GICD_ISENABLER[0]
@   /* Calculate register offset: (irq / 32) * 4 */
    LSR     r2, r0, #5                          @ r2 = irq / 32
    LSL     r2, r2, #2                          @ r2 = (irq / 32) * 4
    ADD     r1, r1, r2                          @ r1 = &GICD_ISENABLER[irq/32]
@   /* Calculate bit position: irq % 32 */
    AND     r2, r0, #31                         @ r2 = irq % 32
    MOV     r0, #1
    LSL     r0, r0, r2                          @ r0 = 1 << (irq % 32)
    STR     r0, [r1]                            @ Enable the interrupt
    DSB
    BX      lr
@
@
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_disable_irq                              Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    Disable a specific interrupt in the GIC distributor.                */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    r0 = Interrupt ID (0-1019)                                          */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_disable_irq
    .type   _tx_gic_disable_irq, %function
_tx_gic_disable_irq:
    LDR     r1, =TX_GIC_DISTRIBUTOR_BASE
    ADD     r1, r1, #GICD_ICENABLER             @ r1 = &GICD_ICENABLER[0]
@   /* Calculate register offset: (irq / 32) * 4 */
    LSR     r2, r0, #5                          @ r2 = irq / 32
    LSL     r2, r2, #2                          @ r2 = (irq / 32) * 4
    ADD     r1, r1, r2                          @ r1 = &GICD_ICENABLER[irq/32]
@   /* Calculate bit position: irq % 32 */
    AND     r2, r0, #31                         @ r2 = irq % 32
    MOV     r0, #1
    LSL     r0, r0, r2                          @ r0 = 1 << (irq % 32)
    STR     r0, [r1]                            @ Disable the interrupt
    DSB
    BX      lr
@
@
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_set_priority                             Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    Set priority for a specific interrupt.                              */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    r0 = Interrupt ID (0-1019)                                          */
@/*    r1 = Priority (0-255, lower = higher priority)                      */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_set_priority
    .type   _tx_gic_set_priority, %function
_tx_gic_set_priority:
    LDR     r2, =TX_GIC_DISTRIBUTOR_BASE
    ADD     r2, r2, #GICD_IPRIORITYR            @ r2 = &GICD_IPRIORITYR[0]
    ADD     r2, r2, r0                          @ r2 = &GICD_IPRIORITYR[irq]
    STRB    r1, [r2]                            @ Write priority (byte access)
    DSB
    BX      lr
@
#endif /* TX_ENABLE_GIC_SUPPORT */
@
@
@/* Define shells for each of the interrupt vectors.  */
@
    .global __tx_undefined
__tx_undefined:
    B       __tx_undefined                      @ Undefined handler
@
    .global __tx_swi_interrupt
__tx_swi_interrupt:
    B       __tx_swi_interrupt                  @ Software interrupt handler
@
    .global __tx_prefetch_handler
__tx_prefetch_handler:
    B       __tx_prefetch_handler               @ Prefetch exception handler
@
    .global __tx_abort_handler
__tx_abort_handler:
    B       __tx_abort_handler                  @ Abort exception handler
@
    .global __tx_reserved_handler
__tx_reserved_handler:
    B       __tx_reserved_handler               @ Reserved exception handler
@
    .global __tx_irq_handler
    .global __tx_irq_processing_return      
__tx_irq_handler:
@
@    /* Jump to context save to save system context.  */
    B       _tx_thread_context_save
__tx_irq_processing_return:
@
@    /* At this point execution is still in the IRQ mode.  The CPSR, point of
@       interrupt, and all C scratch registers are available for use.  In 
@       addition, IRQ interrupts may be re-enabled - with certain restrictions -
@       if nested IRQ interrupts are desired.  Interrupts may be re-enabled over
@       small code sequences where lr is saved before enabling interrupts and 
@       restored after interrupts are again disabled.  */
@
@    /* Interrupt nesting is allowed after calling _tx_thread_irq_nesting_start
@       from IRQ mode with interrupts disabled.  This routine switches to the
@       system mode and returns with IRQ interrupts enabled.
@
@       NOTE:  It is very important to ensure all IRQ interrupts are cleared
@       prior to enabling nested IRQ interrupts.  */
@
#ifdef TX_ENABLE_GIC_SUPPORT
@
@   /*------------------------------------------------------------------------*/
@   /* GIC-based IRQ Dispatch                                                */
@   /*                                                                        */
@   /* This section demonstrates proper GIC interrupt handling:              */
@   /* 1. Read GICC_IAR to acknowledge the interrupt and get the ID          */
@   /* 2. Check for spurious interrupt (ID >= 1020)                          */
@   /* 3. Enable nesting (if configured)                                     */
@   /* 4. Dispatch to appropriate handler                                    */
@   /* 5. Disable nesting (if configured)                                    */
@   /* 6. Write GICC_EOIR with the original IAR value to signal completion   */
@   /*                                                                        */
@   /* CRITICAL: The value written to EOIR must be the same value read from  */
@   /* IAR, including the CPU ID bits for SGIs.                              */
@   /*------------------------------------------------------------------------*/
@
    PUSH    {r4-r7}                             @ Save r4-r7 (r6=ID, r7=padding for alignment)
    LDR     r5, =TX_GIC_CPU_INTERFACE_BASE      @ r5 = GICC base
@
_gic_dispatch_loop:
@   /* Read GICC_IAR to acknowledge interrupt and get ID */
    LDR     r4, [r5, #GICC_IAR]                 @ r4 = IAR value (preserve for EOIR)
    UBFX    r6, r4, #0, #10                     @ r6 = interrupt ID (callee-saved)
@
#ifdef TX_GIC_DEFERRED_EOI
@   /* Save IAR for deferred EOIR in tx_thread_context_restore.S */
    LDR     r0, =_tx_gic_iar
    STR     r4, [r0]                            @ Save full IAR value
#endif
@
@   /* Check for spurious interrupt (ID 1020-1023 are reserved/spurious) */
@   /* ARM GIC spec: IDs 1020-1023 indicate no pending interrupt or special cases */
    CMP     r6, #1020                           @ Check against reserved range start
    BGE     _gic_dispatch_done                  @ Spurious if ID >= 1020, exit loop
@
#ifdef TX_ENABLE_IRQ_NESTING
@   /* CRITICAL: nesting_start clobbers r0-r3 (AAPCS). The interrupt ID is    */
@   /* preserved in r6 (callee-saved) so it survives the function call.       */
    BL      _tx_thread_irq_nesting_start
#endif
@
@   /*------------------------------------------------------------------------*/
@   /* Dispatch the interrupt to the appropriate handler                     */
@   /*                                                                        */
@   /* Option 1: Direct handler call (shown below for timer)                 */
@   /* Option 2: Use a handler table (see _tx_gic_handler_table)             */
@   /*------------------------------------------------------------------------*/
@
#ifdef TX_GIC_USE_HANDLER_TABLE
@   /* Handler table dispatch: _tx_gic_handler_table[id](id) */
@   /* Bounds check: prevent buffer overflow for IDs >= table size */
    LDR     r1, =TX_GIC_MAX_INTERRUPTS          @ r1 = table size
    CMP     r6, r1                              @ Check if ID within table bounds
    BGE     _gic_call_default                   @ OOB: call default handler
    LDR     r1, =_tx_gic_handler_table          @ r1 = handler table base
    LDR     r2, [r1, r6, LSL #2]                @ r2 = handler_table[id]
    CMP     r2, #0                              @ Check for null handler
    BEQ     _gic_call_default                   @ NULL: call default handler
    MOV     r0, r6                              @ r0 = interrupt ID (first arg)
    PUSH    {r4-r7}                             @ Save working registers (16 bytes, aligned)
    BLX     r2                                  @ Call handler(id)
    POP     {r4-r7}                             @ Restore
    B       _gic_handler_done                   @ Skip default handler
_gic_call_default:
@   /* Call default handler for unregistered/OOB interrupts (weak symbol) */
    MOV     r0, r6                              @ r0 = interrupt ID (first arg)
    PUSH    {r4-r7}                             @ Save working registers (16 bytes, aligned)
    BL      _tx_gic_default_handler             @ Call default handler(id)
    POP     {r4-r7}                             @ Restore
_gic_handler_done:
#else
@   /* Direct dispatch: check interrupt ID and call appropriate handler      */
@   /* Example: Assume interrupt ID TX_GIC_TIMER_IRQ is the system tick      */
@   /* Platforms should define TX_GIC_TIMER_IRQ appropriately                */
@
#ifndef TX_GIC_TIMER_IRQ
#define TX_GIC_TIMER_IRQ    29                  @ Default: Private timer (PPI #29)
#endif
@
    CMP     r6, #TX_GIC_TIMER_IRQ               @ Is this the timer interrupt?
    BNE     _gic_not_timer                      @ No, check other sources
    PUSH    {r4-r7}                             @ Save working registers (16 bytes, aligned)
    BL      _tx_timer_interrupt                 @ Call timer interrupt handler
    POP     {r4-r7}                             @ Restore
    B       _gic_complete_irq                   @ Proceed to EOIR
@
_gic_not_timer:
@   /* Add additional interrupt handlers here as needed                      */
@   /* Example: CMP r0, #UART_IRQ; BEQ _handle_uart; etc.                   */
@
@   /* Unhandled interrupt - just acknowledge it                             */
@
#endif /* TX_GIC_USE_HANDLER_TABLE */
@
_gic_complete_irq:
#ifdef TX_ENABLE_IRQ_NESTING
    BL      _tx_thread_irq_nesting_end
#endif

_gic_write_eoir:
@   /* Write GICC_EOIR with original IAR value to complete interrupt         */
@   /* Note: Must be done after handler returns to ensure priority drop      */
#ifndef TX_GIC_DEFERRED_EOI
    STR     r4, [r5, #GICC_EOIR]                @ Write EOIR = IAR value
    DSB                                         @ Ensure write completes
#else
@   /* EOIR is written in tx_thread_context_restore.S after CPSID            */
@   /* This closes the race window for level-triggered interrupts            */
#endif
@
#if defined(TX_ENABLE_IRQ_NESTING) || defined(TX_GIC_DEFERRED_EOI)
@   /* No loop when:                                                         */
@   /* - IRQ nesting: need to unwind stack properly                          */
@   /* - Deferred EOI: single saved IAR, loop would overwrite before EOIR    */
#else
@   /* Loop to handle any pending lower-priority interrupts                  */
@   /* Safe only when IRQ nesting is disabled (IRQs masked during dispatch)  */
    B       _gic_dispatch_loop                  @ Check for more interrupts
#endif
@
_gic_dispatch_done:
    POP     {r4-r7}                             @ Restore registers
@
#else /* !TX_ENABLE_GIC_SUPPORT */
@
#ifdef TX_ENABLE_IRQ_NESTING
    BL      _tx_thread_irq_nesting_start
#endif
@
@    /* For debug purpose, execute the timer interrupt processing here.  In
@       a real system, some kind of status indication would have to be checked
@       before the timer interrupt handler could be called.  */
@
    BL     _tx_timer_interrupt                  @ Timer interrupt handler

#ifdef TX_ENABLE_IRQ_NESTING
    BL      _tx_thread_irq_nesting_end
#endif
@
#endif /* TX_ENABLE_GIC_SUPPORT */
@
@
@    /* Jump to context restore to restore system context.  */
@    /* Note: _tx_thread_irq_nesting_end is already called inside both GIC     */
@    /* and non-GIC paths above (see _gic_complete_irq and non-GIC section).   */
    B       _tx_thread_context_restore
@
@
@    /* This is an example of a vectored IRQ handler.  */
@
@    .global __tx_example_vectored_irq_handler
@__tx_example_vectored_irq_handler:
@
@
@    /* Save initial context and call context save to prepare for 
@       vectored ISR execution.  */
@
@    STMDB   sp!, {r0-r3}                        @ Save some scratch registers
@    MRS     r0, SPSR                            @ Pickup saved SPSR
@    SUB     lr, lr, #4                          @ Adjust point of interrupt 
@    STMDB   sp!, {r0, r10, r12, lr}             @ Store other scratch registers
@    BL      _tx_thread_vectored_context_save    @ Vectored context save
@
@    /* At this point execution is still in the IRQ mode.  The CPSR, point of
@       interrupt, and all C scratch registers are available for use.  In 
@       addition, IRQ interrupts may be re-enabled - with certain restrictions -
@       if nested IRQ interrupts are desired.  Interrupts may be re-enabled over
@       small code sequences where lr is saved before enabling interrupts and 
@       restored after interrupts are again disabled.  */
@
@
@    /* Interrupt nesting is allowed after calling _tx_thread_irq_nesting_start 
@       from IRQ mode with interrupts disabled.  This routine switches to the
@       system mode and returns with IRQ interrupts enabled.  
@       
@       NOTE:  It is very important to ensure all IRQ interrupts are cleared 
@       prior to enabling nested IRQ interrupts.  */
@#ifdef TX_ENABLE_IRQ_NESTING
@    BL      _tx_thread_irq_nesting_start
@#endif
@
@    /* Application IRQ handlers can be called here!  */
@
@    /* If interrupt nesting was started earlier, the end of interrupt nesting
@       service must be called before returning to _tx_thread_context_restore.  
@       This routine returns in processing in IRQ mode with interrupts disabled.  */
@#ifdef TX_ENABLE_IRQ_NESTING
@    BL      _tx_thread_irq_nesting_end
@#endif
@
@    /* Jump to context restore to restore system context.  */
@    B       _tx_thread_context_restore
@
@
#ifdef TX_ENABLE_FIQ_SUPPORT
    .global  __tx_fiq_handler
    .global  __tx_fiq_processing_return
__tx_fiq_handler:
@
@    /* Jump to fiq context save to save system context.  */
    B       _tx_thread_fiq_context_save
__tx_fiq_processing_return:
@
@    /* At this point execution is still in the FIQ mode.  The CPSR, point of
@       interrupt, and all C scratch registers are available for use.  */
@
@    /* Interrupt nesting is allowed after calling _tx_thread_fiq_nesting_start 
@       from FIQ mode with interrupts disabled.  This routine switches to the
@       system mode and returns with FIQ interrupts enabled. 
@
@       NOTE:  It is very important to ensure all FIQ interrupts are cleared 
@       prior to enabling nested FIQ interrupts.  */
#ifdef TX_ENABLE_FIQ_NESTING
    BL      _tx_thread_fiq_nesting_start
#endif
@
@    /* Application FIQ handlers can be called here!  */
@
@    /* If interrupt nesting was started earlier, the end of interrupt nesting
@       service must be called before returning to _tx_thread_fiq_context_restore.  */
#ifdef TX_ENABLE_FIQ_NESTING
    BL      _tx_thread_fiq_nesting_end
#endif
@
@    /* Jump to fiq context restore to restore system context.  */
    B       _tx_thread_fiq_context_restore
@
@
#else
    .global  __tx_fiq_handler
__tx_fiq_handler:
    B       __tx_fiq_handler                    @ FIQ interrupt handler
#endif
@
@
BUILD_OPTIONS:
    .word  _tx_build_options                    @ Reference to bring in
VERSION_ID:
    .word  _tx_version_id                       @ Reference to bring in


#ifdef TX_ENABLE_GIC_SUPPORT
@
@/**************************************************************************/
@/*                                                                        */
@/*  GIC Deferred EOI Storage                                              */
@/*                                                                        */
@/*  When TX_GIC_DEFERRED_EOI is defined, the IAR value is saved here      */
@/*  for later use by tx_thread_context_restore.S                          */
@/*                                                                        */
@/**************************************************************************/
@
#ifdef TX_GIC_DEFERRED_EOI
    .data
    .align  2
    .global _tx_gic_iar
_tx_gic_iar:
    .word   0x3FF                               @ Init to 1023 (spurious) to prevent EOI at startup
    .text
#endif
@
@/**************************************************************************/
@/*                                                                        */
@/*  GIC Handler Table (Optional)                                          */
@/*                                                                        */
@/*  When TX_GIC_USE_HANDLER_TABLE is defined, this table provides a       */
@/*  function pointer array for interrupt handlers. Initialize entries     */
@/*  via _tx_gic_register_handler() or by directly modifying the table.    */
@/*                                                                        */
@/*  Handler prototype: void handler(unsigned int irq_id);                 */
@/*                                                                        */
@/**************************************************************************/
@
#ifdef TX_GIC_USE_HANDLER_TABLE
@
@   Handler table: one function pointer (4 bytes) per interrupt
@   Size = TX_GIC_MAX_INTERRUPTS * 4 bytes
@   Default: 192 interrupts * 4 bytes = 768 bytes
@
    .data
    .align  4
    .global _tx_gic_handler_table
_tx_gic_handler_table:
@   Use .fill instead of .space for better preprocessor compatibility
    .fill   TX_GIC_MAX_INTERRUPTS, 4, 0         @ Array of function pointers
@
    .text
    .align  2
@
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_register_handler                         Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    Register a handler function for a specific interrupt ID.            */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    r0 = Interrupt ID (0 to TX_GIC_MAX_INTERRUPTS-1)                    */
@/*    r1 = Handler function pointer (or NULL to unregister)               */
@/*                                                                        */
@/*  OUTPUT                                                                */
@/*                                                                        */
@/*    r0 = Previous handler (or NULL)                                     */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_register_handler
    .type   _tx_gic_register_handler, %function
_tx_gic_register_handler:
    LDR     r2, =TX_GIC_MAX_INTERRUPTS
    CMP     r0, r2                              @ Check bounds
    MOVGE   r0, #0                              @ Return NULL if out of bounds
    BXGE    lr
    LDR     r2, =_tx_gic_handler_table          @ r2 = table base
    LSL     r3, r0, #2                          @ r3 = offset (id * 4)
    LDR     r0, [r2, r3]                        @ r0 = previous handler
    STR     r1, [r2, r3]                        @ Store new handler
    BX      lr
@
#endif /* TX_GIC_USE_HANDLER_TABLE */
@
@
@/**************************************************************************/
@/*                                                                        */
@/*  FUNCTION                                               RELEASE        */
@/*                                                                        */
@/*    _tx_gic_send_sgi                                 Cortex-R5/GNU      */
@/*                                                           6.x          */
@/*  DESCRIPTION                                                           */
@/*                                                                        */
@/*    Send a Software Generated Interrupt (SGI) to target CPUs.           */
@/*    SGIs are interrupts 0-15, used for inter-processor communication.   */
@/*                                                                        */
@/*  INPUT                                                                 */
@/*                                                                        */
@/*    r0 = SGI ID (0-15)                                                  */
@/*    r1 = Target filter:                                                 */
@/*         0 = Use target list (r2)                                       */
@/*         1 = All CPUs except self                                       */
@/*         2 = Only self                                                  */
@/*    r2 = Target CPU list (bitmask, used when r1=0)                      */
@/*                                                                        */
@/**************************************************************************/
    .global _tx_gic_send_sgi
    .type   _tx_gic_send_sgi, %function
_tx_gic_send_sgi:
    AND     r0, r0, #0xF                        @ Mask to valid SGI range
    AND     r1, r1, #0x3                        @ Mask filter to 2 bits
    AND     r2, r2, #0xFF                       @ Mask target list to 8 bits
    LSL     r1, r1, #24                         @ Shift filter to bits 25:24
    LSL     r2, r2, #16                         @ Shift target list to bits 23:16
    ORR     r0, r0, r1                          @ Combine SGI ID and filter
    ORR     r0, r0, r2                          @ Combine with target list
    LDR     r1, =TX_GIC_DISTRIBUTOR_BASE
    STR     r0, [r1, #GICD_SGIR]                @ Write to GICD_SGIR
    DSB                                         @ Ensure write completes
    BX      lr
@
@
@/**************************************************************************/
@/*                                                                        */
@/*  Default interrupt handler (weak symbol)                               */
@/*                                                                        */
@/*  Applications can override this by defining their own version.         */
@/*  Called for any interrupt without a registered handler.                */
@/*                                                                        */
@/*  INPUT: r0 = Interrupt ID                                              */
@/*                                                                        */
@/**************************************************************************/
    .weak   _tx_gic_default_handler
    .type   _tx_gic_default_handler, %function
_tx_gic_default_handler:
@   /* Default: do nothing, just return                                    */
@   /* Override to implement logging, error handling, or panic             */
    BX      lr
@
#endif /* TX_ENABLE_GIC_SUPPORT */


