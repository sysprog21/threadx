# Eclipse ThreadX for Cortex-R5

Using the GNU Tools

## 1. Building the ThreadX Runtime Library

First make sure you are in the `example_build` directory. Also, make sure that you have setup your path and other environment variables necessary for the GNU development environment.

At this point you may run the `build_threadx.bat` batch file. This will build the ThreadX runtime environment in the `example_build` directory.

You should observe assembly and compilation of a series of ThreadX source files. At the end of the batch file, they are all combined into the runtime library file: `tx.a`. This file must be linked with your application in order to use ThreadX.

## 2. Demonstration System

Building the demonstration is easy; simply execute the `build_threadx_sample.bat` batch file while inside the `example_build` directory.

You should observe the compilation of `sample_threadx.c` (which is the demonstration application) and linking with `tx.a`. The resulting file `DEMO` is a binary file that can be downloaded and executed.

## 3. System Initialization

The entry point in ThreadX for the Cortex-R5 using GNU tools is at label `_start`. This is defined within the modified version of the GNU startup code - `crt0.S`.

The ThreadX `tx_initialize_low_level.S` file is responsible for setting up various system data structures, the interrupt vectors, and a periodic timer interrupt source. By default, the vector area is defined to be located at the `__vectors` label, which is defined in `reset.S`. This area is typically located at 0. In situations where this is impossible, the vectors at the `__vectors` label should be copied to address 0.

This is also where initialization of a periodic timer interrupt source should take place.

In addition, `_tx_initialize_low_level` defines the first available address for use by the application, which is supplied as the sole input parameter to your application definition function, `tx_application_define`.

## 4. Assembler / Compiler Switches

The following are compiler switches used in building the demonstration system:

### Compiler/Assembler Switches

| Switch | Meaning |
|--------|---------|
| `-g` | Specifies debug information |
| `-c` | Specifies object code generation |
| `-mcpu=cortex-r5` | Specifies target CPU |

### Linker Switches

| Switch | Meaning |
|--------|---------|
| `-o sample_threadx.out` | Specifies output file |
| `-M > sample_threadx.map` | Specifies demo map file |
| `-A cortex-r5` | Specifies target architecture |
| `-T sample_threadx.ld` | Specifies the loader control file |

### Application Defines (`-D` option)

#### TX_ENABLE_FIQ_SUPPORT

This assembler define enables FIQ interrupt handling support in the ThreadX assembly files. If used, it should be used on all assembly files and the generic C source of ThreadX should be compiled with `TX_ENABLE_FIQ_SUPPORT` defined as well.

#### TX_ENABLE_IRQ_NESTING

This assembler define enables IRQ nested support. If IRQ nested interrupt support is needed, this define should be applied to `tx_initialize_low_level.S`.

#### TX_ENABLE_FIQ_NESTING

This assembler define enables FIQ nested support. If FIQ nested interrupt support is needed, this define should be applied to `tx_initialize_low_level.S`. In addition, IRQ nesting should also be enabled.

#### TX_DISABLE_ERROR_CHECKING

If defined before `tx_api.h` is included, this define causes basic ThreadX error checking to be disabled. Please see Chapter 2 in the "ThreadX User Guide" for more details.

#### TX_MAX_PRIORITIES

Defines the priority levels for ThreadX. Legal values range from 32 through 1024 (inclusive) and MUST be evenly divisible by 32. Increasing the number of priority levels supported increases the RAM usage by 128 bytes for every group of 32 priorities. However, there is only a negligible effect on performance. By default, this value is set to 32 priority levels.

#### TX_MINIMUM_STACK

Defines the minimum stack size (in bytes). It is used for error checking when threads are created. The default value is port-specific and is found in `tx_port.h`.

#### TX_TIMER_THREAD_STACK_SIZE

Defines the stack size (in bytes) of the internal ThreadX timer thread. This thread processes all thread sleep requests as well as all service call timeouts. In addition, all application timer callback routines are invoked from this context. The default value is port-specific and is found in `tx_port.h`.

#### TX_TIMER_THREAD_PRIORITY

Defines the priority of the internal ThreadX timer thread. The default value is priority 0 - the highest priority in ThreadX. The default value is defined in `tx_port.h`.

#### TX_TIMER_PROCESS_IN_ISR

Defined, this option eliminates the internal system timer thread for ThreadX. This results in improved performance on timer events and smaller RAM requirements because the timer stack and control block are no longer needed. However, using this option moves all the timer expiration processing to the timer ISR level. By default, this option is not defined.

#### TX_REACTIVATE_INLINE

Defined, this option performs reactivation of ThreadX timers in-line instead of using a function call. This improves performance but slightly increases code size. By default, this option is not defined.

#### TX_DISABLE_STACK_FILLING

Defined, placing the `0xEF` value in each byte of each thread's stack is disabled. By default, this option is not defined.

#### TX_ENABLE_STACK_CHECKING

Defined, this option enables ThreadX runtime stack checking, which includes analysis of how much stack has been used and examination of data pattern "fences" before and after the stack area. If a stack error is detected, the registered application stack error handler is called. This option does result in slightly increased overhead and code size. Please review the `tx_thread_stack_error_notify` API for more information. By default, this option is not defined.

#### TX_DISABLE_PREEMPTION_THRESHOLD

Defined, this option disables the preemption-threshold feature and slightly reduces code size and improves performance. Of course, the preemption-threshold capabilities are no longer available. By default, this option is not defined.

#### TX_DISABLE_REDUNDANT_CLEARING

Defined, this option removes the logic for initializing ThreadX global C data structures to zero. This should only be used if the compiler's initialization code sets all uninitialized C global data to zero. Using this option slightly reduces code size and improves performance during initialization. By default, this option is not defined.

#### TX_DISABLE_NOTIFY_CALLBACKS

Defined, this option disables the notify callbacks for various ThreadX objects. Using this option slightly reduces code size and improves performance.

#### TX_BLOCK_POOL_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on block pools. By default, this option is not defined.

#### TX_BYTE_POOL_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on byte pools. By default, this option is not defined.

#### TX_EVENT_FLAGS_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on event flags groups. By default, this option is not defined.

#### TX_MUTEX_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on mutexes. By default, this option is not defined.

#### TX_QUEUE_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on queues. By default, this option is not defined.

#### TX_SEMAPHORE_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on semaphores. By default, this option is not defined.

#### TX_THREAD_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on threads. By default, this option is not defined.

#### TX_TIMER_ENABLE_PERFORMANCE_INFO

Defined, this option enables the gathering of performance information on timers. By default, this option is not defined.

#### TX_ENABLE_EVENT_TRACE

Defined, this option enables the internal ThreadX trace feature. The trace buffer is supplied at a later time via an application call to `tx_trace_enable`.

#### TX_TRACE_TIME_SOURCE

This defines the time-stamp source for event tracing. This define is only pertinent if the ThreadX library is built with `TX_ENABLE_EVENT_TRACE` defined.

#### TX_TRACE_TIME_MASK

This defines the number of valid bits in the event trace time-stamp source defined previously. If the time-stamp source is 16-bits, this value should be `0xFFFF`. Alternatively, if the time-stamp source is 32-bits, this value should be `0xFFFFFFFF`. This define is only pertinent if the ThreadX library is built with `TX_ENABLE_EVENT_TRACE` defined.

## 5. Register Usage and Stack Frames

The GNU compiler assumes that registers `r0-r3` (`a1-a4`) and `r12` (`ip`) are scratch registers for each function. All other registers used by a C function must be preserved by the function. ThreadX takes advantage of this in situations where a context switch happens as a result of making a ThreadX service call (which is itself a C function). In such cases, the saved context of a thread is only the non-scratch registers.

The following defines the saved context stack frames for context switches that occur as a result of interrupt handling or from thread-level API calls. All suspended threads have one of these two types of stack frames. The top of the suspended thread's stack is pointed to by `tx_thread_stack_ptr` in the associated thread control block `TX_THREAD`.

### Stack Frame Layouts

| Offset | Interrupted Stack Frame | Non-Interrupt Stack Frame |
|--------|-------------------------|---------------------------|
| 0x00 | 1 | 0 |
| 0x04 | CPSR | CPSR |
| 0x08 | r0 (a1) | r4 (v1) |
| 0x0C | r1 (a2) | r5 (v2) |
| 0x10 | r2 (a3) | r6 (v3) |
| 0x14 | r3 (a4) | r7 (v4) |
| 0x18 | r4 (v1) | r8 (v5) |
| 0x1C | r5 (v2) | r9 (v6) |
| 0x20 | r6 (v3) | r10 (v7) |
| 0x24 | r7 (v4) | r11 (fp) |
| 0x28 | r8 (v5) | r14 (lr) |
| 0x2C | r9 (v6) | |
| 0x30 | r10 (v7) | |
| 0x34 | r11 (fp) | |
| 0x38 | r12 (ip) | |
| 0x3C | r14 (lr) | |
| 0x40 | PC | |

## 6. Improving Performance

The distribution version of ThreadX is built without any compiler optimizations. This makes it easy to debug because you can trace or set breakpoints.

In addition, you can eliminate the ThreadX basic API error checking by compiling your application code with the symbol `TX_DISABLE_ERROR_CHECKING` defined.

## 7. Interrupt Handling

ThreadX provides complete and high-performance interrupt handling for Cortex-R5 targets. There are a certain set of requirements that are defined in the following sub-sections.

### 7.1 Vector Area

The Cortex-R5 vectors start at address zero. The demonstration system startup `reset.S` file contains the vectors and is loaded at address zero. On actual hardware platforms, this area might have to be copied to address 0.

### 7.2 IRQ ISRs

ThreadX fully manages standard and vectored IRQ interrupts. ThreadX also supports nested IRQ interrupts. The following sub-sections define the IRQ capabilities.

#### 7.2.1 Standard IRQ ISRs

The standard ARM IRQ mechanism has a single interrupt vector at address `0x18`. This IRQ interrupt is managed by the `__tx_irq_handler` code in `tx_initialize_low_level`. The following is the default IRQ handler defined in `tx_initialize_low_level.S`:

```assembly
    .global __tx_irq_handler
    .global __tx_irq_processing_return
__tx_irq_handler:
@
@    /* Jump to context save to save system context.  */
    B       _tx_thread_context_save             @ Jump to the context save
__tx_irq_processing_return:
@
@    /* At this point execution is still in the IRQ mode. The CPSR, point of
@       interrupt, and all C scratch registers are available for use. Note
@       that IRQ interrupts are still disabled upon return from the context
@       save function.  */
@
@    /* Application ISR call(s) go here!  */
@
@    /* Jump to context restore to restore system context.  */
    B       _tx_thread_context_restore
```

#### 7.2.2 Vectored IRQ ISRs

The vectored ARM IRQ mechanism has multiple interrupt vectors at addresses specified by the particular implementation. The following is an example IRQ handler defined in `tx_initialize_low_level.S`:

