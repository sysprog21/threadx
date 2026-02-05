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

    .arm

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
    .global     _tx_thread_execute_ptr
    .global     _tx_timer_time_slice
    .global     _tx_thread_schedule
    .global     _tx_thread_preempt_disable
    .global     _tx_execution_isr_exit
@
@
@/* No 16-bit Thumb mode veneer code is needed for _tx_thread_context_restore
@   since it will never be called 16-bit mode.  */
@ 
    .arm
    .text
    .align 2
@/**************************************************************************/ 
@/*                                                                        */ 
@/*  FUNCTION                                               RELEASE        */ 
@/*                                                                        */ 
@/*    _tx_thread_context_restore                        Cortex-R5/GNU     */ 
@/*                                                           6.1          */
@/*  AUTHOR                                                                */
@/*                                                                        */
@/*    William E. Lamie, Microsoft Corporation                             */
@/*                                                                        */
@/*  DESCRIPTION                                                           */
@/*                                                                        */ 
@/*    This function restores the interrupt context if it is processing a  */ 
@/*    nested interrupt.  If not, it returns to the interrupt thread if no */ 
@/*    preemption is necessary.  Otherwise, if preemption is necessary or  */ 
@/*    if no thread was running, the function returns to the scheduler.    */ 
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
@/*    _tx_thread_schedule                   Thread scheduling routine     */ 
@/*                                                                        */ 
@/*  CALLED BY                                                             */ 
@/*                                                                        */ 
@/*    ISRs                                  Interrupt Service Routines    */ 
@/*                                                                        */ 
@/*  RELEASE HISTORY                                                       */ 
@/*                                                                        */ 
@/*    DATE              NAME                      DESCRIPTION             */
@/*                                                                        */
@/*  09-30-2020     William E. Lamie         Initial Version 6.1           */
@/*                                                                        */
@/**************************************************************************/
@VOID   _tx_thread_context_restore(VOID)
@{
    .global _tx_thread_context_restore
    .type   _tx_thread_context_restore,function
_tx_thread_context_restore:
@
@    /* Lockout interrupts.  */
@
#ifdef TX_ENABLE_FIQ_SUPPORT
    CPSID   if                              @ Disable IRQ and FIQ interrupts
#else
    CPSID   i                               @ Disable IRQ interrupts
#endif

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY
@
@    /* Call the ISR exit function to indicate an ISR is complete.  */
@
    BL      _tx_execution_isr_exit          @ Call the ISR exit function
#endif
@
@    /* Determine if interrupts are nested.  */
@    if (--_tx_thread_system_state)
@    {
@
    LDR     r3, =_tx_thread_system_state    @ Pickup address of system state variable
    LDR     r2, [r3]                        @ Pickup system state
    SUB     r2, r2, #1                      @ Decrement the counter
    STR     r2, [r3]                        @ Store the counter 
    CMP     r2, #0                          @ Was this the first interrupt?
    BEQ     __tx_thread_not_nested_restore  @ If so, not a nested restore
@
@    /* Interrupts are nested.  */
@
@    /* Just recover the saved registers and return to the point of 
@       interrupt.  */
@
    LDMIA   sp!, {r0, r10, r12, lr}         @ Recover SPSR, POI, and scratch regs
    MSR     SPSR_cxsf, r0                   @ Put SPSR back
    LDMIA   sp!, {r0-r3}                    @ Recover r0-r3
    MOVS    pc, lr                          @ Return to point of interrupt
@
@    }
__tx_thread_not_nested_restore:
@
@    /* Determine if a thread was interrupted and no preemption is required.  */
@    else if (((_tx_thread_current_ptr) && (_tx_thread_current_ptr == _tx_thread_execute_ptr))
@               || (_tx_thread_preempt_disable))
@    {
@
    LDR     r1, =_tx_thread_current_ptr     @ Pickup address of current thread ptr
    LDR     r0, [r1]                        @ Pickup actual current thread pointer
    CMP     r0, #0                          @ Is it NULL?
    BEQ     __tx_thread_idle_system_restore @ Yes, idle system was interrupted
@
    LDR     r3, =_tx_thread_preempt_disable @ Pickup preempt disable address
    LDR     r2, [r3]                        @ Pickup actual preempt disable flag
    CMP     r2, #0                          @ Is it set?
    BNE     __tx_thread_no_preempt_restore  @ Yes, don't preempt this thread
    LDR     r3, =_tx_thread_execute_ptr     @ Pickup address of execute thread ptr
    LDR     r2, [r3]                        @ Pickup actual execute thread pointer
    CMP     r0, r2                          @ Is the same thread highest priority?
    BNE     __tx_thread_preempt_restore     @ No, preemption needs to happen
@
@
__tx_thread_no_preempt_restore:
@
@    /* Restore interrupted thread or ISR.  */
@
@    /* Switch to SYS mode and pickup the saved stack pointer.  */
@    tmp_ptr =  _tx_thread_current_ptr -> tx_thread_stack_ptr;
@
@    /* Load PC and CPSR from thread stack while in IRQ mode */
    LDR     r1, [r0, #8]                    @ r1 = thread stack pointer
    ADD     r2, r1, #24                     @ r2 = address of saved PC (skip 6 regs)
    LDMIA   r2, {r3, r12}                   @ r3 = PC, r12 = CPSR
@
@    /* Load CPSR into SPSR_irq and PC into lr */
    MSR     SPSR_cxsf, r12                  @ Load CPSR into SPSR_irq
    MOV     lr, r3                          @ Load return address
@
@    /* Switch to thread's actual mode (not blindly SYS) */
    MOV     r3, r12                         @ Copy CPSR to r3
    AND     r3, r3, #0x1F                   @ Isolate mode bits
    CMP     r3, #0x13                       @ Is thread in SVC mode?
    BEQ     __tx_restore_svc_mode           @ Yes, use SVC mode
@
@    /* Thread in SYS/USR mode (0x1F or 0x10) */
    CPS     #0x1F                           @ Switch to SYS mode
    MOV     sp, r1                          @ Set SP_sys to thread stack
    B       __tx_restore_continue
@
__tx_restore_svc_mode:
@    /* Thread in SVC mode (0x13) */
    CPS     #0x13                           @ Switch to SVC mode
    MOV     sp, r1                          @ Set SP_svc to thread stack
@
__tx_restore_continue:
    LDMIA   sp!, {r0-r3, r10, r12}          @ Restore r0-r3, r10, r12
    ADD     sp, sp, #8                      @ Skip saved PC and CPSR (8 bytes)
@
@    /* Switch back to IRQ mode for proper exception return */
    CPS     #0x12                           @ Switch to IRQ mode
@
@    /* Return from exception (SPSR_irq->CPSR, lr->PC) */
    MOVS    pc, lr                          @ Return from exception
@
@    }
@    else
@    {
__tx_thread_preempt_restore:
@
@    /* Restore context and convert to full thread frame for scheduler. */
@    /* Context on thread stack: r0-r3, r10, r12, LR, SPSR (RFE-compatible). */
@
@    /* Determine thread's mode from saved CPSR */
    LDR     r3, [r0, #8]                    @ r3 = thread stack pointer
    LDR     r12, [r3, #28]                  @ r12 = saved CPSR
    AND     r12, r12, #0x1F                 @ r12 = mode bits
    CMP     r12, #0x13                      @ SVC mode?
    BEQ     __tx_preempt_svc_mode
@
@    /* Thread was in SYS mode */
    MOV     r12, #SYS_MODE                  @ SYS mode + interrupts disabled
    MSR     CPSR_c, r12                     @ Switch to SYS mode
    B       __tx_preempt_load_context
@
__tx_preempt_svc_mode:
    MOV     r12, #SVC_MODE                  @ SVC mode + interrupts disabled
    MSR     CPSR_c, r12                     @ Switch to SVC mode
@
__tx_preempt_load_context:
    LDR     sp, [r0, #8]                    @ Restore thread stack pointer
    MOV     r0, lr                          @ Save thread's LR (SYS or SVC) in r0
                                            @   (r0 is scratch here, holding thread ptr
                                            @    which we reload later)

@
@    /* Read metadata from the minimal interrupt frame using indexed loads.
@       r1-r3 are scratch at this point.
@       Minimal frame layout: [r0][r1][r2][r3][r10][r12][PC][SPSR]
@                              +0  +4  +8  +12 +16  +20  +24 +28            */
@
    LDR     r1, [sp, #24]                   @ r1 = PC (point of interrupt)
    LDR     r2, [sp, #28]                   @ r2 = SPSR
    MOV     r3, sp                          @ r3 = minimal frame base address
    LDR     r10, [sp, #16]                  @ r10 = thread's r10 (from frame)
    LDR     r12, [sp, #20]                  @ r12 = thread's r12 (from frame)
@
@    /* Advance thread's SP past the consumed minimal frame. */
    ADD     sp, sp, #32                     @ Thread's SP restored to pre-interrupt value
@
@    /* Switch to SVC mode to build the full interrupt frame.
@       Use CPS to avoid consuming a register for the mode constant.
@       Interrupts remain disabled (I/F bits unchanged by CPS). */
#ifdef TX_ENABLE_FIQ_SUPPORT
    CPSID   if, #0x13                       @ Disable IRQ+FIQ, enter SVC mode
#else
    CPSID   i, #0x13                        @ Disable IRQ, enter SVC mode
#endif
@
@    /* Build the full interrupt frame on the SVC stack.
@       The frame must be: [r0-r12, lr, pc] = 15 registers = 60 bytes.
@       For SVC-mode threads, this frame overlaps with the minimal frame in
@       memory (same stack), so r0-r3 must be read from the frame BEFORE
@       callee-saved writes overwrite those addresses.
@
@       Calculated SP:
@       Old SP (r3) points to base of minimal frame.
@       New SP should be (Old SP + 32) - 60 = Old SP - 28.
@       We use r3 to calculate this to ensure correctness regardless of
@       whether we came from SYS or SVC mode (sp is banked). */
@
    SUB     sp, r3, #28                     @ Allocate full frame (15 regs)
@
@    /* Save the thread's LR (saved in r0) to the stack.
@       We do this early to free up r0 for use as scratch in the copy loop.
@       Offset 52 corresponds to LR slot. */
    STR     r0, [sp, #52]                   @ Save LR
@
@    /* Fill r0-r3 from minimal frame FIRST (before overlap can occur). */
    LDR     r0, [r3, #0]                    @ Thread's r0
    STR     r0, [sp, #0]                    @ -> frame slot r0
    LDR     r0, [r3, #4]                    @ Thread's r1
    STR     r0, [sp, #4]                    @ -> frame slot r1
    LDR     r0, [r3, #8]                    @ Thread's r2
    STR     r0, [sp, #8]                    @ -> frame slot r2
    LDR     r0, [r3, #12]                   @ Thread's r3
    STR     r0, [sp, #12]                   @ -> frame slot r3
@
@    /* Fill callee-saved registers from physical registers. */
    STR     r4, [sp, #16]                   @ r4  (callee-saved, in physical reg)
    STR     r5, [sp, #20]                   @ r5
    STR     r6, [sp, #24]                   @ r6
    STR     r7, [sp, #28]                   @ r7
    STR     r8, [sp, #32]                   @ r8
    STR     r9, [sp, #36]                   @ r9
    STR     r10, [sp, #40]                  @ r10 (loaded from frame)
    STR     r11, [sp, #44]                  @ r11 (callee-saved, in physical reg)
    STR     r12, [sp, #48]                  @ r12 (loaded from frame)
@   STR     lr, [sp, #52]                   @ (LR already saved above)
    STR     r1, [sp, #56]                   @ pc  (point of interrupt)
@
@    /* Prepare SPSR in r4 for the type/SPSR header push below. */
    MOV     r4, r2                          @ r4 = SPSR
@
    LDR     r1, =_tx_thread_current_ptr     @ Pickup address of current thread ptr
    LDR     r0, [r1]                        @ Pickup current thread pointer
@
#ifdef TX_ENABLE_VFP_SUPPORT
    LDR     r2, [r0, #144]                  @ Pickup the VFP enabled flag
    CMP     r2, #0                          @ Is the VFP enabled?
    BEQ     _tx_skip_irq_vfp_save           @ No, skip VFP IRQ save
    VMRS    r2, FPSCR                       @ Pickup the FPSCR
    STR     r2, [sp, #-4]!                  @ Save FPSCR
    VSTMDB  sp!, {D0-D15}                   @ Save D0-D15
_tx_skip_irq_vfp_save:
#endif
@
    MOV     r3, #1                          @ Build interrupt stack type
    STMDB   sp!, {r3, r4}                   @ Save interrupt stack type and SPSR
    STR     sp, [r0, #8]                    @ Save stack pointer in thread control
                                            @   block
@
@    /* Save the remaining time-slice and disable it.  */
@    if (_tx_timer_time_slice)
@    {
@
    LDR     r3, =_tx_timer_time_slice       @ Pickup time-slice variable address
    LDR     r2, [r3]                        @ Pickup time-slice
    CMP     r2, #0                          @ Is it active?
    BEQ     __tx_thread_dont_save_ts        @ No, don't save it
@
@        _tx_thread_current_ptr -> tx_thread_time_slice =  _tx_timer_time_slice;
@        _tx_timer_time_slice =  0;
@
    STR     r2, [r0, #24]                   @ Save thread's time-slice
    MOV     r2, #0                          @ Clear value
    STR     r2, [r3]                        @ Disable global time-slice flag
@
@    }
__tx_thread_dont_save_ts:
@
@
@    /* Clear the current task pointer.  */
@    _tx_thread_current_ptr =  TX_NULL;
@
    MOV     r0, #0                          @ NULL value
    STR     r0, [r1]                        @ Clear current thread pointer
@
@    /* Return to the scheduler.  */
@    _tx_thread_schedule();
@
    B       _tx_thread_schedule             @ Return to scheduler
@    }
@
__tx_thread_idle_system_restore:
@
@    /* Just return back to the scheduler!  */
@
    MOV     r0, #SVC_MODE                   @ Build SVC mode CPSR
    MSR     CPSR_c, r0                      @ Enter SVC mode
    B       _tx_thread_schedule             @ Return to scheduler
@}



