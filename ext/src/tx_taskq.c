#include "tx_taskq.h"

#ifndef TX_DISABLE_NOTIFY_CALLBACKS
static VOID(*_taskq_enter_exit_notify)(TX_TASKQ_ITEM* item, UINT started) = TX_NULL;
#endif

UINT tx_taskq_enter_exit_notify(VOID(*taskq_enter_exit_notify)(TX_TASKQ_ITEM* item, UINT started))
{
#ifdef TX_DISABLE_NOTIFY_CALLBACKS
    return TX_FEATURE_NOT_ENABLED;
#else
    _taskq_enter_exit_notify = taskq_enter_exit_notify;
    return TX_SUCCESS;
#endif
}

VOID tx_taskq_runner_entry_function(ULONG task_pool_ptr)
{
    TX_TASKQ* taskq = (TX_QUEUE*)task_pool_ptr;
    TX_TASKQ_ITEM task;

    while (TX_LOOP_FOREVER)
    {
        if (TX_SUCCESS == tx_queue_receive(taskq, &task, TX_WAIT_FOREVER))
        {
            UINT old;
            TX_THREAD* th = tx_thread_identify();

            tx_thread_priority_change(th, task.task_priority, &old);
            tx_thread_preemption_change(th, task.task_preemption, &old);
#ifndef TX_DISABLE_NOTIFY_CALLBACKS
            if (_taskq_enter_exit_notify)
            {
                _taskq_enter_exit_notify(&task, TX_TRUE);
            }                
#endif
            task.task_entry_function(task.task_input);
#ifndef TX_DISABLE_NOTIFY_CALLBACKS
            if (_taskq_enter_exit_notify)
            {
                _taskq_enter_exit_notify(&task, TX_FALSE);
            }
#endif
            tx_thread_priority_change(th, 0, &old);
        }
        else
        {
            /* Unexpected failure while receiving from the task queue */
            break;
        }
    }
}