```assembly
    .global __tx_irq_example_handler
__tx_irq_example_handler:
@
@    /* Call context save to save system context.  */

    STMDB   sp!, {r0-r3}                        @ Save some scratch registers
    MRS     r0, SPSR                            @ Pickup saved SPSR
    SUB     lr, lr, #4                          @ Adjust point of interrupt
    STMDB   sp!, {r0, r10, r12, lr}             @ Store other scratch registers
    BL      _tx_thread_vectored_context_save    @ Call the vectored IRQ context save
@
@    /* At this point execution is still in the IRQ mode. The CPSR, point of
@       interrupt, and all C scratch registers are available for use. Note
@       that IRQ interrupts are still disabled upon return from the context
@       save function.  */
@
@    /* Application ISR call goes here!  */
@
@    /* Jump to context restore to restore system context.  */
    B       _tx_thread_context_restore
```

#### 7.2.3 Nested IRQ Support

By default, nested IRQ interrupt support is not enabled. To enable nested IRQ support, the entire library should be built with `TX_ENABLE_IRQ_NESTING` defined. With this defined, two new IRQ interrupt management services are available, namely `_tx_thread_irq_nesting_start` and `_tx_thread_irq_nesting_end`. These function should be called between the IRQ context save and restore calls.

Execution between the calls to `_tx_thread_irq_nesting_start` and `_tx_thread_irq_nesting_end` is enabled for IRQ nesting. This is achieved by switching from IRQ mode to SYS mode and enabling IRQ interrupts. The SYS mode stack is used during the SYS mode operation, which was setup in `tx_initialize_low_level.S`. When nested IRQ interrupts are no longer required, calling the `_tx_thread_irq_nesting_end` service disables nesting by disabling IRQ interrupts and switching back to IRQ mode in preparation for the IRQ context restore service.

The following is an example of enabling IRQ nested interrupts in a standard IRQ handler:

```assembly
    .global __tx_irq_handler
    .global __tx_irq_processing_return
__tx_irq_handler:
@
@    /* Jump to context save to save system context.  */
    B       _tx_thread_context_save
__tx_irq_processing_return:
@
@    /* Enable nested IRQ interrupts. NOTE:  Since this service returns
@       with IRQ interrupts enabled, all IRQ interrupt sources must be
@       cleared prior to calling this service.  */
    BL      _tx_thread_irq_nesting_start
@
@    /* Application ISR call(s) go here!  */
@
@    /* Disable nested IRQ interrupts. The mode is switched back to
@       IRQ mode and IRQ interrupts are disable upon return.  */
    BL      _tx_thread_irq_nesting_end
@
@    /* Jump to context restore to restore system context.  */
    B       _tx_thread_context_restore
```

### 7.3 FIQ Interrupts

By default, FIQ interrupts are left alone by ThreadX. Of course, this means that the application is fully responsible for enabling the FIQ interrupt and saving/restoring any registers used in the FIQ ISR processing. To globally enable FIQ interrupts, the application should enable FIQ interrupts at the beginning of each thread or before any threads are created in `tx_application_define`. In addition, the application must ensure that no ThreadX service calls are made from default FIQ ISRs, which is located in `tx_initialize_low_level.S`.

#### 7.3.1 Managed FIQ Interrupts

Full ThreadX management of FIQ interrupts is provided if the ThreadX sources are built with the `TX_ENABLE_FIQ_SUPPORT` defined. If the library is built this way, the FIQ interrupt handlers are very similar to the IRQ interrupt handlers defined previously. The following is default FIQ handler defined in `tx_initialize_low_level.S`:

```assembly
    .global __tx_fiq_handler
    .global __tx_fiq_processing_return
__tx_fiq_handler:
@
@    /* Jump to fiq context save to save system context.  */
    B       _tx_thread_fiq_context_save
__tx_fiq_processing_return:
@
@    /* At this point execution is still in the FIQ mode. The CPSR, point of
@       interrupt, and all C scratch registers are available for use.  */
@
@    /* Application FIQ handlers can be called here!  */
@
@    /* Jump to fiq context restore to restore system context.  */
    B       _tx_thread_fiq_context_restore
```

##### 7.3.1.1 Nested FIQ Support

By default, nested FIQ interrupt support is not enabled. To enable nested FIQ support, the entire library should be built with `TX_ENABLE_FIQ_NESTING` defined. With this defined, two new FIQ interrupt management services are available, namely `_tx_thread_fiq_nesting_start` and `_tx_thread_fiq_nesting_end`. These function should be called between the FIQ context save and restore calls.

Execution between the calls to `_tx_thread_fiq_nesting_start` and `_tx_thread_fiq_nesting_end` is enabled for FIQ nesting. This is achieved by switching from FIQ mode to SYS mode and enabling FIQ interrupts. The SYS mode stack is used during the SYS mode operation, which was setup in `tx_initialize_low_level.S`. When nested FIQ interrupts are no longer required, calling the `_tx_thread_fiq_nesting_end` service disables nesting by disabling FIQ interrupts and switching back to FIQ mode in preparation for the FIQ context restore service.

The following is an example of enabling FIQ nested interrupts in the typical FIQ handler:

```assembly
    .global __tx_fiq_handler
    .global __tx_fiq_processing_return
__tx_fiq_handler:
@
@    /* Jump to fiq context save to save system context.  */
    B       _tx_thread_fiq_context_save
__tx_fiq_processing_return:
@
@    /* At this point execution is still in the FIQ mode. The CPSR, point of
@       interrupt, and all C scratch registers are available for use.  */
@
@    /* Enable nested FIQ interrupts. NOTE:  Since this service returns
@       with FIQ interrupts enabled, all FIQ interrupt sources must be
@       cleared prior to calling this service.  */
    BL      _tx_thread_fiq_nesting_start
@
@    /* Application FIQ handlers can be called here!  */
@
@    /* Disable nested FIQ interrupts. The mode is switched back to
@       FIQ mode and FIQ interrupts are disable upon return.  */
    BL      _tx_thread_fiq_nesting_end
@
@    /* Jump to fiq context restore to restore system context.  */
    B       _tx_thread_fiq_context_restore
```

## 8. Stack Placement and Memory Configuration

The Cortex-R5 processor provides Tightly-Coupled Memory (TCM) and external memory (typically DDR) with different performance characteristics. Proper stack placement is critical for deterministic interrupt response and efficient memory utilization.

### 8.1 Recommended Stack Placement Policy

**SYSTEM/ISR STACKS (in ATCM - fast, deterministic):**
- IRQ stack (default: 1024 bytes)
- FIQ stack (default: 512 bytes)
- SYS stack (default: 1024 bytes, when `TX_ENABLE_IRQ_NESTING` is defined)
- Total system stack requirement: ~2560 bytes with nesting enabled, ~1536 bytes without nesting

**THREAD STACKS (in DDR - abundant, economical):**
- Application thread stacks (size varies per thread)
- Timer thread stack (default: 1024 bytes, unless `TX_TIMER_PROCESS_IN_ISR`)
- Minimum per thread: `TX_MINIMUM_STACK` (200 bytes)

### 8.2 Rationale

**TCM Characteristics** (ARM Cortex-R5 TRM, Section 4.3):
- ATCM/BTCM: Typically 32-64KB total, 1-cycle access latency
- Zero-wait-state access, deterministic timing
- Ideal for interrupt handlers requiring predictable response
- Limited capacity - must be used judiciously

**DDR Characteristics:**
- Large capacity (hundreds of MB to GB)
- Higher latency (10-100+ cycles depending on cache/prefetch)
- Suitable for application data with relaxed timing requirements
- Cost-effective for bulk storage

**Placing system/ISR stacks in ATCM ensures:**
- Deterministic interrupt latency (critical for real-time systems)
- Fast context save/restore operations
- Predictable performance under worst-case conditions

**Placing thread stacks in DDR provides:**
- Abundant space for application threads
- No artificial limits on thread count or stack sizes
- Efficient use of scarce TCM resources

### 8.3 Linker Script Configuration

The default linker script (`sample_threadx.ld`) does not specify memory regions. For production systems with TCM, create a custom linker script with explicit memory regions.

**Template Available:** A complete linker script template with TCM/DDR configuration is provided at `example_build/sample_threadx_tcm.ld`. This template includes:
- MEMORY regions for ATCM, BTCM, and DDR
- Properly aligned stack sections for IRQ, FIQ, and SYS modes
- Extensive comments explaining placement decisions
- Configuration examples for common SoC families (TI TMS570, Xilinx Zynq, NXP i.MX)

Example memory layout (from `sample_threadx_tcm.ld`):

```ld
MEMORY
{
    ATCM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
    BTCM (rwx) : ORIGIN = 0x00080000, LENGTH = 64K
    DDR  (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    /* System stacks in ATCM for deterministic access */
    .stack_irq (NOLOAD) : ALIGN(8)
    {
        _stack_irq_start = .;
        . += IRQ_STACK_SIZE;
        _stack_irq_end = .;
    } > ATCM

    .stack_fiq (NOLOAD) : ALIGN(8)
    {
        _stack_fiq_start = .;
        . += FIQ_STACK_SIZE;
        _stack_fiq_end = .;
    } > ATCM

    .stack_sys (NOLOAD) : ALIGN(8)
    {
        _stack_sys_start = .;
        . += SYS_STACK_SIZE;
        _stack_sys_end = .;
    } > ATCM

    /* Application data and thread stacks in DDR */
    .data : { *(.data*) } > DDR
    .bss  : { *(.bss*)  } > DDR
}
```

**Notes:**
- Adjust `ORIGIN` and `LENGTH` values for your specific SoC
- Common Cortex-R5 configurations:
  - TI TMS570: ATCM at 0x00000000, BTCM at 0x08000000
  - Xilinx Zynq MPSoC: ATCM at 0x00000000, BTCM at 0x00020000
- Stack sections use `(NOLOAD)` to avoid initialization overhead
- `ALIGN(8)` ensures ARM EABI 8-byte stack alignment requirement

### 8.4 Context Switch and Memory Regions

The ThreadX context switch implementation is memory-region transparent:
- Uses standard ARM load/store instructions (`LDR`/`STR`, `LDMIA`/`STMIA`)
- No special handling required for TCM vs DDR access
- ARM architecture guarantees coherency between TCM and DDR
- Performance difference is in access latency, not correctness

**Functions that access stacks during context switch:**
- `_tx_thread_context_save`: Saves registers to current thread stack
- `_tx_thread_context_restore`: Restores registers from thread stack
- `_tx_thread_schedule`: Switches between thread stacks
- `_tx_thread_stack_build`: Initializes new thread stack frame

All of these work correctly regardless of whether the stack is in TCM or DDR.

### 8.5 MPU Configuration for Mixed TCM/DDR Access

The Cortex-R5 Memory Protection Unit (MPU) must be configured to allow access to both TCM and DDR regions. The current ThreadX port uses a static (system-wide) MPU configuration, not per-thread MPU regions.

**Recommended MPU configuration:**

**Region 0: ATCM (System Stacks)**
- Base: 0x00000000, Size: 64KB
- Attributes: RW, Non-cacheable, Non-shareable
- Access: Full (Privileged: RW, User: RW)

**Region 1: BTCM (Data)**
- Base: 0x00080000, Size: 64KB
- Attributes: RW, Non-cacheable, Non-shareable
- Access: Full (Privileged: RW, User: RW)

