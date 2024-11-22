#ifndef TX_RWLOCK_H
#define TX_RWLOCK_H

#include "tx_api.h"

typedef struct TX_RWLOCK_STRUCT
{
    CHAR* tx_rwlock_name;
    ULONG tx_rwlock_rcounter;
    TX_MUTEX tx_rwlock_mtx_rcounter;
    TX_SEMAPHORE tx_rwlock_sem_write;
} TX_RWLOCK;

/**
 * Create a read/write lock.
 *
 * @param rwlock_ptr        Pointer to the read/write lock control block.
 * @param name_ptr          Pointer to the name of the read/write lock.
 * @param priority_inherit  Specifies whether this read/write lock supports priority inheritance.
 *                          If set to `TX_INHERIT`, priority inheritance is enabled.
 *                          If set to `TX_NO_INHERIT`, priority inheritance is disabled.
 *
 * @retval TX_SUCCESS           (0x00) Read/write lock created successfully.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal semaphore pointer (NULL or semaphore already created).
 * @retval TX_MUTEX_ERROR       (0x1C) Invalid internal mutex pointer (NULL or mutex already created).
 * @retval TX_INHERIT_ERROR     (0x1F) Invalid priority inheritance parameter.
 * @retval TX_CALLER_ERROR      (0x13) Invalid caller of this service.
 */
UINT tx_rwlock_create(TX_RWLOCK* rwlock_ptr, CHAR* name_ptr, UINT inherit);

/**
 * Delete a read/write lock.
 *
 * @param rwlock_ptr  Pointer to a previously created read/write lock.
 *
 * @retval TX_SUCCESS           (0x00) Read/write lock deleted successfully.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 * @retval TX_CALLER_ERROR      (0x13) Invalid caller of this service.
 */
UINT tx_rwlock_delete(TX_RWLOCK* rwlock_ptr);

/**
 * Obtain read access to a read/write lock.
 *
 * @param rwlock_ptr   Pointer to a previously created read/write lock.
 * @param wait_option  Defines how the service behaves if the read/write lock is
 *                     already owned by another thread for writing.
 *                     Can be TX_NO_WAIT, TX_WAIT_FOREVER, or a positive
 *                     number of ticks to wait.
 *
 * @retval TX_SUCCESS           (0x00) Successfully obtained the read/write lock.
 * @retval TX_DELETED           (0x01) Internal mutex or counting semaphore was
 *                                    deleted while the thread was suspended.
 * @retval TX_NOT_AVAILABLE     (0x1D) Failed to obtain the mutex within the
 *                                    specified wait time.
 * @retval TX_NO_INSTANCE       (0x0D) Unable to retrieve an instance of the
 *                                    counting semaphore (semaphore count is zero
 *                                    within the specified wait time).
 * @retval TX_WAIT_ABORTED      (0x1A) Suspension was aborted by another thread,
 *                                    timer, or ISR.
 * @retval TX_MUTEX_ERROR       (0x1C) Invalid internal mutex pointer.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 * @retval TX_WAIT_ERROR        (0x04) A wait option other than `TX_NO_WAIT` was
 *                                    specified in a call from a non-thread.
 * @retval TX_CALLER_ERROR      (0x13) Invalid caller of this service.
 */
UINT tx_rwlock_rget(TX_RWLOCK* rwlock_ptr, ULONG wait_option);

/**
 * Release read access to the read/write lock.
 *
 * @param rwlock_ptr  Pointer to a previously created read/write lock.
 *
 * @retval TX_SUCCESS       (0x00) Read/write lock released successfully.
 * @retval TX_NOT_OWNED     (0x1E) Read/write lock is not owned by the caller.
 * @retval TX_MUTEX_ERROR   (0x1C) Invalid internal mutex pointer.
 * @retval TX_CALLER_ERROR  (0x13) Invalid caller of this service.
 */
UINT tx_rwlock_rput(TX_RWLOCK* rwlock_ptr);

/**
 * Obtain exclusive ownership for writing to a read/write lock.
 *
 * @param rwlock_ptr   Pointer to a previously created read/write lock.
 * @param wait_option  Defines how the service behaves if the read/write lock is
 *                     already being used by another thread for reading or writing.
 *                     Can be TX_NO_WAIT, TX_WAIT_FOREVER, or a positive
 *                     number of ticks to wait.
 *
 * @retval TX_SUCCESS           (0x00) Successfully obtained exclusive write access to the read/write lock.
 * @retval TX_DELETED           (0x01) Internal mutex or counting semaphore was deleted
 *                                    while the thread was suspended.
 * @retval TX_NO_INSTANCE       (0x0D) Unable to obtain write access to the read/write lock.
 * @retval TX_WAIT_ABORTED      (0x1A) Suspension was aborted by another thread, timer,
 *                                    or ISR.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 * @retval TX_WAIT_ERROR        (0x04) A wait option other than TX_NO_WAIT was
 *                                    specified in a call from a non-thread.
 */
#ifdef TX_RWLOCK_INLINE_WRITE
#define tx_rwlock_wget(rwlock_ptr, wait_option)  tx_semaphore_get(&((rwlock_ptr)->tx_rwlock_sem_write), wait_option)
#else
UINT tx_rwlock_wget(TX_RWLOCK* rwlock_ptr, ULONG wait_option);
#endif

/**
 * Release ownership of the read/write lock for writing.
 *
 * @param rwlock_ptr  Pointer to a previously created read/write lock.
 *
 * @retval TX_SUCCESS           (0x00) Successfully released the read/write lock.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 */
#ifdef TX_RWLOCK_INLINE_WRITE
#define tx_rwlock_wput(rwlock_ptr)  tx_semaphore_put(&((rwlock_ptr)->tx_rwlock_sem_write))
#else
UINT tx_rwlock_wput(TX_RWLOCK* rwlock_ptr);
#endif

/**
 * Prioritize the read/write lock's waiting list for writing access.
 *
 * @param rwlock_ptr  Pointer to a previously created read/write lock.
 *
 * @retval TX_SUCCESS           (0x00) Successfully prioritized the waiting list for writing access.
 * @retval TX_SEMAPHORE_ERROR   (0x0C) Invalid internal counting semaphore pointer.
 */
#ifdef TX_RWLOCK_INLINE_WRITE
#define tx_rwlock_prioritize_write(rwlock_ptr)  tx_semaphore_prioritize(&((rwlock_ptr)->tx_rwlock_sem_write))
#else
UINT tx_rwlock_prioritize_write(TX_RWLOCK* rwlock_ptr);
#endif

#endif
