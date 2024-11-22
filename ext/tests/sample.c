/*
 * This program creates three tasks, a barrier, a mutex, and a read/write lock.
 * And then it compares performance between mutex and read/write lock for array
 * access.
 */

#include <stdio.h>
#include <stdlib.h>

#include "tx_api.h"

#include "tx_taskq.h"
#include "tx_rwlock.h"
#include "tx_barrier.h"

#include "safe_data.h"

/* Priorities */
#define TASK_PRIO_FILL  2
#define TASK_PRIO_UNIQ  4
#define TASK_PRIO_PROC  5

/* Memory sizes */
#define STACK_SIZE          512
#define BYTE_POOL_SIZE      4096

/* Quantities */
#define PENDING_TASK_NUM    6 
#define DATA_BLOCK_LEN      256

/* Durations (ticks) */
#define GENERATOR_PERIOD    (TX_TIMER_TICKS_PER_SECOND/5)
#define POLL_PERIOD         (TX_TIMER_TICKS_PER_SECOND/20)

/* Sample data */
CHAR* pool_names[] = { "th0", "th1", "th2", "th3", "th4", "th5"};
struct {
    UINT factor;
    CHAR* name;
    ULONG counter;    
} counters[] = {
    { 23, "...x23" },
    { 31, "...x31" },
    { 47, "...x47" },
    { 79, "...x79" }
};

#define THREAD_POOL_SIZE    (sizeof(pool_names)/sizeof(CHAR*))
#define COUNTER_NUM         (sizeof(counters)/sizeof(counters[0]))

UCHAR byte_pool_mem[BYTE_POOL_SIZE];

#define CHECK(action)   { UINT ret = (action); if(TX_SUCCESS != ret) return; }

/* Define the ThreadX object control blocks */
TX_THREAD pool[THREAD_POOL_SIZE];
TX_BYTE_POOL byte_pool;
TX_TASKQ tasks;
TX_BARRIER barrier;
TX_SEMAPHORE join;

/* Define task prototypes. */
VOID task_main          (ULONG input);
VOID task_fill_random   (ULONG input);
VOID task_update_unique (ULONG input);
VOID task_process       (ULONG input);

/* Join (aka wait) counters functions */
VOID join_counters(int count);
VOID join_counters_callback(TX_TASKQ_ITEM* item, UINT started);

/* Utilities */
VOID print_progress(const char* title, UINT quantity);

/****************************************************/
/* Entry Points                                     */
/****************************************************/

int main()
{
    tx_kernel_enter();
}

void tx_application_define(void* first_unused_memory)
{
    VOID* taskq_mem;
    VOID* pool_stack_ptr[THREAD_POOL_SIZE];
    
    /* Init modules */
    CHECK(safe_data_init());
    
    /* Create sync objects */
    CHECK(tx_barrier_create(&barrier, "done", 2, TX_INHERIT));
    CHECK(tx_semaphore_create(&join, "join", 0));
    tx_taskq_enter_exit_notify(join_counters_callback);

    /* Create a memory byte pool for thread stack allocation and task queue. */
    CHECK(tx_byte_pool_create(&byte_pool, "byte pool", byte_pool_mem, BYTE_POOL_SIZE));

    /* Create the pool  */
    CHECK(tx_byte_allocate(&byte_pool, &taskq_mem, TX_TASKQ_SIZE(PENDING_TASK_NUM), TX_NO_WAIT));
    CHECK(tx_taskq_create(&tasks, "taskq", taskq_mem, TX_TASKQ_SIZE(PENDING_TASK_NUM)));

    /* Create runner thread for the pool  */
    for (int i = 0; i < THREAD_POOL_SIZE; i++)
    {
        CHECK(tx_byte_allocate(&byte_pool, pool_stack_ptr+i, STACK_SIZE, TX_NO_WAIT));
        CHECK(tx_taskq_create_runner(&tasks, pool + i, pool_names[i], pool_stack_ptr[i], STACK_SIZE));
    }
    
    /* Run main task */
    tx_taskq_send(&tasks, task_main, 0, 1, 1, TX_NO_WAIT);
}

/****************************************************/
/* Tasks                                            */
/****************************************************/

VOID task_main(ULONG input)
{
    static int use_mutex = TX_TRUE;

    while (TX_LOOP_FOREVER)
    {
        /* Select data protection mode */
        if (use_mutex)
        {
            printf("MUTEX\n");
            safe_data_use_mutex();
        }
        else
        {
            printf("R/W LOCK\n");
            safe_data_use_rwlock();
        }
        /* Start tasks */
        ULONG start = tx_time_get();

        tx_taskq_send(&tasks, task_fill_random  , 0, TASK_PRIO_FILL, TASK_PRIO_FILL, TX_NO_WAIT);
        tx_barrier_wait(&barrier, TX_WAIT_FOREVER);

        tx_taskq_send(&tasks, task_update_unique, 0, TASK_PRIO_UNIQ, TASK_PRIO_UNIQ, TX_NO_WAIT);
        for (UINT i = 0; i < COUNTER_NUM; i++)
        {
            counters[i].counter = 0;
            tx_taskq_send(&tasks, task_process, i, TASK_PRIO_PROC+i, TASK_PRIO_PROC, TX_NO_WAIT);
        }

        /* Wait for the end of all task process */
        join_counters(COUNTER_NUM);

        printf("- Performance %d\n", tx_time_get() - start);
        tx_barrier_reset(&barrier);

        /* Change the data protection mode */
        use_mutex = !use_mutex;
    }
}

VOID task_fill_random(ULONG input)
{
    srand(0);
    safe_data_clear();
    tx_barrier_wait(&barrier, TX_WAIT_FOREVER);
    for (UINT generated = 0; generated < SAFE_DATA_SIZE; generated += DATA_BLOCK_LEN)
    {
        safe_data_fill_random(DATA_BLOCK_LEN);
        print_progress("Generated", generated + DATA_BLOCK_LEN);
        tx_thread_sleep(GENERATOR_PERIOD);
    }
}

VOID task_update_unique(ULONG input)
{
    for (UINT updated = 0; updated < SAFE_DATA_SIZE; )
    {
        UINT checked = safe_data_unique_update();

        if (checked)
        {
            updated += checked;
            print_progress("Uniqueness", updated);
        }
        else
        {
            tx_thread_sleep(POLL_PERIOD);
        }
    }
}

static VOID task_process_callback(unsigned index, unsigned value, unsigned long counter_index)
{
    if (value % counters[counter_index].factor == 0 && safe_data_unique_check(index))
    {
        counters[counter_index].counter++;
        tx_thread_sleep(2);
    }
}

VOID task_process(ULONG input)
{
    printf("- Process %d : start\n", input);
    for (UINT processed = 0; processed < SAFE_DATA_SIZE; )
    {
        if (safe_data_browse(&processed, task_process_callback, input))
        {
            print_progress(counters[input].name, processed);
        }
        else
        {
            tx_thread_sleep(POLL_PERIOD);
        }
    }
}

/****************************************************/
/* Utilities                                        */
/****************************************************/

VOID print_progress(const char* title, UINT quantity)
{
    printf("- %s %d%%\n", title, (quantity * 100) / SAFE_DATA_SIZE);
}

VOID join_counters_callback(TX_TASKQ_ITEM* item, UINT started)
{
    if (!started && item->task_entry_function == task_process)
    {
        tx_semaphore_put(&join);
    }
}

VOID join_counters(int count)
{
    while (count--)
    {
        tx_semaphore_get(&join, TX_WAIT_FOREVER);
    }
}