**Region 2: DDR (Application Memory, Thread Stacks)**
- Base: 0x80000000, Size: 256MB
- Attributes: RW, Write-back cacheable, Non-shareable (or Shareable for SMP)
- Access: Full (Privileged: RW, User: RW)

**Notes:**
- TCM is inherently non-cacheable (direct access)
- DDR should be cacheable for performance (write-back policy)
- For SMP configurations, DDR must be marked Shareable
- Stack overflow detection requires guard regions (not shown above)

Example CP15 configuration code (to be added in `tx_initialize_low_level.S`):

```assembly
    @ Configure MPU Region 0 (ATCM)
    MOV     r0, #0                          @ Region 0
    MCR     p15, 0, r0, c6, c2, 0          @ Select region
    LDR     r0, =0x00000000 | 0x10         @ Base address + Enable
    MCR     p15, 0, r0, c6, c1, 0          @ Set base address
    MOV     r0, #0x0F << 1 | 1             @ 64KB size, region enable
    MCR     p15, 0, r0, c6, c1, 2          @ Set size and enable
```

Refer to the ARM Cortex-R5 TRM Section 4.4 (MPU) and ARMv7-R Architecture Manual Section B4 (Protected Memory System Architecture) for complete details.

### 8.6 Performance Considerations

**Interrupt Latency Impact:**
- With system stacks in ATCM: ~10-15 cycles for stack access during ISR entry
- With system stacks in DDR: ~30-100 cycles (depending on cache state)
- Difference: Up to 90 cycles (~1-2 microseconds at 100 MHz)

**Thread Stack Access:**
- Thread stacks see DDR latency during context switches
- Mitigated by ARM write buffer and cache for normal operation
- Context switch overhead: ~100-200 cycles regardless of stack location

**Recommendations:**
- For hard real-time systems (ASIL-B+, IEC 62304 Class C): Use TCM for all ISR stacks
- For soft real-time systems: TCM for ISR stacks, DDR for thread stacks (recommended)
- For non-real-time systems: All stacks in DDR acceptable

### 8.7 ECC Memory Handling

The Cortex-R5 supports Error Correcting Code (ECC) protection for TCM and external memory. ECC is critical for safety-critical systems (ISO 26262 ASIL-B+, IEC 62304 Class C) to detect and correct single-bit errors and detect multi-bit errors.

**ARM Reference**: Cortex-R5 TRM, Section 4.4.4 (ECC implementation)

#### 8.7.1 ECC Overview

**ECC Protection Capabilities:**
- **Single-bit error correction (SEC)**: Automatically corrected in hardware
- **Double-bit error detection (DED)**: Detected but not correctable
- **Protected regions**: ATCM, BTCM, Cache (optional), External memory interface (if enabled)

**ECC Fault Types:**
- **Correctable error**: Single-bit error, corrected transparently, optional interrupt
- **Uncorrectable error**: Multi-bit error, generates abort exception

**ACTLR (Auxiliary Control Register) ECC Control Bits:**

**CRITICAL**: ACTLR bits are **IMPLEMENTATION DEFINED** in ARMv7-R architecture. The following bit assignments are **examples** and must be verified against your specific SoC Technical Reference Manual:

- **Bit 25**: ATCM ECC check enable (example - verify for your SoC)
- **Bit 26**: BTCM ECC check enable (example - verify for your SoC)
- **Bit 27**: BTCM ECC error reporting enable (example - verify for your SoC)
- **Bit 28**: ATCM ECC error reporting enable (example - verify for your SoC)

**Vendor-Specific ACTLR Mappings** (always verify with latest TRM):
- **TI TMS570**: Check TMS570 TRM Chapter 2 (ARM Cortex-R5F Core)
- **Xilinx Zynq UltraScale+ MPSoC**: Check Zynq UltraScale+ TRM UG1085, R5F subsystem
- **NXP i.MX**: Check i.MX series TRM for Cortex-R5 ACTLR register map

**Note**: Both "check enable" and "error reporting enable" bits must be set to generate Data Abort exceptions on uncorrectable errors. Incorrect bit usage will silently disable ECC protection.

**CRITICAL SAFETY WARNINGS:**

1. **ACTLR bits are implementation-defined**: The ECC control bits in ACTLR vary by SoC vendor and revision. **You must verify bit assignments** against your specific SoC Technical Reference Manual before deployment. Incorrect bit usage will silently disable ECC protection.

2. **Never call ThreadX APIs from exception handlers**: Functions like `tx_thread_terminate()`, `tx_thread_suspend()`, or `tx_queue_send()` are NOT ISR-safe when called from Data Abort handlers. They will corrupt kernel state. **For ASIL-B+ and Class C systems, use immediate reset** on uncorrectable ECC errors.

3. **Memory scrubbing requires atomicity**: Read-modify-write operations in scrubbing threads must disable interrupts or use exclusive access instructions (`LDREX`/`STREX`) to prevent data corruption from concurrent thread access. Note that interrupt disable does **not** protect against DMA access to TCM.

4. **BTCM initialization is mandatory**: If BTCM ECC is enabled but BTCM is not initialized, any access triggers uncorrectable errors causing boot loops. **Always initialize both ATCM and BTCM** before enabling ECC.

5. **Use proper DFSR fault status encoding**: Data Fault Address Register (`DFAR`) is only valid for precise (synchronous) aborts. Use DFSR FS[5:0] status field to distinguish precise from imprecise aborts, **not DFSR bit 10** which has different meaning in ARMv7-R.

6. **Verify barrier scope**: Use `DSB SY` (full system) barriers before CP15 ACTLR writes in safety-critical systems. Default `DSB` may not provide sufficient ordering guarantees across all bus masters.

#### 8.7.2 Boot-Time ECC Initialization

**Critical Requirement**: All ECC-protected memory MUST be initialized (written) before first read to establish valid ECC codes. Reading uninitialized ECC memory causes uncorrectable ECC faults.

**Initialization Sequence** (in `tx_initialize_low_level.S` or boot code):

```assembly
@
@ ECC Initialization for ATCM and BTCM
@
@ This must occur BEFORE any stack operations or ECC enable
@
@ WARNING: ACTLR bit assignments are IMPLEMENTATION DEFINED
@ The bit numbers below are EXAMPLES and must be verified against
@ your specific SoC Technical Reference Manual. Using incorrect
@ bit assignments will silently disable ECC protection.
@

    @ Disable ECC temporarily (if not already disabled)
    MRC     p15, 0, r0, c1, c0, 1          @ Read ACTLR
    BIC     r0, r0, #(1 << 25)             @ Clear ATCM ECC check (verify bit number!)
    BIC     r0, r0, #(1 << 26)             @ Clear BTCM ECC check (verify bit number!)
    BIC     r0, r0, #(1 << 27)             @ Clear BTCM error enable (verify bit number!)
    BIC     r0, r0, #(1 << 28)             @ Clear ATCM error enable (verify bit number!)
    DSB     SY                              @ Full system barrier (ensure all prior ops complete)
    MCR     p15, 0, r0, c1, c0, 1          @ Write ACTLR
    ISB                                     @ Flush instruction pipeline

    @ Initialize ATCM (64KB example, adjust for your configuration)
    LDR     r0, =0x00000000                @ ATCM base address
    LDR     r1, =0x00010000                @ ATCM size (64KB)
    ADD     r1, r0, r1                     @ Calculate end address
    MOV     r2, #0                         @ Write value (zeros)
    MOV     r3, #0                         @ For STRD (64-bit store)

atcm_ecc_init_loop:
    STRD    r2, r3, [r0], #8               @ Write 64-bit, increment pointer
    CMP     r0, r1                         @ Check if done
    BLT     atcm_ecc_init_loop             @ Continue until end

    @ Initialize BTCM (CRITICAL: Must not skip this step)
    LDR     r0, =0x00080000                @ BTCM base address (adjust for SoC)
    LDR     r1, =0x00010000                @ BTCM size (64KB)
    ADD     r1, r0, r1                     @ Calculate end address
    MOV     r2, #0
    MOV     r3, #0

btcm_ecc_init_loop:
    STRD    r2, r3, [r0], #8               @ Write 64-bit, increment pointer
    CMP     r0, r1                         @ Check if done
    BLT     btcm_ecc_init_loop             @ Continue until end

    @ Enable ECC with error reporting
    DSB                                     @ Ensure all memory writes complete
    MRC     p15, 0, r0, c1, c0, 1          @ Read ACTLR
    ORR     r0, r0, #(1 << 25)             @ Enable ATCM ECC check
    ORR     r0, r0, #(1 << 26)             @ Enable BTCM ECC check
    ORR     r0, r0, #(1 << 27)             @ Enable BTCM error reporting
    ORR     r0, r0, #(1 << 28)             @ Enable ATCM error reporting
    MCR     p15, 0, r0, c1, c0, 1          @ Write ACTLR
    ISB                                     @ Flush pipeline

    @ Initialize DDR ECC (if enabled at memory controller level)
    @ This is typically done by boot firmware or startup code
    @ Consult your SoC memory controller documentation
```

**Optimization Note**: For large memory regions, use efficient write patterns:
- Use `STMIA` (store multiple) for faster initialization
- Enable write buffers if supported
- Consider using DMA for DDR initialization (vendor-specific)

#### 8.7.3 Memory Placement Requirements

**ECC-Protected Regions** (must be in ECC-enabled memory):

1. **System/ISR Stacks** (ATCM with ECC)
   - IRQ stack: Critical for interrupt handling integrity
   - FIQ stack: Fast interrupt path requires protection
   - SYS stack: Nested interrupt context

2. **Thread Control Blocks (TCBs)**
   - Store in ECC-protected DDR or BTCM
   - Corruption of TCB state can cause system-wide failure
   - Consider placing critical TCBs in BTCM for maximum protection

3. **Critical Data Structures**
   - Scheduler state (`_tx_thread_execute_ptr`, `_tx_thread_current_ptr`)
   - Timer state (`_tx_timer_time_slice`)
   - System counters and flags

**Non-ECC Regions** (acceptable for non-critical data):
- Temporary buffers
- Non-critical application data
- Cached data with software validation

#### 8.7.4 Runtime ECC Fault Handling

**ECC Fault Scenarios and Responses:**

##### Scenario 1: Correctable Error (Single-Bit)

**Detection**: Optional interrupt (configure via ACTLR register)

**Recommended Actions:**
1. Log error location and count
2. If error count exceeds threshold → trigger maintenance alert
3. Continue operation (hardware corrects automatically)

**Example Handler**:
```c
void ecc_correctable_error_handler(void)
{
    uint32_t fault_addr;

    /* Read ECC fault address register (vendor-specific) */
    /* Example: fault_addr = read_ecc_status_register(); */

    /* Log for trending analysis */
    log_ecc_correctable_error(fault_addr);

    /* Check threshold (e.g., >10 errors in same location) */
    if (ecc_error_count[fault_addr] > ECC_THRESHOLD) {
        trigger_maintenance_alert();
    }

    /* Clear interrupt and continue */
    clear_ecc_interrupt();
}
```

##### Scenario 2: Uncorrectable Error (Multi-Bit)

**Detection**: Data abort exception

