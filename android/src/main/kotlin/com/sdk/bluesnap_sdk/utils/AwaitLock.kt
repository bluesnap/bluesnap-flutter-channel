package com.sdk.bluesnap_sdk.utils

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking


class AwaitLock() {
    private var isLocked: Boolean = false
    private var result: Any? = null
    private lateinit var timeOut: Job


    suspend fun startLock(timeoutSeconds: Long?) = CoroutineScope(Dispatchers.Main).launch {
        isLocked = true;
        if (timeoutSeconds != null && timeoutSeconds != 0L) {
            timeOut = launch (Dispatchers.Default) {
                delay(timeoutSeconds * 1000L)
                isLocked = false
            }
        }
    }

    suspend fun <T> stopLock(withResult: T?) {
        this.isLocked = false;
        this.timeOut.cancelAndJoin()

        if(withResult != null) {
            this.result = withResult
        }
    }

    tailrec suspend fun awaitLock(): Any? {
        delay(1000)
        return if (isLocked) {
            awaitLock()
        } else {
            result
        }
    }

}
