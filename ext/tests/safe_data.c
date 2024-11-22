#include <stdlib.h>
#include "safe_data.h"
#include "tx_api.h"
#include "tx_rwlock.h"

#define CHECK(action)   { UINT ret = (action); if(TX_SUCCESS != ret) return ret; }

static unsigned safe_data[SAFE_DATA_SIZE];
static unsigned int safe_data_len = 0;
static TX_RWLOCK safe_data_rwlock;
static TX_MUTEX safe_data_mutex;

static unsigned safe_data_unique[SAFE_DATA_SIZE];
static unsigned int safe_data_unique_last = 0;
static unsigned int safe_data_unique_len = 0;
static TX_RWLOCK safe_data_unique_rwlock;
static TX_MUTEX safe_data_unique_mutex;

static VOID* safe_data_lock;
static VOID* safe_data_unique_lock;
static UINT(*safe_data_wget)(VOID*, ULONG);
static UINT(*safe_data_rget)(VOID*, ULONG);
static UINT(*safe_data_wput)(VOID*);
static UINT(*safe_data_rput)(VOID*);

unsigned safe_data_init()
{
    safe_data_len = safe_data_unique_last = safe_data_unique_len = 0;
    
    CHECK(tx_rwlock_create(&safe_data_rwlock       , "safe data r/w lock"        , TX_INHERIT));
    CHECK(tx_rwlock_create(&safe_data_unique_rwlock, "safe data r/w lock uniques", TX_INHERIT));
    CHECK(tx_mutex_create (&safe_data_mutex        , "safe data mutex"           , TX_INHERIT));
    CHECK(tx_mutex_create (&safe_data_unique_mutex , "safe data mutex uniques"   , TX_INHERIT));
    return TX_SUCCESS;
}

void safe_data_shut()
{
    tx_mutex_delete(&safe_data_mutex);
    tx_mutex_delete(&safe_data_unique_mutex);
    tx_rwlock_delete(&safe_data_rwlock);
    tx_rwlock_delete(&safe_data_unique_rwlock);
}

void safe_data_clear()
{
    safe_data_wget(safe_data_lock, TX_WAIT_FOREVER);
    safe_data_len = 0;
    safe_data_wput(safe_data_lock);
    
    safe_data_wget(safe_data_unique_lock, TX_WAIT_FOREVER);
    safe_data_unique_last = safe_data_unique_len = 0;
    safe_data_wput(safe_data_unique_lock);
}

void safe_data_use_mutex()
{
    tx_rwlock_wget(&safe_data_rwlock, TX_WAIT_FOREVER);
    tx_rwlock_wget(&safe_data_unique_rwlock, TX_WAIT_FOREVER);
    
    safe_data_lock        = &safe_data_mutex;
    safe_data_unique_lock = &safe_data_unique_mutex;

    safe_data_wget =
    safe_data_rget = tx_mutex_get;
    safe_data_wput =
    safe_data_rput = tx_mutex_put;

    tx_rwlock_wput(&safe_data_unique_rwlock);
    tx_rwlock_wput(&safe_data_rwlock);
}

void safe_data_use_rwlock()
{
    tx_mutex_get(&safe_data_mutex, TX_WAIT_FOREVER);
    tx_mutex_get(&safe_data_unique_mutex, TX_WAIT_FOREVER);

    safe_data_lock = &safe_data_rwlock;
    safe_data_unique_lock = &safe_data_unique_rwlock;
    
    safe_data_wget = tx_rwlock_wget;
    safe_data_rget = tx_rwlock_rget;
    safe_data_wput = tx_rwlock_wput;
    safe_data_rput = tx_rwlock_rput;

    tx_mutex_put(&safe_data_unique_mutex);
    tx_mutex_put(&safe_data_mutex);    
}

void safe_data_fill_random(unsigned len)
{
    safe_data_wget(safe_data_lock, TX_WAIT_FOREVER);
    {
        /* Ceil len if too big */
        if (safe_data_len + len > SAFE_DATA_SIZE)
        {
            len = SAFE_DATA_SIZE - safe_data_len;
        }
        /* Fill rwldata */
        for (unsigned i = 0; i < len; i++)
        {
            safe_data[safe_data_len++] = (unsigned)rand();
        }
    }
    safe_data_wput(safe_data_lock);
}

static unsigned _unsafe_data_browse(unsigned* start, void (*process)(unsigned index, unsigned value, unsigned long input), unsigned long input)
{
    unsigned delta = safe_data_len - *start;

    for (; *start < safe_data_len; (*start)++)
    {
        process(*start, safe_data[*start], input);
    }
    return delta;
}


unsigned safe_data_browse(unsigned* start, void (*process)(unsigned index, unsigned value, unsigned long input), unsigned long input)
{
    safe_data_rget(safe_data_lock, TX_WAIT_FOREVER);
    unsigned delta = _unsafe_data_browse(start, process, input);
    safe_data_rput(safe_data_lock);
    return delta;
}

static void _safe_data_unique_check(unsigned index, unsigned value, unsigned long input)
{
    for (unsigned i = 0; i < index; i++)
    {
        if (safe_data[i] == value)
            return;
    }
    safe_data_unique[safe_data_unique_len++] = index;
}

unsigned safe_data_unique_update()
{
    unsigned ret;

    safe_data_rget(safe_data_lock, TX_WAIT_FOREVER);
    safe_data_wget(safe_data_unique_lock, TX_WAIT_FOREVER);
    ret = _unsafe_data_browse(&safe_data_unique_last, _safe_data_unique_check, 0);
    safe_data_wput(safe_data_unique_lock);
    safe_data_rput(safe_data_lock);
    return ret;
}

int safe_data_unique_check(unsigned index)
{
    int res = 0;

    safe_data_rget(safe_data_unique_lock, TX_WAIT_FOREVER);
    {
        if (index < safe_data_unique_last)
            for (unsigned i = 0; !res && i<safe_data_unique_len; i++)
            {
                res = (safe_data_unique[i] == index);
            }
        else
            res = -1;
    }    
    safe_data_rput(safe_data_unique_lock);
    return res;
}