**Recommended Actions** (choose based on safety requirements):

**Option A: Panic/Reset (ASIL-D, Class C)**
```c
void data_abort_handler(void)
{
    /* Read fault status registers */
    uint32_t dfsr = read_dfsr();
    uint32_t dfar = read_dfar();

    /* Check if ECC fault (decode DFSR) */
    if (is_ecc_uncorrectable_error(dfsr)) {
        /* Log fault information to non-volatile storage */
        log_fatal_error(ECC_UNCORRECTABLE, dfar);

        /* Safety response: Reset processor */
        system_reset();
    }
}
```

**Option B: Immediate Reset (ASIL-B+, Class C - Recommended)**
```c
void data_abort_handler(void)
{
    uint32_t dfsr = read_dfsr();
    uint32_t dfar = read_dfar();

    if (is_ecc_uncorrectable_error(dfsr)) {
        /* Check if abort is precise using DFSR status field (FS[5:0])
         * ARMv7-R DFSR encoding: FS[5:0] = {DFSR[10], DFSR[3:0]}
         * Precise faults: 0x01 (alignment), 0x05 (translation), etc.
         * Imprecise fault: 0x16 (asynchronous external abort) */
        uint32_t fs = ((dfsr >> 6) & 0x10) | (dfsr & 0x0F);  /* Extract FS[5:0] */

        if (fs == 0x16) {
            /* Imprecise (asynchronous) abort - DFAR invalid */
            log_fatal_error(ECC_UNCORRECTABLE_IMPRECISE, dfsr);
            system_reset();
        } else {
            /* Precise abort - DFAR valid, can log fault address */
            log_fatal_error(ECC_UNCORRECTABLE_PRECISE, dfar);
            system_reset();
        }
    }
}

```

**Note**: For ASIL-B+ and Class C systems, immediate reset is the recommended and safest approach. Attempting to continue operation after uncorrectable ECC errors introduces significant complexity and risk of further corruption.

**Option C: Retry with Backup (Redundant Systems)**
```c
void data_abort_handler(void)
{
    /* Switch to redundant processor/memory */
    /* This requires dual-processor lockstep or redundant memory */
    /* Implementation is highly system-specific */
}
```

#### 8.7.5 Safety Certification Requirements

**ISO 26262 (Automotive Functional Safety):**

| ASIL Level | ECC Requirement | Fault Handling |
|------------|-----------------|----------------|
| ASIL-A | Recommended | Log correctable errors |
| ASIL-B | **Required** | Log + threshold monitoring |
| ASIL-C | **Required** | Terminate faulting thread or reset |
| ASIL-D | **Required** | Immediate reset on uncorrectable error |

**IEC 62304 (Medical Device Software):**

| Safety Class | ECC Requirement | Fault Handling |
|--------------|-----------------|----------------|
| Class A | Optional | Basic logging |
| Class B | Recommended | Error counting + alerts |
| Class C | **Required** | Immediate safe state transition |

**Documentation Requirements for Certification:**
1. ECC initialization procedures and verification
2. Fault injection testing results (single-bit, double-bit)
3. Fault detection coverage analysis
4. Mean Time To Failure (MTTF) calculations
5. Fault handling response time measurements
6. Memory scrubbing strategies (if applicable)

#### 8.7.6 ECC Configuration Checklist

**Pre-Boot:**
- [ ] Verify SoC ECC capabilities (ATCM, BTCM, external memory)
- [ ] Configure memory controller ECC enable (DDR)
- [ ] Determine ECC-protected memory regions

**Boot Sequence:**
1. [ ] Disable ECC (if not already disabled)
2. [ ] Initialize all ECC-protected memory (write zeros or pattern)
3. [ ] Verify initialization (read back and check)
4. [ ] Enable ECC via ACTLR register
5. [ ] Configure ECC error interrupts (if using correctable error logging)
6. [ ] Set up exception handlers for uncorrectable errors

**Runtime:**
- [ ] Install data abort handler for uncorrectable ECC errors
- [ ] Install ECC error interrupt handler (correctable errors)
- [ ] Implement error logging and threshold monitoring
- [ ] Define safe state transition for critical faults
- [ ] Test fault injection (single-bit, double-bit)

**ThreadX Integration:**
- [ ] Ensure system stacks in ECC-protected ATCM
- [ ] Place TCBs in ECC-protected memory (BTCM or DDR)
- [ ] Initialize ThreadX heap in ECC-protected DDR
- [ ] Document non-ECC regions (if any) and risks

#### 8.7.7 Memory Scrubbing (Optional but Recommended)

For systems requiring high reliability, implement periodic memory scrubbing to detect and correct accumulated single-bit errors before they become uncorrectable.

**Scrubbing Strategy:**
```c
/* Background scrubbing task (low priority) - covers ATCM and BTCM */
void tx_ecc_scrubbing_thread(ULONG unused)
{
    typedef struct {
        uint32_t base;
        uint32_t size;
    } mem_region_t;

    mem_region_t regions[] = {
        {ATCM_BASE, ATCM_SIZE},
        {BTCM_BASE, BTCM_SIZE}
    };
    uint32_t region_idx = 0;
    uint32_t *scrub_ptr = (uint32_t *)regions[0].base;
    uint32_t scrub_end = regions[0].base + regions[0].size;

    while (1) {
        /* CRITICAL: Disable interrupts to ensure atomicity
         * Read-modify-write must be atomic to prevent data corruption
         * from concurrent access by ISRs or other threads
         * Note: This does NOT protect against DMA access */
        UINT old_posture = tx_interrupt_control(TX_INT_DISABLE);

        /* Read word (triggers ECC check and correction) */
        volatile uint32_t data = *scrub_ptr;

        /* Write back (updates ECC code with corrected data) */
        *scrub_ptr = data;

        /* Restore interrupts (keep critical section short - 1 word only) */
        tx_interrupt_control(old_posture);

        /* Advance pointer */
        scrub_ptr++;

        /* Check if reached end of current region */
        if ((uint32_t)scrub_ptr >= scrub_end) {
            /* Move to next region */
            region_idx++;
            if (region_idx >= (sizeof(regions) / sizeof(regions[0]))) {
                /* Completed all regions, wrap to first */
                region_idx = 0;
                /* Sleep after completing full cycle */
                tx_thread_sleep(100);
            }

            /* Start next region */
            scrub_ptr = (uint32_t *)regions[region_idx].base;
            scrub_end = regions[region_idx].base + regions[region_idx].size;
        }

        /* Yield occasionally to avoid starving other threads */
        if (((uint32_t)scrub_ptr % 1024) == 0) {
            tx_thread_relinquish();
        }
    }
}
```

**Scrubbing Frequency Guidelines:**
- **Mission-critical**: Continuous scrubbing with minimal sleep
- **High-reliability**: Scrub entire memory every 1-10 seconds
- **Standard**: Scrub entire memory every 1-10 minutes
- **Low-power**: Scrub only during idle periods

#### 8.7.8 Testing and Validation

**ECC Fault Injection Testing:**

```assembly
@ Inject single-bit error (correctable)
@ WARNING: This is destructive and should only be used in test environments

inject_single_bit_error:
    @ Disable ECC temporarily
    MRC     p15, 0, r0, c1, c0, 1
    BIC     r0, r0, #(1 << 25)             @ Disable ATCM ECC check
    BIC     r0, r0, #(1 << 28)             @ Disable ATCM error reporting
    DSB                                     @ Ensure prior operations complete
    MCR     p15, 0, r0, c1, c0, 1
    ISB                                     @ Flush pipeline

    @ Write data with intentional bit flip
    LDR     r0, =test_memory_location
    LDR     r1, [r0]                       @ Read original value
    EOR     r1, r1, #(1 << 5)              @ Flip bit 5
    STR     r1, [r0]                       @ Write corrupted value
    DSB                                     @ Ensure write completes

    @ Re-enable ECC
    MRC     p15, 0, r0, c1, c0, 1
    ORR     r0, r0, #(1 << 25)             @ Enable ATCM ECC check
    ORR     r0, r0, #(1 << 28)             @ Enable ATCM error reporting
    DSB                                     @ Ensure prior operations complete
    MCR     p15, 0, r0, c1, c0, 1
    ISB                                     @ Flush pipeline

    @ Next read will trigger correctable error
    BX      lr
```

**Verification Steps:**
1. Confirm ECC initialization completes without faults
2. Inject single-bit error → verify correction and interrupt (if enabled)
3. Inject double-bit error → verify data abort exception
4. Measure fault detection latency
5. Verify fault handler response time
6. Test under high interrupt load

#### 8.7.9 Vendor-Specific Considerations

**TI TMS570 Series:**
- ECC enabled by default for Flash and RAM
- Use Flash/TCRAM ECC status registers for error information
- Consult TMS570 TRM Chapter 6 (Flash) and Chapter 7 (RAM)

**Xilinx Zynq UltraScale+ MPSoC:**
- R5F TCM ECC controlled via R5_TCMRAM_ECC_CTRL register
- DDR ECC requires DDRC configuration
- Consult Zynq UltraScale+ TRM Chapter 4 (APU and RPU)

**NXP i.MX Series:**
- ECC support varies by part number
- Check OCRAM and DDR controller specifications
- Consult i.MX TRM for ECC configuration registers

**Note**: Always consult your specific SoC technical reference manual for:
- ECC enable/disable procedures
- Fault status register locations
- Interrupt configuration
- Memory controller ECC settings

## 9. Lockstep Mode Support

The Cortex-R5 processor supports dual-core configuration in two modes: lockstep and asymmetric SMP. This section documents ThreadX support for lockstep mode.

**ARM Reference**: Cortex-R5 TRM, Chapter 11 (Dual-core configuration)

### 9.1 What is Lockstep Mode?

**Lockstep mode** operates both Cortex-R5 cores as a single logical processor for fault detection:
- Both cores execute identical instructions simultaneously
- Outputs are compared cycle-by-cycle for mismatches
- Any mismatch triggers an error signal (indicates hardware fault)
- Software sees a single-core system (no SMP programming required)
- Provides hardware fault detection for safety-critical systems (ISO 26262 ASIL-D, IEC 62304 Class C)

**CRITICAL: Lockstep Mode is Hardware-Configured at Reset**

Lockstep mode is a **hardware boot configuration** that is:
- Set via hardware straps (fuses, eFuses, or GPIO signals) sampled at processor reset
- **Active immediately upon reset** - no software enable required
- **Cannot be changed at runtime** by software (no runtime switch to/from SMP)
- Requires full hardware reset/power cycle to change mode

**What This Means:**
- If your board is strapped for lockstep, the processor IS in lockstep from reset onwards
- Software (ThreadX or application) cannot disable lockstep mode
- Switching between lockstep and SMP requires **hardware reconfiguration + reset** (see Section 9.9)
- Both cores execute identically from first instruction after reset

**ThreadX Certification Context:**
While ThreadX *supports* ASIL-D contexts through its deterministic design, the ThreadX OS itself is not ASIL-D certified unless using the commercially certified version. Lockstep mode facilitates the *hardware's* ability to reach ASIL-D certification.

**Lockstep vs SMP:**

