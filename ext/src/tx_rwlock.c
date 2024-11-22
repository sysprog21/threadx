#include "tx_rwlock.h"

UINT tx_rwlock_create(TX_RWLOCK* rwlock_ptr, CHAR* name_ptr, UINT inherit)
{
    rwlock_ptr->tx_rwlock_name = name_ptr;
    rwlock_ptr->tx_rwlock_rcounter = 0;
    UINT ret = tx_mutex_create(&(rwlock_ptr->tx_rwlock_mtx_rcounter), name_ptr, inherit);

    if (TX_SUCCESS == ret)
    {
        ret = tx_semaphore_create(&(rwlock_ptr->tx_rwlock_sem_write), name_ptr, 1);
    }
    return ret;
}

UINT tx_rwlock_delete(TX_RWLOCK* rwlock_ptr)
{
    tx_mutex_delete(&(rwlock_ptr->tx_rwlock_mtx_rcounter));
    return tx_semaphore_delete(&(rwlock_ptr->tx_rwlock_sem_write));
}

UINT tx_rwlock_rget(TX_RWLOCK* rwlock_ptr, ULONG wait_option)
{
    ULONG start = tx_time_get();
    UINT ret = tx_mutex_get(&(rwlock_ptr->tx_rwlock_mtx_rcounter), wait_option);

    if (TX_SUCCESS == ret)
    {
        if (!rwlock_ptr->tx_rwlock_rcounter)
        {
            /* Adjust the wait option if acquiring the mutex was delayed */
            if (TX_WAIT_FOREVER != wait_option)
            {
                ULONG elapsed = tx_time_get() - start;
                
                wait_option = elapsed >= wait_option ? TX_NO_WAIT : wait_option - elapsed;
            }
            /* Acquire the write semaphore to block write access */
            ret = tx_semaphore_get(&(rwlock_ptr->tx_rwlock_sem_write), wait_option);
        }
        if (TX_SUCCESS == ret)
        {
            rwlock_ptr->tx_rwlock_rcounter++;            
        }
        /* Other readers can attempt access (even if a writer is present) */
        ret = tx_mutex_put(&(rwlock_ptr->tx_rwlock_mtx_rcounter));
    }
    return ret;            
}

UINT tx_rwlock_rput(TX_RWLOCK* rwlock_ptr)
{
    UINT ret = tx_mutex_get(&(rwlock_ptr->tx_rwlock_mtx_rcounter), TX_WAIT_FOREVER);

    if (TX_SUCCESS == ret)
    {
        if (!--(rwlock_ptr->tx_rwlock_rcounter))
        {
            /* Last reader releases write access */
            tx_semaphore_put(&(rwlock_ptr->tx_rwlock_sem_write));
        }
        ret = tx_mutex_put(&(rwlock_ptr->tx_rwlock_mtx_rcounter));
    }
    return ret;
}

#ifndef TX_RWLOCK_INLINE_WRITE

UINT tx_rwlock_wget(TX_RWLOCK* rwlock_ptr, ULONG wait_option)
{
    return tx_semaphore_get(&((rwlock_ptr)->tx_rwlock_sem_write), wait_option);
}

UINT tx_rwlock_wput(TX_RWLOCK* rwlock_ptr)
{
    return tx_semaphore_put(&((rwlock_ptr)->tx_rwlock_sem_write));
}

UINT tx_rwlock_prioritize_write(TX_RWLOCK* rwlock_ptr)
{
    return tx_semaphore_prioritize(&((rwlock_ptr)->tx_rwlock_sem_write));
}

#endif
