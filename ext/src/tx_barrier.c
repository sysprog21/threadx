#include "tx_barrier.h"

UINT tx_barrier_create(TX_BARRIER* barrier_ptr, CHAR* name_ptr, UINT raise_count, UINT inherit)
{
    barrier_ptr->tx_barrier_name = name_ptr;
    barrier_ptr->tx_barrier_counter = 0;
    barrier_ptr->tx_barrier_raise_count = raise_count;
    UINT ret = tx_mutex_create(&(barrier_ptr->tx_barrier_mtx_counter), name_ptr, inherit);
    
    if (TX_SUCCESS == ret)
    {
        ret = tx_semaphore_create(&(barrier_ptr->tx_barrier_sem_raise), name_ptr, 0);
    }
    return ret;
}

UINT tx_barrier_delete(TX_BARRIER* barrier_ptr)
{
    tx_mutex_delete(&(barrier_ptr->tx_barrier_mtx_counter));
    return tx_semaphore_delete(&(barrier_ptr->tx_barrier_sem_raise));
}

static UINT _tx_semaphore_abort_suspended(TX_SEMAPHORE* semaphore_ptr)
{
    TX_THREAD* suspended;
    ULONG value;
    
    tx_semaphore_info_get(semaphore_ptr, TX_NULL, &value, &suspended, TX_NULL, TX_NULL);
    if (value)
    {
        tx_semaphore_get(semaphore_ptr, TX_NO_WAIT);
    }
    if (suspended)
    {
        tx_thread_wait_abort(suspended);
    }
    return value || suspended;
}

UINT tx_barrier_reset(TX_BARRIER* barrier_ptr)
{
    UINT ret = tx_mutex_get(&(barrier_ptr->tx_barrier_mtx_counter), TX_WAIT_FOREVER);

    if (TX_SUCCESS == ret)
    {
        barrier_ptr->tx_barrier_counter = 0;        
        while (_tx_semaphore_abort_suspended(&(barrier_ptr->tx_barrier_sem_raise)))
            ;
        tx_mutex_put(&(barrier_ptr->tx_barrier_mtx_counter));
    }
    return ret;
}

UINT tx_barrier_wait(TX_BARRIER* barrier_ptr, ULONG wait_option)
{
    UINT ret = tx_mutex_get(&(barrier_ptr->tx_barrier_mtx_counter), TX_WAIT_FOREVER);

    if (TX_SUCCESS == ret)
    {
        /* Increment the waiters count and determine if waiting is required */
        UINT count = ++(barrier_ptr->tx_barrier_counter);
        UINT wait = count != barrier_ptr->tx_barrier_raise_count;

        tx_mutex_put(&(barrier_ptr->tx_barrier_mtx_counter));
        ret = wait
            ? tx_semaphore_get(&(barrier_ptr->tx_barrier_sem_raise), wait_option)
            : TX_SUCCESS;

        /* Everyone is present; notify the next waiter */
        if (TX_SUCCESS == ret)
        {
            tx_semaphore_put(&(barrier_ptr->tx_barrier_sem_raise));
        }
    }
    return ret;
}