| Feature | Lockstep Mode | SMP Mode |
|---------|---------------|----------|
| Cores | 2 cores, 1 logical CPU | 2 independent CPUs |
| Execution | Identical instructions | Independent tasks |
| Software view | Single-core | Multi-core |
| Purpose | Fault detection | Performance |
| ThreadX variant | Standard ThreadX | ThreadX SMP |

### 9.2 Current Support Status

**ThreadX Cortex-R5 GNU port is COMPATIBLE with lockstep mode.**

**Rationale:**
- Lockstep presents as a single-core system to software
- No SMP-specific programming required
- All operations are naturally deterministic in single-threaded execution
- Recent interrupt barrier fixes (commit c4602872, 162e286c) ensure deterministic behavior

**Verified Components:**
1. **Interrupt Control** (tx_port.h:290-296):
   - TX_DISABLE/TX_RESTORE use DMB + ISB barriers
   - Ensures identical CPSR state and memory ordering on both cores
   - No instruction reordering across critical sections

2. **Context Switching** (tx_thread_schedule.S, tx_thread_context_save.S):
   - Deterministic register save/restore sequences
   - No data-dependent branches in critical paths
   - Identical execution guaranteed for same inputs

3. **Stack Management** (tx_initialize_low_level.S:126-166):
   - Deterministic stack pointer initialization
   - No dynamic stack allocation in interrupt paths
   - Fixed stack sizes ensure identical layout

### 9.3 Lockstep-Specific Restrictions

**CRITICAL: Debug/Trace Limitations**

Lockstep mode imposes strict requirements on debug and trace features. Violating these restrictions may cause lockstep errors or system failures.

**Prohibited in Lockstep Mode:**
1. **Asymmetric Breakpoints**: Setting breakpoints on only one core breaks synchronization
2. **Single-Stepping**: Stepping through code on one core while other runs
3. **Performance Counters**: Core-specific counter access may differ between cores
4. **Trace Macrocells**: ETM/PTM trace may introduce timing variations

**Critical: Watchdog Timer Considerations**
- Hardware watchdog timers are the ultimate safety net in lockstep systems
- If lockstep comparator freezes the bus or both cores halt, watchdog triggers reset
- Ensure watchdog is properly configured and serviced in all execution paths
- Watchdog timeout should account for worst-case interrupt latency + critical section duration

**Allowed in Lockstep Mode:**
1. **Invasive Debug**: Both cores halt simultaneously (lockstep preserved)
2. **Non-Invasive Trace**: Trace output multiplexed from one core only
3. **DCC (Debug Comms Channel)**: Software-based debug I/O (vendor-specific)

**Recommendation**: Use software-based debugging techniques (UART logging, memory dumps) instead of JTAG/SWD during lockstep operation. Reserve JTAG debugging for non-lockstep development.

### 9.4 Determinism Requirements

For reliable lockstep operation, all code paths must be deterministic. ThreadX port already satisfies these requirements:

**Guaranteed Deterministic:**
- **Interrupt Latency**: Fixed instruction sequences in interrupt entry/exit
- **Memory Barriers**: Explicit DMB/ISB prevent compiler/CPU reordering
- **Register Context**: Fixed save/restore order (AAPCS compliant)
- **Timer ISR**: Deterministic tick processing (no conditional branches based on external state)

**Application Responsibilities:**
- **Avoid Timing-Dependent Logic**: Don't use wall-clock time for control flow decisions within critical sections
- **No External Randomness**: Don't read hardware RNG or jitter-prone sources in interrupt handlers
- **Consistent Cache Policy**: Both cores must have identical cache enable/disable configuration
- **Identical MPU Configuration**: Both cores must program identical MPU regions

### 9.5 Cache Considerations

**TCM in Lockstep Mode:**
- ATCM/BTCM are local to each core (duplicated, not shared)
- Both cores access their own TCM with identical addresses
- Contents must remain identical (guaranteed by lockstep execution)
- No cache coherency issues (TCM is not cacheable)

**CRITICAL: TCM Initialization Requirement**

**Timing Constraint:** Lockstep mode is already active at reset (configured by hardware straps). TCM must be scrubbed BEFORE any stack operations or TCM reads.

**The Paradox:** Section 8.1 recommends system stacks in ATCM, but lockstep requires ATCM scrubbing before first use. Solution requires early boot sequence with non-TCM resources.

**Boot Sequence Options:**

**Option A: ROM/OCRAM Stack (Recommended for production)**
```assembly
@ Early boot - before any C code or stack usage in ATCM
@ This code must execute from ROM/Flash with stack in OCRAM or other non-TCM RAM

_start:
    @ 1. Set up temporary stack in OCRAM (not ATCM)
    LDR     sp, =__ocram_stack_top          @ Vendor-specific OCRAM address

    @ 2. Scrub ATCM (write zeros to establish identical state)
    BL      scrub_atcm                       @ See implementation below

    @ 3. Scrub BTCM (if used)
    BL      scrub_btcm

    @ 4. Now safe to initialize system stacks in ATCM
    BL      _tx_initialize_low_level         @ Sets up IRQ/FIQ/SYS stacks in ATCM

    @ 5. Continue with normal boot (ECC enable, ThreadX init, etc.)
    B       main

scrub_atcm:
    @ Scrub ATCM with no stack usage (leaf function, no function calls)
    LDR     r0, =ATCM_BASE                   @ e.g., 0x00000000
    LDR     r1, =ATCM_SIZE                   @ e.g., 64KB (0x10000)
    ADD     r1, r0, r1                       @ End address
    MOV     r2, #0
    MOV     r3, #0
scrub_loop:
    STRD    r2, r3, [r0], #8                 @ Write 64-bit zeros
    CMP     r0, r1
    BLT     scrub_loop
    BX      lr
```

**Option B: DDR Stack (if available early)**
```assembly
@ If DDR is initialized by bootloader/ROM code
_start:
    @ 1. Use DDR stack temporarily
    LDR     sp, =__ddr_temp_stack            @ DDR address from linker script

    @ 2. Scrub TCM (same as Option A)
    BL      scrub_atcm
    BL      scrub_btcm

    @ 3. Switch to ATCM stacks
    BL      _tx_initialize_low_level
    B       main
```

**Option C: No-Stack Scrubbing (if ROM stack unavailable)**
```assembly
@ Ultra-minimal: scrub without any stack
@ WARNING: No function calls allowed, inline only
_start:
    @ Inline ATCM scrub (no BL, no stack)
    LDR     r0, =ATCM_BASE
    LDR     r1, =ATCM_SIZE
    ADD     r1, r0, r1
    MOV     r2, #0
    MOV     r3, #0
inline_scrub:
    STRD    r2, r3, [r0], #8
    CMP     r0, r1
    BLT     inline_scrub

    @ Now safe to set up stack
    LDR     sp, =__stack_top                 @ Can use ATCM now
    BL      _tx_initialize_low_level
    B       main
```

**Relationship to ECC Initialization:**
- TCM scrubbing for lockstep and ECC initialization (Section 8.7.2) are **THE SAME OPERATION**
- Writing zeros to all TCM satisfies both requirements simultaneously
- Perform scrubbing once before any TCM access, then enable ECC if desired
- Order: Scrub TCM → Enable ECC → Use TCM normally

**Vendor-Specific Considerations:**
- Check if your bootloader/ROM already scrubs TCM (some do for ECC)
- Verify OCRAM availability and address from SoC memory map
- Some SoCs have small SRAM suitable for early stack (e.g., TI TMS570 has dedicated RAM)
- Xilinx Zynq MPSoC: OCM available at 0xFFFC0000 (256KB)

**L1 Cache in Lockstep Mode:**
- Each core has its own L1 cache (instruction and data)
- Cache contents should remain identical (same execution, same data access)
- Cache maintenance operations (clean, invalidate) execute on both cores
- No explicit synchronization required (lockstep ensures identical state)

**Note**: Cache coherency issues do NOT apply to lockstep mode. Those issues only affect dual-core R5F running in SMP mode with independent execution.

### 9.6 Interrupt Timing Determinism

Lockstep mode requires identical interrupt timing on both cores. The Cortex-R5 hardware ensures this automatically:

**Hardware Guarantees:**
- IRQ/FIQ signals are routed to the single logical CPU interface (lockstep comparator handles distribution)
- Interrupt controller (GIC) sees only ONE CPU interface in lockstep mode (not separate interfaces like SMP)
- Interrupt latency is identical (same pipeline state, same instruction)
- No GIC distributor configuration needed to "broadcast" interrupts (hardwired in lockstep)

**Software Requirements:**
- **No Core-Specific IRQ Routing**: Don't use GIC CPU interface targeting (vendor-specific)
- **Consistent Interrupt Priorities**: Ensure identical GIC priority configuration
- **No Timing-Dependent ISRs**: Avoid ISRs that branch based on elapsed time

### 9.7 Testing Requirements for Lockstep Validation

**Lockstep Error Detection Testing:**

To validate lockstep operation and error detection, perform the following tests (if supported by your SoC):

**1. Fault Injection Test (Hardware Lockstep Validation)**

This test validates the end-to-end lockstep error detection path: injection → status → ISR → logging → reset.

```c
/* Vendor-specific register definitions - MUST be filled from your SoC TRM */
#define LOCKSTEP_INJECT_ADDR  0x00000000  /* Replace with actual address */
#define LOCKSTEP_STATUS_ADDR  0x00000000  /* Replace with actual address */
#define LOCKSTEP_CLEAR_ADDR   0x00000000  /* Replace with actual address */

#define LOCKSTEP_INJECT_REG   (*(volatile uint32_t *)LOCKSTEP_INJECT_ADDR)
#define LOCKSTEP_STATUS_REG   (*(volatile uint32_t *)LOCKSTEP_STATUS_ADDR)
#define LOCKSTEP_CLEAR_REG    (*(volatile uint32_t *)LOCKSTEP_CLEAR_ADDR)

/* Vendor-specific error injection values */
#define LOCKSTEP_INJECT_MISMATCH  0x00000001  /* Consult TRM */

/* Global state for ISR verification */
static volatile uint32_t lockstep_fault_seen = 0;

/* Lockstep Error ISR - Must be registered to ESM/NMI/error interrupt */
void lockstep_error_isr(void)
{
    uint32_t status = LOCKSTEP_STATUS_REG;

    /* Log error information to non-volatile storage */
    log_fatal_error(LOCKSTEP_COMPARE_ERROR, status);

    /* Clear status register (vendor-specific) */
    LOCKSTEP_CLEAR_REG = status;

    /* Latch error for test verification */
    lockstep_fault_seen = status;

    /* Safety response: trigger system reset */
    system_reset();  /* Vendor-specific reset function */
}

/* Fault Injection Test Function */
int lockstep_fault_injection_test(void)
{
    lockstep_fault_seen = 0;

    /* Trigger intentional mismatch between cores */
    LOCKSTEP_INJECT_REG = LOCKSTEP_INJECT_MISMATCH;

    /* Wait for ISR to fire (should happen within microseconds) */
    tx_thread_sleep(1);  /* 1 tick delay */

    /* Verify the ISR fired and status was latched */
    if (lockstep_fault_seen != 0) {
        /* PASS: Lockstep detection is functional */
        return 0;
    } else {
        /* FAIL: Lockstep error was not detected */
        return -1;
    }
}

/* Vendor-Specific Examples:
 *
 * TI TMS570:
 *   - LOCKSTEP_INJECT_ADDR: ESM_EEPAPR1 register
 *   - LOCKSTEP_STATUS_ADDR: ESM_SR1 register
 *   - Inject via CPU self-test (LBIST) control registers
 *   - Refer to TMS570 TRM Chapter 8
 *
 * Xilinx Zynq UltraScale+:
 *   - LOCKSTEP_STATUS_ADDR: RPU_ERR_STATUS register
 *   - Inject via RPU error injection registers
 *   - Refer to Zynq UltraScale+ TRM Chapter 4
 *
 * NXP i.MX:
 *   - Consult i.MX TRM for Cortex-R5 error injection mechanism
 */
```

