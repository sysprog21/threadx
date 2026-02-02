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
@/**   Thread                                                              */
@/**                                                                       */
@/**************************************************************************/
@/**************************************************************************/
#ifdef TX_INCLUDE_USER_DEFINE_FILE
#include "tx_user.h"
#endif

#ifdef TX_ENABLE_FIQ_SUPPORT
SVC_MODE        =     0xD3               @ Disable IRQ/FIQ, SVC mode
SYS_MODE        =     0xDF               @ Disable IRQ/FIQ, SYS mode
IRQ_MODE        =     0xD2               @ Disable IRQ/FIQ, IRQ mode
#else
SVC_MODE        =     0x93               @ Disable IRQ, SVC mode
SYS_MODE        =     0x9F               @ Disable IRQ, SYS mode
IRQ_MODE        =     0x92               @ Disable IRQ, IRQ mode
#endif
@
    .global     _tx_thread_system_state
    .global     _tx_thread_current_ptr
    .global     _tx_irq_processing_return
    .global     _tx_execution_isr_enter
@
@
@/* No 16-bit Thumb mode veneer code is needed for _tx_thread_context_save
@   since it will never be called 16-bit mode.  */
@ 
    .arm
    .text
    .align 2
@/**************************************************************************/ 
@/*                                                                        */ 
@/*  FUNCTION                                               RELEASE        */ 
@/*                                                                        */ 
@/*    _tx_thread_context_save                           Cortex-R5/GNU     */ 
@/*                                                           6.1          */
@/*  AUTHOR                                                                */
@/*                                                                        */
@/*    William E. Lamie, Microsoft Corporation                             */
@/*                                                                        */
@/*  DESCRIPTION                                                           */
@/*                                                                        */ 
@/*    This function saves the context of an executing thread in the       */ 
@/*    beginning of interrupt processing.  The function also ensures that  */ 
@/*    the system stack is used upon return to the calling ISR.            */ 
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
@/*    ISRs                                                                */ 
@/*                                                                        */ 
@/*  RELEASE HISTORY                                                       */ 
@/*                                                                        */ 
@/*    DATE              NAME                      DESCRIPTION             */
@/*                                                                        */
@/*  09-30-2020     William E. Lamie         Initial Version 6.1           */
@/*                                                                        */
@/**************************************************************************/
@VOID   _tx_thread_context_save(VOID)
@{
    .global _tx_thread_context_save
    .type   _tx_thread_context_save,function
_tx_thread_context_save:
@
@    /* Upon entry to this routine, it is assumed that IRQ interrupts are locked
@       out, we are in IRQ mode, and all registers are intact.  */
@
@    /* Check for a nested interrupt condition.  */
@    if (_tx_thread_system_state++)
@    {
@
    STMDB   sp!, {r0-r3}                    @ Save some working registers 
#ifdef TX_ENABLE_FIQ_SUPPORT
    CPSID   if                              @ Disable FIQ interrupts
#endif
    LDR     r3, =_tx_thread_system_state    @ Pickup address of system state variable
    LDR     r2, [r3]                        @ Pickup system state
    CMP     r2, #0                          @ Is this the first interrupt?
    BEQ     __tx_thread_not_nested_save     @ Yes, not a nested context save
@
@    /* Nested interrupt condition.  */
@
    ADD     r2, r2, #1                      @ Increment the interrupt counter
    STR     r2, [r3]                        @ Store it back in the variable
@
@   /* Save the rest of the scratch registers on the stack and return to the
@      calling ISR.  */
@
    MRS     r0, SPSR                        @ Pickup saved SPSR
    SUB     lr, lr, #4                      @ Adjust point of interrupt 
    STMDB   sp!, {r0, r10, r12, lr}         @ Store other registers
@
@    /* Return to the ISR.  */
@
    MOV     r10, #0                         @ Clear stack limit

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                            @ Save ISR lr
    BL      _tx_execution_isr_enter         @ Call the ISR enter function
    POP     {lr}                            @ Recover ISR lr
#endif

    B       __tx_irq_processing_return      @ Continue IRQ processing
@
__tx_thread_not_nested_save:
@    }
@
@    /* Otherwise, not nested, check to see if a thread was running.  */
@    else if (_tx_thread_current_ptr)
@    {
@
    ADD     r2, r2, #1                      @ Increment the interrupt counter
    STR     r2, [r3]                        @ Store it back in the variable
    LDR     r1, =_tx_thread_current_ptr     @ Pickup address of current thread ptr
    LDR     r0, [r1]                        @ Pickup current thread pointer
    CMP     r0, #0                          @ Is it NULL?
    BEQ     __tx_thread_idle_system_save    @ If so, interrupt occurred in
                                            @   scheduling loop - nothing needs saving!
@
@    /* Save minimal context of interrupted thread on thread's stack.  */
@    /* Stack frame: r0-r3, r10, r12, PC, CPSR (32 bytes) */
@
    MOV     r2, sp                          @ r2 = IRQ stack pointer (has saved r0-r3)
@
@    /* Pickup SPSR and adjust return address BEFORE switching modes */
    MRS     r3, SPSR                        @ r3 = saved SPSR (thread's CPSR)
    SUB     lr, lr, #4                      @ Adjust point of interrupt (lr_irq)
    MOV     r1, lr                          @ Save lr_irq in r1 (before mode switch!)
@
@    /* Switch to the thread's actual mode (from SPSR) to access its stack */
@    /* r3 contains SPSR_irq = thread's saved CPSR */
    AND     r4, r3, #0x1F                   @ r4 = thread's mode bits
    CMP     r4, #0x13                       @ Was thread in SVC mode?
    BEQ     __tx_save_svc_mode
@
@    /* Thread was in SYS/USR mode - switch to SYS mode */
@    /* Note: USR and SYS share the same sp/lr register bank */
    MOV     r4, #SYS_MODE                   @ SYS mode + interrupts disabled
    MSR     CPSR_c, r4                      @ Switch to SYS mode
    B       __tx_save_context_on_stack
@
__tx_save_svc_mode:
@    /* Thread was in SVC mode - switch to SVC mode */
    MOV     r4, #SVC_MODE                   @ SVC mode + interrupts disabled
    MSR     CPSR_c, r4                      @ Switch to SVC mode
@
__tx_save_context_on_stack:
@    /* Now sp = thread's actual stack pointer (sp_sys or sp_svc) */
@
@    /* Save SPSR and PC to stack */
    STR     r3, [sp, #-4]!                  @ Push SPSR at [SP-4]
    STR     r1, [sp, #-4]!                  @ Push lr_irq (as PC) at [SP-8]
@
@    /* Recover original r0-r3 from IRQ stack (r2 still points to IRQ stack) */
    LDMIA   r2, {r0-r3}                     @ Recover thread's r0-r3 from IRQ stack
@
@    /* Save remaining registers */
    STMDB   sp!, {r0-r3, r10, r12}          @ Save r0-r3, r10, r12 (final SP = base-32)
@
@    /* Save the thread's stack pointer in the thread's control block.  */
@    _tx_thread_current_ptr -> tx_thread_stack_ptr =  sp;
@
    LDR     r1, =_tx_thread_current_ptr     @ Reload current thread pointer address
    LDR     r0, [r1]                        @ Get current thread pointer
    STR     sp, [r0, #8]                    @ Save updated thread stack pointer
@
@    /* Switch to IRQ mode to use dedicated IRQ stack for ISR execution.  */
    MOV     r4, #IRQ_MODE                   @ IRQ mode + interrupts disabled
    MSR     CPSR_c, r4                      @ Switch to IRQ mode
    ADD     sp, sp, #16                     @ Pop stale r0-r3 from IRQ stack (4 regs * 4 bytes)
    MOV     r10, #0                         @ Clear stack limit

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                            @ Save ISR lr
    BL      _tx_execution_isr_enter         @ Call the ISR enter function
    POP     {lr}                            @ Recover ISR lr
#endif

    B       __tx_irq_processing_return      @ Continue IRQ processing
@
@    }
@    else
@    {
@
__tx_thread_idle_system_save:
@
@    /* Interrupt occurred in the scheduling loop.  */
@
    MOV     r10, #0                         @ Clear stack limit

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                            @ Save ISR lr
    BL      _tx_execution_isr_enter         @ Call the ISR enter function
    POP     {lr}                            @ Recover ISR lr
#endif

    ADD     sp, sp, #16                     @ Recover saved registers
    B       __tx_irq_processing_return      @ Continue IRQ processing
@
@    }
@}
