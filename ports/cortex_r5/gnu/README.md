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

**⚠️ CRITICAL**: ACTLR bits are **IMPLEMENTATION DEFINED** in ARMv7-R architecture. The following bit assignments are **examples** and must be verified against your specific SoC Technical Reference Manual:

- **Bit 25**: ATCM ECC check enable (example - verify for your SoC)
- **Bit 26**: BTCM ECC check enable (example - verify for your SoC)
- **Bit 27**: BTCM ECC error reporting enable (example - verify for your SoC)
- **Bit 28**: ATCM ECC error reporting enable (example - verify for your SoC)

**Vendor-Specific ACTLR Mappings** (always verify with latest TRM):
- **TI TMS570**: Check TMS570 TRM Chapter 2 (ARM Cortex-R5F Core)
- **Xilinx Zynq UltraScale+ MPSoC**: Check Zynq UltraScale+ TRM UG1085, R5F subsystem
- **NXP i.MX**: Check i.MX series TRM for Cortex-R5 ACTLR register map

**Note**: Both "check enable" and "error reporting enable" bits must be set to generate Data Abort exceptions on uncorrectable errors. Incorrect bit usage will silently disable ECC protection.

**⚠️ CRITICAL SAFETY WARNINGS:**

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

## 9. ThreadX Timer Interrupt

ThreadX requires a periodic interrupt source to manage all time-slicing, thread sleeps, timeouts, and application timers. Without such a timer interrupt source, these services are not functional but the remainder of ThreadX will still run.

To add the timer interrupt processing, simply make a call to `_tx_timer_interrupt` in the IRQ processing. An example of this can be found in the file `tx_initialize_low_level.S` for the demonstration system.