**Test Execution:**
1. Register `lockstep_error_isr` to your SoC's error interrupt vector
2. Call `lockstep_fault_injection_test()` during system validation
3. Expected: Test returns 0 (pass) and system resets after ISR
4. If test returns -1, lockstep error path is not functional

**2. Interrupt Stress Test (Determinism Validation)**

This test validates lockstep operation under heavy interrupt load and concurrent thread activity.

```c
#define STRESS_TEST_DURATION_TICKS  (3600U * TX_TIMER_TICKS_PER_SECOND)  /* 1 hour */
#define NUM_STRESS_THREADS          12
#define INTERRUPT_RATE_HZ           10000  /* 10 kHz timer interrupts */

/* Global stress test state */
static TX_THREAD stress_threads[NUM_STRESS_THREADS];
static ULONG stress_thread_stacks[NUM_STRESS_THREADS][1024];
static volatile ULONG stress_test_failures = 0;

/* Worker thread - generates CPU load and context switches */
void stress_worker_thread(ULONG thread_id)
{
    ULONG counter = 0;

    while (1) {
        /* Perform some computation */
        for (int i = 0; i < 1000; i++) {
            counter += (thread_id * i);
        }

        /* Force context switch */
        tx_thread_relinquish();

        /* Check for lockstep errors periodically */
        if ((counter % 10000) == 0) {
            if (LOCKSTEP_STATUS_REG != 0) {
                /* Lockstep fault detected */
                stress_test_failures++;
                log_fatal_error(LOCKSTEP_COMPARE_ERROR, LOCKSTEP_STATUS_REG);
                system_reset();
            }
        }
    }
}

/* Main stress test function */
int lockstep_interrupt_stress_test(void)
{
    UINT status;
    ULONG start_time, elapsed_time;

    /* Reset failure counter */
    stress_test_failures = 0;

    /* Create multiple worker threads with varying priorities */
    for (UINT i = 0; i < NUM_STRESS_THREADS; i++) {
        status = tx_thread_create(
            &stress_threads[i],
            "StressWorker",
            stress_worker_thread,
            i,  /* Thread ID */
            stress_thread_stacks[i],
            sizeof(stress_thread_stacks[i]),
            i + 5,  /* Priority: 5 to 16 */
            i + 5,
            TX_NO_TIME_SLICE,
            TX_AUTO_START
        );

        if (status != TX_SUCCESS) {
            return -1;  /* Thread creation failed */
        }
    }

    /* Configure timer for high interrupt rate (vendor-specific) */
    /* Example: configure_timer_interrupt(INTERRUPT_RATE_HZ); */

    /* Monitor test progress */
    start_time = tx_time_get();

    while (1) {
        elapsed_time = tx_time_get() - start_time;

        /* Check for lockstep errors in main monitoring loop */
        if (LOCKSTEP_STATUS_REG != 0) {
            log_fatal_error(LOCKSTEP_COMPARE_ERROR, LOCKSTEP_STATUS_REG);
            return -2;  /* Lockstep error detected */
        }

        /* Check if test duration completed */
        if (elapsed_time >= STRESS_TEST_DURATION_TICKS) {
            break;  /* Test passed */
        }

        /* Check for worker thread failures */
        if (stress_test_failures > 0) {
            return -3;  /* Worker detected error */
        }

        tx_thread_sleep(TX_TIMER_TICKS_PER_SECOND);  /* Check every second */
    }

    /* Cleanup: delete stress threads */
    for (UINT i = 0; i < NUM_STRESS_THREADS; i++) {
        tx_thread_terminate(&stress_threads[i]);
        tx_thread_delete(&stress_threads[i]);
    }

    /* Test passed - no lockstep errors under stress */
    return 0;
}

/* Expected Results:
 * - Return 0: No lockstep errors detected during entire test duration
 * - Return -1: Thread creation failure (test setup issue)
 * - Return -2/-3: Lockstep error detected (FAILURE - hardware issue)
 */
```

**3. Context Switch Validation (Register Preservation)**

This test validates deterministic context save/restore across 100K+ switches.

```c
#define CONTEXT_SWITCH_ITERATIONS  100000
#define TEST_PATTERN_1  0xA5A5A5A5
#define TEST_PATTERN_2  0x5A5A5A5A

/* Assembly helper functions to set/check register patterns */
/* These must be implemented in assembly to avoid compiler optimization */

extern void set_gpr_pattern(uint32_t pattern);
extern uint32_t check_gpr_pattern(uint32_t pattern);

/* Assembly implementation (add to .S file):
 *
 * .global set_gpr_pattern
 * set_gpr_pattern:
 *     MOV     r1, r0
 *     MOV     r2, r0
 *     MOV     r3, r0
 *     MOV     r4, r0
 *     MOV     r5, r0
 *     MOV     r6, r0
 *     MOV     r7, r0
 *     MOV     r8, r0
 *     MOV     r9, r0
 *     MOV     r10, r0
 *     MOV     r11, r0
 *     MOV     r12, r0
 *     BX      lr
 *
 * .global check_gpr_pattern
 * check_gpr_pattern:
 *     CMP     r1, r0
 *     BNE     check_fail
 *     CMP     r2, r0
 *     BNE     check_fail
 *     @ ... repeat for r3-r12 ...
 *     MOV     r0, #0          @ Success
 *     BX      lr
 * check_fail:
 *     MOV     r0, #1          @ Failure
 *     BX      lr
 */

/* Context switch test threads */
static TX_THREAD context_thread_a, context_thread_b;
static ULONG context_stack_a[1024], context_stack_b[1024];
static volatile ULONG context_switch_count = 0;
static volatile ULONG context_errors = 0;

void context_test_thread_a(ULONG unused)
{
    (void)unused;

    for (ULONG i = 0; i < CONTEXT_SWITCH_ITERATIONS; i++) {
        /* Set register pattern */
        set_gpr_pattern(TEST_PATTERN_1);

        /* Force context switch */
        tx_thread_relinquish();

        /* Verify pattern preserved after switch */
        if (check_gpr_pattern(TEST_PATTERN_1) != 0) {
            context_errors++;
        }

        context_switch_count++;
    }
}

void context_test_thread_b(ULONG unused)
{
    (void)unused;

    for (ULONG i = 0; i < CONTEXT_SWITCH_ITERATIONS; i++) {
        /* Set different pattern to detect cross-contamination */
        set_gpr_pattern(TEST_PATTERN_2);

        tx_thread_relinquish();

        if (check_gpr_pattern(TEST_PATTERN_2) != 0) {
            context_errors++;
        }

        context_switch_count++;
    }
}

/* Main context switch test */
int lockstep_context_switch_test(void)
{
    UINT status;

    context_switch_count = 0;
    context_errors = 0;

    /* Create two threads that will context switch rapidly */
    status = tx_thread_create(&context_thread_a, "ContextA",
                              context_test_thread_a, 0,
                              context_stack_a, sizeof(context_stack_a),
                              10, 10, TX_NO_TIME_SLICE, TX_AUTO_START);
    if (status != TX_SUCCESS) return -1;

    status = tx_thread_create(&context_thread_b, "ContextB",
                              context_test_thread_b, 0,
                              context_stack_b, sizeof(context_stack_b),
                              10, 10, TX_NO_TIME_SLICE, TX_AUTO_START);
    if (status != TX_SUCCESS) return -2;

    /* Wait for both threads to complete */
    while (context_switch_count < (2 * CONTEXT_SWITCH_ITERATIONS)) {
        tx_thread_sleep(10);

        /* Check for lockstep errors during test */
        if (LOCKSTEP_STATUS_REG != 0) {
            return -3;  /* Lockstep error during test */
        }
    }

    /* Cleanup */
    tx_thread_terminate(&context_thread_a);
    tx_thread_delete(&context_thread_a);
    tx_thread_terminate(&context_thread_b);
    tx_thread_delete(&context_thread_b);

    /* Check results */
    if (context_errors > 0) {
        return -4;  /* Register preservation errors */
    }

    return 0;  /* Test passed */
}

/* VFP Extension (if TX_ENABLE_VFP defined):
 * Add similar set_vfp_pattern/check_vfp_pattern functions for D0-D15 registers
 */
```

**4. Memory Barrier Validation (Compiler Reordering Prevention)**

This test validates that memory barriers prevent compiler reordering in optimized builds.

**Important:** In lockstep (single logical core), this tests **COMPILER** reordering prevention, not multi-core race conditions. Hardware program order is maintained. This is critical for -O3 optimization validation.

```c
/* Shared data for barrier test */
static volatile int barrier_shared_flag = 0;
static volatile int barrier_shared_data = 0;
static volatile ULONG barrier_errors = 0;

/* Producer thread - writes data then signals */
void barrier_producer_thread(ULONG unused)
{
    (void)unused;
    TX_INTERRUPT_SAVE_AREA;

    for (int i = 0; i < 10000; i++) {
        /* Critical section with barriers */
        TX_DISABLE;
        barrier_shared_data = 42 + i;    /* Must not reorder past TX_RESTORE */
        barrier_shared_flag = 1;
        TX_RESTORE;

        /* Wait for consumer to process */
        while (barrier_shared_flag == 1) {
            /* Spin */
        }

        tx_thread_sleep(1);  /* Yield periodically */
    }
}

/* Consumer thread - waits for signal then reads data */
void barrier_consumer_thread(ULONG unused)
{
    (void)unused;

    for (int i = 0; i < 10000; i++) {
        uint32_t start = tx_time_get();

        /* Wait for signal with timeout */
        while (barrier_shared_flag == 0) {
            if ((tx_time_get() - start) > 5) {
                /* Timeout - deadlock or barrier failure */
                barrier_errors++;
                return;
            }
        }

        /* Verify data is correct */
        if (barrier_shared_data != (42 + i)) {
            /* Memory ordering violation */
            barrier_errors++;
        }

        /* Clear flag to signal producer */
        barrier_shared_flag = 0;
    }
}

/* Main barrier test function */
int lockstep_barrier_test(void)
{
    TX_THREAD producer, consumer;
    ULONG producer_stack[1024], consumer_stack[1024];
    UINT status;

    barrier_errors = 0;
    barrier_shared_flag = 0;
    barrier_shared_data = 0;

    /* Create producer thread */
    status = tx_thread_create(&producer, "BarrierProducer",
                              barrier_producer_thread, 0,
                              producer_stack, sizeof(producer_stack),
                              15, 15, TX_NO_TIME_SLICE, TX_AUTO_START);
    if (status != TX_SUCCESS) return -1;

    /* Create consumer thread */
    status = tx_thread_create(&consumer, "BarrierConsumer",
                              barrier_consumer_thread, 0,
                              consumer_stack, sizeof(consumer_stack),
                              15, 15, TX_NO_TIME_SLICE, TX_AUTO_START);
    if (status != TX_SUCCESS) return -2;

    /* Wait for threads to complete (20 seconds max) */
    tx_thread_sleep(20 * TX_TIMER_TICKS_PER_SECOND);

    /* Cleanup */
    tx_thread_terminate(&producer);
    tx_thread_delete(&producer);
    tx_thread_terminate(&consumer);
    tx_thread_delete(&consumer);

    /* Check results */
    if (barrier_errors > 0) {
        return -3;  /* Barrier/ordering errors detected */
    }

    return 0;  /* Test passed */
}

/* Build Requirements:
 * - Compile with -O3 -flto to expose reordering bugs
 * - Without proper barriers, compiler may reorder shared_data/shared_flag writes
 * - Test validates TX_DISABLE/TX_RESTORE memory clobbers are effective
 */
```

