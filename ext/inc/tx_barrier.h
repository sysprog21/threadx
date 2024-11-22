#ifndef TX_BARRIER_H
#define TX_BARRIER_H

#include "tx_api.h"

typedef struct TX_BARRIER_STRUCT
{
    CHAR* tx_barrier_name;
    ULONG tx_barrier_counter;
    ULONG tx_barrier_raise_count;
    TX_MUTEX tx_barrier_mtx_counter;
    TX_SEMAPHORE tx_barrier_sem_raise;
} TX_BARRIER;

/**
 * Create a barrier.
 *
 * @param barrier_ptr       Pointer to the barrier control block.
 * @param name_ptr          Pointer to the name of the barrier.
 * @param raise_count       Number of calls to `tx_barrier_wait` required to raise the barrier.
 * @param priority_inherit  Specifies whether this barrier supports priority inheritance.
 *                          If set to `TX_INHERIT`, priority inheritance is enabled.
 *                          If set to `TX_NO_INHERIT`, priority inheritance is disabled.
 *
 * @retval TX_SUCCESS           (0x00) Barrier created successfully.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal semaphore pointer (NULL or barrier already created).
 * @retval TX_MUTEX_ERROR       (0x1C) Invalid internal mutex pointer (NULL or mutex already created).
 * @retval TX_INHERIT_ERROR     (0x1F) Invalid priority inheritance parameter.
 * @retval TX_CALLER_ERROR      (0x13) Invalid caller of this service.
 */
UINT tx_barrier_create(TX_BARRIER* barrier_ptr, CHAR* name_ptr, UINT raise_count, UINT inherit);

/**
 * Delete a barrier.
 *
 * @param barrier_ptr  Pointer to a previously created barrier.
 *
 * @retval TX_SUCCESS           (0x00) Barrier deleted successfully.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 * @retval TX_CALLER_ERROR      (0x13) Invalid caller of this service.
 */
UINT tx_barrier_delete(TX_BARRIER* barrier_ptr);

/**
 * Synchronize the current thread with other threads using the barrier.
 *
 * @param barrier_ptr  Pointer to a previously created barrier.
 * @param wait_option  Defines how the service behaves if not all threads have reached the barrier.
 *                     Can be TX_NO_WAIT, TX_WAIT_FOREVER, or a positive number of ticks to wait.
 *
 * @retval TX_SUCCESS           (0x00) Barrier synchronized successfully.
 * @retval TX_DELETED           (0x01) Internal mutex or counting semaphore was deleted while the thread was suspended.
 * @retval TX_NO_INSTANCE       (0x0D) Barrier not raised within the specified wait time. This thread is still counted and must not retry.
 * @retval TX_WAIT_ABORTED      (0x1A) Suspension was aborted by another thread, timer, or ISR. This can occur if `tx_barrier_reset` is called.
 * @retval TX_MUTEX_ERROR       (0x1C) Invalid internal mutex pointer.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 * @retval TX_WAIT_ERROR        (0x04) A wait option other than `TX_NO_WAIT` was specified in a call from a non-thread.
 */
UINT tx_barrier_wait(TX_BARRIER* barrier_ptr, ULONG wait_option);

/**
 * Reset the barrier, aborting all waiting operations.
 *
 * @param barrier_ptr  Pointer to a previously created barrier.
 *
 * @retval TX_SUCCESS  (0x00) Barrier reset successfully.
 */
UINT tx_barrier_reset(TX_BARRIER* barrier_ptr);

#endif
