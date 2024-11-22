#ifndef SAFE_DATA_H
#define SAFE_DATA_H
          
#ifndef SAFE_DATA_SIZE
#define SAFE_DATA_SIZE    2048
#endif

/**
 * Initialize safe data structure with no initial value.
 * @retval TX_SUCCESS (0x00) Successful read/write lock creation.
 * @retval TX_SEMAPHORE_ERROR (0x0C) Invalid internal semaphore pointer. Either the pointer is NULL or the semaphore is already created.
 * @retval TX_MUTEX_ERROR (0x1C) Invalid internal mutex pointer. Either the pointer is NULL or the mutex is already created.
 * @retval TX_INHERIT_ERROR (0x1F) Invalid priority inheritance parameter.
 * @retval TX_CALLER_ERROR (0x13) Invalid caller of this service.
 */
unsigned safe_data_init();

/**
 * Free all resources used by the safe data structure.
 */
void safe_data_shut();

/**
 * Empty safe data.
 */
void safe_data_clear();
   
/**
 * Protect safe data accesses using mutexes.
 */
void safe_data_use_mutex();

/**
 * Protect safe data accesses using R/W locks.
 */
void safe_data_use_rwlock();

/**
 * Add a specific number of random values to the safe data.
 * @param Number of value to add
 */
void safe_data_fill_random(unsigned length);

unsigned safe_data_browse(unsigned* start, void (*process)(unsigned index, unsigned value, unsigned long input), unsigned long input);
/**
 * Browse safe data using the process function.
 * @param[in,out] start Pointer to the index of the starting position. Updated after browsing.
 * @param[in] process Callback function called for each available value.
 * @param[in] input User-defined input passed to the process function.
 * @return Number of values processed during browsing.
 */
unsigned safe_data_browse(unsigned* start, void (*process)(unsigned index, unsigned value, unsigned long input), unsigned long input);

/**
 * Update the unique values index from the recently added values.
 * @return number of values checked
 */
unsigned safe_data_unique_update(); 

/**
 * Checks if a value at the specified index is unique in the safe data structure.
 * @param[in] index Index of the value to check.
 * @retval -1 Uniqueness is unknown (new values were recently added and safe_data_unique_update() has not been called).
 * @retval 0 Value at this index is not unique.
 * @retval 1 Value at this index is unique.
 * @see safe_data_unique_update
 */
int safe_data_unique_check(unsigned index); 

#endif