**5. Vendor-Specific Lockstep Status Monitoring**

**Error Recovery Behavior:**
- Lockstep faults typically trigger hardware reset or NMI (Non-Maskable Interrupt)
- ThreadX **cannot recover** the current thread when a lockstep fault occurs
- System requires full reboot after lockstep error detection
- Error handler (if used) should log fault information to non-volatile storage before reset
- Some SoCs support error aggregation (combining lockstep, clock monitor, voltage monitor faults)

**TI TMS570 Series Implementation:**

```c
/* TMS570 Register Definitions */
#define ESM_BASE_ADDR         0xFFFFF500
#define ESM_SR1               (*(volatile uint32_t *)(ESM_BASE_ADDR + 0x04))
#define ESM_EEPAPR1           (*(volatile uint32_t *)(ESM_BASE_ADDR + 0x14))
#define ESM_IOFFHR            (*(volatile uint32_t *)(ESM_BASE_ADDR + 0x1C))

#define ESM_CPU_COMPARE_ERROR (1 << 0)  /* Bit 0 in ESM_SR1 */

/* TMS570 Lockstep Error Handler (register to ESM high-priority interrupt) */
void tms570_lockstep_error_handler(void)
{
    uint32_t error_status = ESM_SR1;

    if (error_status & ESM_CPU_COMPARE_ERROR) {
        /* Log to non-volatile memory (EEPROM/Flash) */
        log_fatal_error(LOCKSTEP_ERROR_TMS570, error_status);

        /* Clear error status */
        ESM_SR1 = ESM_CPU_COMPARE_ERROR;

        /* Trigger system reset via watchdog or reset controller */
        trigger_system_reset();
    }
}

/* TMS570 Periodic Status Check (called from monitoring thread) */
int tms570_check_lockstep_status(void)
{
    if (ESM_SR1 & ESM_CPU_COMPARE_ERROR) {
        return -1;  /* Lockstep error detected */
    }
    return 0;  /* No errors */
}
```

**Xilinx Zynq UltraScale+ MPSoC Implementation:**

```c
/* Zynq UltraScale+ Register Definitions */
#define RPU_BASE_ADDR        0xFF9A0000
#define RPU_ERR_STATUS       (*(volatile uint32_t *)(RPU_BASE_ADDR + 0x20))
#define RPU_ERR_EN           (*(volatile uint32_t *)(RPU_BASE_ADDR + 0x24))

#define RPU_LOCKSTEP_ERROR   (1 << 0)  /* Lockstep compare error bit */

/* Zynq Lockstep Error Handler */
void zynq_lockstep_error_handler(void)
{
    uint32_t error_status = RPU_ERR_STATUS;

    if (error_status & RPU_LOCKSTEP_ERROR) {
        /* Log error */
        log_fatal_error(LOCKSTEP_ERROR_ZYNQ, error_status);

        /* Clear error status (write 1 to clear) */
        RPU_ERR_STATUS = RPU_LOCKSTEP_ERROR;

        /* Trigger reset via PMU or PSCI */
        trigger_system_reset();
    }
}

/* Zynq Status Monitoring */
int zynq_check_lockstep_status(void)
{
    return (RPU_ERR_STATUS & RPU_LOCKSTEP_ERROR) ? -1 : 0;
}
```

**NXP i.MX Series Implementation:**

```c
/* i.MX Register Definitions (Example - verify with your specific i.MX variant) */
#define IMX_ERROR_BASE       0x00000000  /* Replace with actual base address */
#define IMX_ERROR_STATUS     (*(volatile uint32_t *)(IMX_ERROR_BASE + 0x00))
#define IMX_ERROR_CLEAR      (*(volatile uint32_t *)(IMX_ERROR_BASE + 0x04))

/* i.MX Lockstep Error Handler */
void imx_lockstep_error_handler(void)
{
    uint32_t error_status = IMX_ERROR_STATUS;

    /* Log error */
    log_fatal_error(LOCKSTEP_ERROR_IMX, error_status);

    /* Clear error status */
    IMX_ERROR_CLEAR = error_status;

    /* Trigger system reset */
    trigger_system_reset();
}
```

**Generic Status Monitoring Loop (for periodic checking):**

```c
/* Background monitoring task - checks for lockstep errors periodically */
void lockstep_monitor_thread(ULONG unused)
{
    (void)unused;

    while (1) {
        /* Call vendor-specific status check */
        #if defined(TMS570)
            if (tms570_check_lockstep_status() != 0) {
                tms570_lockstep_error_handler();
            }
        #elif defined(ZYNQ_ULTRASCALE)
            if (zynq_check_lockstep_status() != 0) {
                zynq_lockstep_error_handler();
            }
        #elif defined(IMX)
            if (imx_check_lockstep_status() != 0) {
                imx_lockstep_error_handler();
            }
        #endif

        /* Check every 100ms */
        tx_thread_sleep(TX_TIMER_TICKS_PER_SECOND / 10);
    }
}
```

