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

    .global     _tx_thread_system_state
    .global     _tx_thread_current_ptr
    .global     __tx_fiq_processing_return
    .global     _tx_execution_isr_enter
@
@
@/* No 16-bit Thumb mode veneer code is needed for _tx_thread_fiq_context_save
@   since it will never be called 16-bit mode.  */
@
    .arm
    .text
    .align 2
@/**************************************************************************/ 
@/*                                                                        */ 
@/*  FUNCTION                                               RELEASE        */ 
@/*                                                                        */ 
@/*    _tx_thread_fiq_context_save                      Cortex-R5/GNU      */ 
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
@ VOID   _tx_thread_fiq_context_save(VOID)
@{
    .global  _tx_thread_fiq_context_save
    .type    _tx_thread_fiq_context_save,function
_tx_thread_fiq_context_save:
@
@    /* Upon entry to this routine, it is assumed that IRQ interrupts are locked
@       out, we are in IRQ mode, and all registers are intact.  */
@
@    /* Check for a nested interrupt condition.  */
@    if (_tx_thread_system_state++)
@    {
@
    STMDB   sp!, {r0-r3}                        @ Save some working registers 
    LDR     r3, =_tx_thread_system_state        @ Pickup address of system state variable
    LDR     r2, [r3]                            @ Pickup system state
    CMP     r2, #0                              @ Is this the first interrupt?
    BEQ     __tx_thread_fiq_not_nested_save     @ Yes, not a nested context save
@
@    /* Nested interrupt condition.  */
@
    ADD     r2, r2, #1                          @ Increment the interrupt counter
    STR     r2, [r3]                            @ Store it back in the variable
@
@    /* Save the rest of the scratch registers on the stack and return to the
@       calling ISR.  */
@
    MRS     r0, SPSR                            @ Pickup saved SPSR
    SUB     lr, lr, #4                          @ Adjust point of interrupt 
    STMDB   sp!, {r0, r10, r12, lr}             @ Store other registers
@
@    /* Return to the ISR.  */
@
    MOV     r10, #0                             @ Clear stack limit

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                                @ Save ISR lr
    BL      _tx_execution_isr_enter             @ Call the ISR enter function
    POP     {lr}                                @ Recover ISR lr
#endif

    B       __tx_fiq_processing_return          @ Continue FIQ processing 
@
__tx_thread_fiq_not_nested_save:
@    }  
@
@    /* Otherwise, not nested, check to see if a thread was running.  */
@    else if (_tx_thread_current_ptr)
@    {   
@
    ADD     r2, r2, #1                          @ Increment the interrupt counter
    STR     r2, [r3]                            @ Store it back in the variable
    LDR     r1, =_tx_thread_current_ptr         @ Pickup address of current thread ptr
    LDR     r0, [r1]                            @ Pickup current thread pointer
    CMP     r0, #0                              @ Is it NULL?
    BEQ     __tx_thread_fiq_idle_system_save    @ If so, interrupt occurred in 
@                                               @   scheduling loop - nothing needs saving! 
@
@    /* Save minimal context of interrupted thread on thread's stack.  */
@    /* Must switch to SYS mode and set SP before saving context */
@    /* Stack frame ordered for RFE compatibility: r0-r3, r10, r12, PC, CPSR */
@    /* Note: FIQ mode has banked r8-r12, so we save thread's r10/r12 from SYS mode. */
@
@    /* Get thread's stack pointer from TCB (r0 = current thread ptr) */
    MOV     r2, sp                              @ r2 = FIQ stack pointer (has saved r0-r3)
    LDR     r1, [r0, #8]                        @ r1 = thread stack pointer from TCB
@
@    /* Pickup SPSR and adjust return address BEFORE switching modes */
    MRS     r3, SPSR                            @ r3 = saved SPSR
    SUB     lr, lr, #4                          @ Adjust point of interrupt (lr_fiq)
    MOV     r1, lr                              @ Save lr_fiq in r1 (before mode switch!)
@
@    /* Switch to SYS mode and set SP to thread's stack pointer */
    CPS     #0x1F                               @ Switch to SYS mode
    LDR     sp, [r0, #8]                        @ Load thread SP directly into sp
@
@    /* Save SPSR and LR to final stack positions (r2 still points to FIQ stack) */
    STR     r3, [sp, #-4]!                      @ Push SPSR at [SP-4]
    STR     r1, [sp, #-4]!                      @ Push lr_fiq (as PC) at [SP-8]
@
@    /* Now recover original r0-r3 from exception stack (r2 reg not yet modified) */
    LDMIA   r2, {r0-r3}                         @ Recover thread's r0-r3 from FIQ stack
@
@    /* Save remaining registers below LR */
    STMDB   sp!, {r0-r3, r10, r12}              @ Save r0-r3, r10, r12 (final SP = base-32)
@
@    /* Save the thread's stack pointer in the thread's control block.  */
@    _tx_thread_current_ptr -> tx_thread_stack_ptr =  sp;
@
    LDR     r1, =_tx_thread_current_ptr         @ Reload current thread pointer address
    LDR     r0, [r1]                            @ Get current thread pointer
    STR     sp, [r0, #8]                        @ Save updated thread stack pointer
@
@    /* Switch to FIQ mode to use dedicated FIQ stack for ISR execution.  */
@    /* This prevents thread stack overflow during deep interrupt nesting. */
@    /* Note: r0-r3 on FIQ stack are now stale but will be popped on return. */
@
    CPS     #0x11                               @ Switch to FIQ mode
    ADD     sp, sp, #16                         @ Pop stale r0-r3 from FIQ stack (4 regs * 4 bytes)
    MOV     r10, #0                             @ Clear stack limit (also saved to thread stack)

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                                @ Save ISR lr
    BL      _tx_execution_isr_enter             @ Call the ISR enter function
    POP     {lr}                                @ Recover ISR lr
#endif

    B       __tx_fiq_processing_return          @ Continue FIQ processing 
@
@   }
@   else
@   {
@
__tx_thread_fiq_idle_system_save:
@
@    /* Interrupt occurred in the scheduling loop.  */
@
#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR enter function to indicate an ISR is executing.  */
@
    PUSH    {lr}                                @ Save ISR lr
    BL      _tx_execution_isr_enter             @ Call the ISR enter function
    POP     {lr}                                @ Recover ISR lr
#endif
@
@    /* Not much to do here, save the current SPSR and LR for possible
@       use in IRQ interrupted in idle system conditions, and return to 
@       FIQ interrupt processing.  */
@
    MRS     r0, SPSR                            @ Pickup saved SPSR
    SUB     lr, lr, #4                          @ Adjust point of interrupt 
    STMDB   sp!, {r0, lr}                       @ Store other registers that will get used
@                                               @   or stripped off the stack in context 
@                                               @   restore 
    B       __tx_fiq_processing_return          @ Continue FIQ processing  
@
@    }
@}  