**Integration Checklist:**
- [ ] Identify lockstep error register addresses from SoC TRM
- [ ] Register error handler to appropriate interrupt vector (ESM/NMI/error IRQ)
- [ ] Implement non-volatile logging function (EEPROM/Flash)
- [ ] Implement system reset function (watchdog/reset controller)
- [ ] Test error path with fault injection (Test #1 above)

### 9.8 Lockstep Configuration Checklist

**Hardware Configuration (before ThreadX initialization):**
- [ ] Verify Cortex-R5 configured in lockstep mode (hardware straps/fuses, not runtime software)
- [ ] Confirm both cores enabled with identical clock configuration
- [ ] Configure lockstep error output signal routing (if required)
- [ ] Enable lockstep error interrupt (if using error handler)
- [ ] Configure watchdog timer with appropriate timeout (worst-case latency + margin)

**Software Configuration:**
- [ ] Use standard ThreadX (NOT ThreadX SMP)
- [ ] Compile with optimization (-O2 or -O3) to expose barrier issues
- [ ] Enable stack checking (TX_ENABLE_STACK_CHECKING) for validation
- [ ] Disable debug/trace features in production builds

**Testing:**
- [ ] Perform cold boot TCM scrubbing test (verify all TCM initialized before lockstep enable)
- [ ] Run interrupt stress test (extended duration, high interrupt rate)
- [ ] Validate context switch determinism (100K+ switches, no errors)
- [ ] Perform memory barrier validation (with -O3 -flto compilation)
- [ ] Inject lockstep faults (if hardware supports) to verify error detection
- [ ] Test clock monitor/voltage monitor integration (if applicable)
- [ ] Verify watchdog triggers reset when system halts
- [ ] Monitor vendor-specific error status registers during testing

**Documentation:**
- [ ] Document lockstep error handler implementation (if used)
- [ ] Record lockstep configuration settings (registers, values)
- [ ] Document debug strategy for lockstep mode (software-based)
- [ ] Maintain test results for safety certification

### 9.9 Transitioning Between Lockstep and SMP Modes

**CRITICAL: Lockstep and SMP are mutually exclusive hardware configurations.**

Transitioning between modes **requires hardware reconfiguration and full system reset** - this is NOT a runtime software operation.

**Hardware Reconfiguration Process:**

**Step 1: Hardware Strap/Fuse Changes**
- Modify hardware straps (GPIO, resistor straps, or eFuse programming)
- Common methods:
  - **TI TMS570**: LBIST configuration pins sampled at reset
  - **Xilinx Zynq UltraScale+**: Boot mode pins or eFuse BOOT_MODE settings
  - **NXP i.MX**: Configuration pins or one-time programmable fuses
- Consult your SoC technical reference manual for exact procedure

**Step 2: Power Cycle/Hard Reset Required**
- Soft reset (software reset via SCR register) is **INSUFFICIENT**
- Full hardware reset required to re-sample strap configuration
- Some SoCs require complete power cycle (VDD removal)

**Step 3: Software Stack Changes (if switching to SMP)**

If reconfiguring hardware from lockstep → SMP:

**Hardware Enablement:**
1. Verify SMP mode active after reset (check vendor status register)
2. Enable SCU (Snoop Control Unit) for cache coherency
3. Configure GIC for per-core interrupt routing (enable CPU interface 1)
4. Enable ACP (Accelerator Coherency Port) if using DMA

**Software Replacement:**
1. Replace ThreadX with ThreadX SMP (`common_smp/` sources)
2. Implement cache coherency barriers (DSB + cache clean/invalidate)
3. Add SMP-safe spinlocks for shared data structures
4. Update linker script for per-core stacks
5. Test extensively for race conditions and deadlocks

**Important:** Do NOT attempt to run standard ThreadX in SMP mode. Use ThreadX SMP variant from `common_smp/` and `ports_smp/` directories.

**Transitioning from SMP → Lockstep:**
- Reverse the above process
- Switch to standard ThreadX (this directory)
- Remove SMP-specific barriers and spinlocks
- Simplify to single-core programming model

## 10. ThreadX Timer Interrupt

ThreadX requires a periodic interrupt source to manage all time-slicing, thread sleeps, timeouts, and application timers. Without such a timer interrupt source, these services are not functional but the remainder of ThreadX will still run.

To add the timer interrupt processing, simply make a call to `_tx_timer_interrupt` in the IRQ processing. An example of this can be found in the file `tx_initialize_low_level.S` for the demonstration system.

## 11. GIC (Generic Interrupt Controller) Support

The Cortex-R5 port includes optional GIC (Generic Interrupt Controller) initialization and IRQ dispatch support. This is essential for systems using ARM GIC v1/v2 interrupt controllers, such as the Xilinx Zynq UltraScale+ RPU.

**ARM Reference**: GIC Architecture Specification (IHI 0048B)

### 11.1 Enabling GIC Support

To enable GIC support, define `TX_ENABLE_GIC_SUPPORT` when compiling `tx_initialize_low_level.S`:

```bash
arm-none-eabi-gcc -DTX_ENABLE_GIC_SUPPORT -c tx_initialize_low_level.S
```

Optional defines:

| Define | Default | Description |
|--------|---------|-------------|
| `TX_GIC_DISTRIBUTOR_BASE` | 0xF9000000 | GIC Distributor (GICD) base address |
| `TX_GIC_CPU_INTERFACE_BASE` | 0xF9001000 | GIC CPU Interface (GICC) base address |
| `TX_GIC_MAX_INTERRUPTS` | 192 | Maximum interrupt count for handler table |
| `TX_GIC_TIMER_IRQ` | 29 | Interrupt ID for system timer (PPI #29) |
| `TX_GIC_USE_HANDLER_TABLE` | undefined | Enable handler table dispatch |

### 11.2 GIC Base Address Discovery

GIC base addresses can be discovered via:

**Option 1: CBAR Register (if implemented)**
```assembly
MRC     p15, 4, r0, c15, c0, 0    @ Read CBAR
@ GICD = CBAR + 0x1000
@ GICC = CBAR + 0x2000
```

**Option 2: Platform-Specific (default)**
Override via compiler defines:
```bash
-DTX_GIC_DISTRIBUTOR_BASE=0xF9000000 -DTX_GIC_CPU_INTERFACE_BASE=0xF9001000
```

Common platform addresses:

| Platform | GICD Base | GICC Base |
|----------|-----------|-----------|
| Zynq UltraScale+ RPU | 0xF9000000 | 0xF9001000 |
| Zynq-7000 | 0xF8F01000 | 0xF8F00100 |
| TI K2x/AM6x | Varies | Varies |

### 11.3 GIC Initialization

Call `_tx_gic_initialize()` before enabling interrupts (typically in `tx_application_define` or early startup):

```c
extern void _tx_gic_initialize(void);

void tx_application_define(void *first_unused_memory)
{
    /* Initialize GIC before creating threads */
    _tx_gic_initialize();

    /* Enable timer interrupt */
    _tx_gic_enable_irq(TX_GIC_TIMER_IRQ);
    _tx_gic_set_priority(TX_GIC_TIMER_IRQ, 0x80);

    /* Create threads... */
}
```

The initialization sequence:
1. Disable distributor
2. Read GICD_TYPER to determine interrupt count
3. Disable all interrupts (GICD_ICENABLER)
4. Clear all pending interrupts (GICD_ICPENDR)
5. Clear all active interrupts (GICD_ICACTIVER)
6. Set default priority (0x80) for all interrupts
7. Set CPU target to CPU0 for all SPIs
8. Initialize CPU interface (PMR=0xFF, BPR=3)
9. Enable distributor and CPU interface

### 11.4 GIC API Functions

**Initialization:**
```c
void _tx_gic_initialize(void);       /* Initialize GIC distributor and CPU interface */
```

**Interrupt Control:**
```c
void _tx_gic_enable_irq(uint32_t irq_id);           /* Enable specific interrupt */
void _tx_gic_disable_irq(uint32_t irq_id);          /* Disable specific interrupt */
void _tx_gic_set_priority(uint32_t irq_id, uint32_t priority);  /* Set priority (0=highest) */
```

**Software Generated Interrupts (SGIs):**
```c
void _tx_gic_send_sgi(uint32_t sgi_id, uint32_t filter, uint32_t target_list);
/* filter: 0=use target_list, 1=all except self, 2=only self */
/* target_list: CPU bitmask (when filter=0) */
```

**Handler Table (when TX_GIC_USE_HANDLER_TABLE defined):**
```c
void* _tx_gic_register_handler(uint32_t irq_id, void (*handler)(uint32_t));
/* Returns previous handler, or NULL if none */
```

### 11.5 IRQ Dispatch Modes

**Mode 1: Direct Dispatch (default)**

The IRQ handler checks the interrupt ID and calls the appropriate handler directly:

```assembly
CMP     r0, #TX_GIC_TIMER_IRQ
BNE     _gic_not_timer
BL      _tx_timer_interrupt
```

Add additional handlers by modifying `__tx_irq_processing_return` in `tx_initialize_low_level.S`.

**Mode 2: Handler Table Dispatch**

Enable with `-DTX_GIC_USE_HANDLER_TABLE`. Provides a function pointer table for dynamic handler registration:

```c
/* Handler signature */
typedef void (*gic_handler_t)(uint32_t irq_id);

/* Register handlers */
_tx_gic_register_handler(UART_IRQ, uart_isr);
_tx_gic_register_handler(DMA_IRQ, dma_isr);
_tx_gic_register_handler(TX_GIC_TIMER_IRQ, timer_isr);
```

Handler table size is `TX_GIC_MAX_INTERRUPTS * 4` bytes (default: 768 bytes for 192 interrupts).

### 11.6 IRQ Handler Flow

```
IRQ Exception
    │
    ├─► _tx_thread_context_save         (save thread context)
    │
    ├─► Read GICC_IAR                   (acknowledge interrupt, get ID)
    │       │
    │       ├─► ID >= 1020?  ──► Yes ──► Spurious, exit
    │       │
    │       └─► ID < 1020?  ──► Dispatch to handler
    │               │
    │               └─► Write GICC_EOIR (signal completion)
    │
    └─► _tx_thread_context_restore      (restore context, may switch threads)
```

**CRITICAL: IAR/EOIR Pairing**

The value written to GICC_EOIR **must** be the exact value read from GICC_IAR, including the CPU ID bits (bits 12:10) for SGIs. Failure to do so causes interrupt handling errors.

### 11.7 Timer Interrupt Configuration

The default timer interrupt ID is PPI #29 (Private Timer). Override for your platform:

```bash
-DTX_GIC_TIMER_IRQ=27    # Example: Use IRQ 27 for timer
```

Common timer interrupt IDs:

| Timer Type | Typical IRQ ID | Notes |
|------------|----------------|-------|
| ARM Private Timer | 29 (PPI #13) | Per-core timer |
| ARM Global Timer | 27 (PPI #11) | Shared timer |
| Platform Timer | Varies | Consult SoC TRM |

### 11.8 Example: Complete GIC Setup

```c
/* tx_application_define.c */

extern void _tx_gic_initialize(void);
extern void _tx_gic_enable_irq(unsigned int irq);
extern void _tx_gic_set_priority(unsigned int irq, unsigned int prio);

#define TIMER_IRQ       29      /* Private Timer PPI */
#define UART0_IRQ       53      /* UART0 SPI (example) */

void tx_application_define(void *first_unused_memory)
{
    /* Initialize GIC */
    _tx_gic_initialize();

    /* Configure timer interrupt */
    _tx_gic_set_priority(TIMER_IRQ, 0x80);
    _tx_gic_enable_irq(TIMER_IRQ);

    /* Configure UART interrupt */
    _tx_gic_set_priority(UART0_IRQ, 0xA0);  /* Lower priority than timer */
    _tx_gic_enable_irq(UART0_IRQ);

    /* Start platform timer hardware (vendor-specific) */
    /* Example: configure_arm_private_timer(TICK_RATE_HZ); */

    /* Create application threads... */
}
```

### 11.9 Common Mistakes

1. **Enabling interrupts before GIC init**: Always call `_tx_gic_initialize()` first
2. **Missing EOIR write**: Causes interrupt to remain pending, system hangs
3. **Wrong EOIR value**: Write exact IAR value, not just the interrupt ID
4. **Wrong base addresses**: Verify GICD/GICC addresses for your platform
5. **Timer not enabled in hardware**: GIC enable is separate from timer peripheral enable

### 11.10 GIC and FIQ Interaction

The GIC implementation routes all interrupts through the IRQ handler by default:

**Current Configuration:**
- All interrupts default to **Group 0** (GICD_IGROUPR registers not modified)
- **FIQEn = 0** in GICC_CTLR (bit 3 not set), meaning Group 0 signals as IRQ
- Result: All GIC-managed interrupts use the IRQ path with GIC dispatch

**FIQ Handler Independence:**
The FIQ handler (`__tx_fiq_handler`) operates independently of GIC:
- No GIC IAR/EOIR acknowledgment in FIQ path
- Suitable for dedicated FIQ sources not routed through GIC
- Used for latency-critical interrupts requiring minimal overhead

**Using GIC-Managed FIQ (Advanced):**
To route Group 0 interrupts to FIQ:
1. Set FIQEn bit: Modify `_tx_gic_initialize` to write `0x0F` to GICC_CTLR (instead of 0x07)
2. Add GIC dispatch to FIQ handler: Read GICC_AIAR (0x20), dispatch, write GICC_AEOIR (0x24)
3. Configure interrupt groups: Write GICD_IGROUPR to assign interrupts to Group 0 (FIQ) or Group 1 (IRQ)

**Typical ZynqMP RPU Usage:**
Most applications use all interrupts through IRQ. The default configuration is appropriate for:
- Timer interrupts (PPI #29 or TTC)
- UART, SPI, I2C peripherals
- DMA completion interrupts
- Inter-processor interrupts (IPI)

If dedicated low-latency FIQ is needed for a specific source not requiring GIC features, use `TX_ENABLE_FIQ_SUPPORT` with direct FIQ pin routing, bypassing GIC entirely

### 11.11 GIC Deferred EOI (Level-Triggered Interrupt Fix)

For platforms with level-triggered interrupts, there is a race window between the EOIR write in the IRQ handler and the CPSID in `_tx_thread_context_restore`. If the peripheral still asserts the interrupt signal, the interrupt can re-trigger before interrupts are masked.

**The Race Window:**
```
Normal flow:
  Handler → EOIR write → ... → context_restore → CPSID
                          ↑
            Race window: interrupt can re-trigger before CPSID
```

**Deferred EOI Solution:**
```
Deferred EOI:
  Handler → save IAR → ... → context_restore → CPSID → EOIR write
                                                        ↑
                                          Safe: IRQs already masked
```

**Enabling Deferred EOI:**

In `tx_user.h`:
```c
#define TX_GIC_DEFERRED_EOI

/* Optional: Override GIC base address if not ZynqMP */
#define TX_GIC_CPU_INTERFACE_BASE    0xF9001000
```

**Constraints:**
- **Single-core only**: Uses global `_tx_gic_iar` variable
- **NOT compatible with TX_ENABLE_IRQ_NESTING**: Build will fail with error
- **Requires TX_ENABLE_GIC_SUPPORT**: Must be enabled in tx_initialize_low_level.S
- **GICv2 only**: GICv3 uses different register interface

**How It Works:**
1. IRQ handler reads GICC_IAR and saves it to `_tx_gic_iar`
2. Handler runs normally but does NOT write EOIR
3. `_tx_thread_context_restore` executes CPSID (disabling interrupts)
4. After CPSID, deferred EOIR block writes the saved IAR to GICC_EOIR
5. Interrupt is now safely completed with no race window

**When to Use:**
- Level-triggered interrupts that remain asserted during handler execution
- Platforms where peripheral interrupt clear has latency
- Systems experiencing spurious interrupt storms

**When NOT to Use:**
- Edge-triggered interrupts (no race condition)
- Systems requiring IRQ nesting (incompatible)
- Multi-core systems (global variable not core-safe)
