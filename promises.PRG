* PROMISES (LIB)
* JS PROMISES IMPLEMENTATION FOR VFP
*
* AUTHOR : VICTOR ESPINA, DMITRY CHUNIKHIN
* VERSION: 1.2
*

*  Public API description:
*  
*  Callable (class)
*
*  Function object interface. 
*  Promise executors, then and catch handlers must be subclasses of Callable
*  USAGE: sample.prg
*  
*  
*  Promise (function)
*
*  RETURNS A NEW INSTANCE OF Promise CLASS
*  USAGE: sample.prg
* 
*   
*  Promise (class)
* 
*  JS PROMISE CONCEPT IMPLEMENTATION ON VFP.
*  USAGE: sample.prg
* 
*   
*  IntervalCallable (class)
* 
*  JS Interval CONCEPT IMPLEMENTATION ON VFP.
*  USAGE: sample.prg
* 
*   
*  TimeoutCallable (class)
* 
*  JS Timeout CONCEPT IMPLEMENTATION ON VFP.
*  USAGE: sample.prg
* 
*   
*  AsyncTask (class)
* 
*  ASYNC TASK CONCEPT IMPLEMENTATION ON VFP.
*  Properties:
*   - Promise: Promise object providing result of the AsyncTask execution
*  Methods:
*   - Start: start task in background (adds task to the Event Loop)
*   - Stop: stop task (removes task from the Event Loop)
*  AsyncTask constructor input:
*   - Callable object named Action as the first argument
*   - Arguments from 2 to 11: user's arbitrary arguments
*  Action's return types:
*   - result of AsyncRepeat() function call: Action will be executed one more time, AsyncTask.Promise will not be fulfilled
*   - Promise: AsyncTask.Promise will be resolved with resulting value of Promise returned by Action
*   - AsyncTask: Value of Promise property of returned AsyncTask 
*   - Exception: AsyncTask.Promise will be rejected with exception returned by Action of throwed by Action
*   - Any other value: AsyncTask.Promise will be resolved with the value returned by Action
*  USAGE: sample_asyncrun.prg
* 
* 
*  AsyncRun (function)
*  
*  RETURN NEW INSTANCE OF ASYNCTASK CLASS AND CALL ASYNCTASK.START BEFORE RETURN
*  Shortcut for 
*   with CREATEOBJECT("AsyncTask")
*      .Start()
*   endwith
*  USAGE: sample_asyncrun.prg
* 
*  
*  AsyncRepeat (function)
* 
*  Returned from Action routine of the AsyncTask, AsyncRepeat instructs the Event Loop to repeat this Action in a given number of milliseconds
*  AsyncRepeat input:
*   - repeat delay in milliseconds
*  USAGE: sample_asyncrun.prg



DEFINE CLASS Callable as Custom
    FUNCTION call
    ENDFUNC
ENDDEFINE

FUNCTION Promise(executor as Callable)
    RETURN CREATEOBJECT("Promise", m.executor)
ENDFUNC

DEFINE CLASS Promise AS Custom
    #define PENDING 1
    #define RESOLVED 2
    #define REJECTED 3

    HIDDEN _onResolved[1]
    HIDDEN _onRejected[1]
    HIDDEN _chainedPromises[1]
    HIDDEN _chainedPromisesCnt
    HIDDEN _state
    HIDDEN _data
    HIDDEN _hasData
    
    PROCEDURE Init(executor as Callable)
        This._state = PENDING
        This._data = NULL
        This._hasData = .F.
        This._chainedPromisesCnt = 0
        
        IF VARTYPE(m.executor) = "C" AND NOT EMPTY(m.executor)
            m.executor = CREATEOBJECT(m.executor)
        ENDIF
        IF VARTYPE(m.executor) = "O"
            m.executor.call(CREATEOBJECT("PromiseExecutorResolve", This), CREATEOBJECT("PromiseExecutorReject", This))
        ENDIF
    ENDPROC

    PROCEDURE resolve(value)
        IF PCOUNT() = 1
            This._callback(RESOLVED, m.value)
        ELSE
            This._callback(RESOLVED)
        ENDIF
    ENDPROC

    PROCEDURE reject(reason)
        IF PCOUNT() = 1
            This._callback(REJECTED, m.reason)
        ELSE
            This._callback(REJECTED)
        ENDIF
    ENDPROC

    PROCEDURE then(onResolved as Callable, onRejected as Callable)
        IF VARTYPE(m.onResolved) = "C" AND NOT EMPTY(m.onResolved)
            m.onResolved = CREATEOBJECT(m.onResolved)
        ENDIF
        IF VARTYPE(m.onRejected ) = "C" AND NOT EMPTY(m.onRejected)
            m.onRejected = CREATEOBJECT(m.onRejected)
        ENDIF
        
        This._chainedPromisesCnt = This._chainedPromisesCnt + 1
        DIMENSION This._onResolved(This._chainedPromisesCnt)
        DIMENSION This._onRejected(This._chainedPromisesCnt)
        DIMENSION This._chainedPromises(This._chainedPromisesCnt)
        This._onResolved[This._chainedPromisesCnt] = m.onResolved
        This._onRejected[This._chainedPromisesCnt] = m.onRejected
        
        LOCAL chainedPromise
        m.chainedPromise = CREATEOBJECT("Promise")
        This._chainedPromises[This._chainedPromisesCnt] = m.chainedPromise
        
        This._callback()
        
        RETURN m.chainedPromise
    ENDPROC

    PROCEDURE catch(onRejected as Callable)
        RETURN This.then(NULL, m.onRejected)
    ENDPROC

    HIDDEN PROCEDURE _callback(nextState, data)
        IF This._state = PENDING AND PCOUNT() > 0
            This._state = m.nextState
            IF PCOUNT() > 1
                This._hasData = .T.
                This._data = m.data
            ENDIF
        ENDIF
        
        DO CASE
        CASE This._state = RESOLVED
            LOCAL i
            FOR m.i = 1 TO This._chainedPromisesCnt
                LOCAL retVal
                m.retVal = NULL
                IF VARTYPE(This._onResolved[m.i]) = "O"
                    IF This._hasData
                        m.retVal = This._onResolved[m.i].call(This._data)
                    ELSE
                        m.retVal = This._onResolved[m.i].call()
                    ENDIF
                 ENDIF
                 This._chainedPromises[m.i].resolve(m.retVal)
            ENDFOR
            This.Cleanup()

        CASE This._state = REJECTED
            LOCAL i
            FOR m.i = 1 TO This._chainedPromisesCnt
                LOCAL retVal
                m.retVal = NULL
                IF VARTYPE(This._onRejected[m.i]) = "O"
                    IF This._hasData
                        m.retVal = This._onRejected[m.i].call(This._data)
                    ELSE
                        m.retVal = This._onRejected[m.i].call()
                    ENDIF
                 ENDIF
                 This._chainedPromises[m.i].reject(m.retVal)
            ENDFOR
            This.Cleanup()
        ENDCASE
    ENDPROC
    
    PROCEDURE Destroy
        This.Cleanup()
    ENDPROC
    
    HIDDEN PROCEDURE Cleanup
        This._chainedPromisesCnt = 0
        DIMENSION This._onResolved(1)
        DIMENSION This._onRejected(1)
        DIMENSION This._chainedPromises(1)
        STORE NULL TO This._onResolved, This._onRejected, This._chainedPromises
    ENDPROC
ENDDEFINE  && Promise


DEFINE CLASS PromiseExecutorResolve as Callable
    HIDDEN _promise
    
    PROCEDURE Init(promise as Promise)
        This._promise = m.promise
    ENDPROC
    
    FUNCTION call(value)
        IF PCOUNT() = 1
            This._promise.resolve(m.value)
        ELSE
            This._promise.resolve()
        ENDIF
    ENDFUNC
ENDDEFINE


DEFINE CLASS PromiseExecutorReject as Callable
    HIDDEN _promise
    
    PROCEDURE Init(promise as Promise)
        This._promise = m.promise
    ENDPROC

    FUNCTION call(reason)
        IF PCOUNT() = 1
            This._promise.reject(m.reason)
        ELSE
            This._promise.reject()
        ENDIF
    ENDFUNC
ENDDEFINE


* Timers
DEFINE CLASS IntervalCallable as Callable
    HIDDEN _IntervalID

    PROCEDURE SetInterval(delay as Integer, arg1, arg2, arg3, arg4, arg5)
        IF PEMSTATUS(_VFP, "_Intervals", 5) = .F.
            ADDPROPERTY(_VFP, "_Intervals")
        ENDIF
        IF VARTYPE(_VFP._Intervals) != "O"
            _VFP._Intervals = CREATEOBJECT("Collection")
        ENDIF
        
        This._IntervalID = INT(VAL(_VFP._Intervals.GetKey(_VFP._Intervals.Count))) + 1
        _VFP._Intervals.Add(;
            CREATEOBJECT("_PromisesTimer", .T., This, m.delay, MAX(PCOUNT() - 1, 0), m.arg1, m.arg2, m.arg3, m.arg4, m.arg5), ;
            TRANSFORM(This._IntervalID))
    ENDPROC

    PROCEDURE ClearInterval
        IF PEMSTATUS(_VFP, "_Intervals", 5) = .F.
            RETURN
        ENDIF
        IF VARTYPE(_VFP._Intervals) != "O"
            RETURN
        ENDIF
        LOCAL index
        m.index = _VFP._Intervals.GetKey(TRANSFORM(This._IntervalID))
        IF m.index > 0
            _VFP._Intervals.Remove(m.index)
        ENDIF
    ENDPROC
ENDDEFINE

DEFINE CLASS TimeoutCallable as Callable
    HIDDEN _TimeoutID

    PROCEDURE SetTimeout(delay as Integer, arg1, arg2, arg3, arg4, arg5)
        IF PEMSTATUS(_VFP, "_Timeouts", 5) = .F.
            ADDPROPERTY(_VFP, "_Timeouts", NULL)
        ENDIF
        IF VARTYPE(_VFP._Timeouts) != "O"
            _VFP._Timeouts = CREATEOBJECT("Collection")
        ENDIF
        
        This._TimeoutID = INT(VAL(_VFP._Timeouts.GetKey(_VFP._Timeouts.Count))) + 1
        _VFP._Timeouts.Add(;
            CREATEOBJECT("_PromisesTimer", .F., This, m.delay, MAX(PCOUNT() - 1, 0), m.arg1, m.arg2, m.arg3, m.arg4, m.arg5), ;
            TRANSFORM(This._TimeoutID))
    ENDPROC

    PROCEDURE ClearTimeout
        IF PEMSTATUS(_VFP, "_Timeouts", 5) = .F.
            RETURN
        ENDIF
        IF VARTYPE(_VFP._Timeouts) != "O"
            RETURN
        ENDIF
        LOCAL index
        m.index = _VFP._Timeouts.GetKey(TRANSFORM(This._TimeoutID))
        IF m.index > 0
            _VFP._Timeouts.Remove(m.index)
        ENDIF
    ENDPROC
ENDDEFINE


DEFINE CLASS _PromisesTimer as Timer
    Interval = 0
    Enabled = .F.
    HIDDEN _repeat
    HIDDEN _callback
    HIDDEN _callbackArgs[1]
    HIDDEN _callbackArgsCnt
    HIDDEN _callbackArgsMacro
    
    PROCEDURE Init(repeat as Boolean, func as Callable, interval as Integer, funcArgsCnt, funcArg1, funcArg2, funcArg3, funcArg4, funcArg5)
        This._repeat = m.repeat
        This._callback = m.func
        This.Interval = m.interval
        This._callbackArgsCnt = m.funcArgsCnt
        This._callbackArgsMacro = ""
        IF This._callbackArgsCnt > 0
            DIMENSION This._callbackArgs(This._callbackArgsCnt)
            LOCAL i
            FOR i = 1 TO This._callbackArgsCnt
                This._callbackArgs[m.i] = EVALUATE("m.funcArg" + TRANSFORM(m.i))
                This._callbackArgsMacro = This._callbackArgsMacro + IIF(m.i > 1, ",", "") + "This._callbackArgs[" + TRANSFORM(m.i) + "]"
            ENDFOR
        ENDIF
        This.Enabled = .T.
    ENDPROC
    
    PROCEDURE Timer
        This.Enabled = .F.
        LOCAL lcArgs
        m.lcArgs = This._callbackArgsMacro

        IF EMPTY(m.lcArgs)
            This._callback.call()
        ELSE
            This._callback.call(&lcArgs)
        ENDIF
        
        This.Enabled = This._repeat
    ENDPROC    
ENDDEFINE



* Async tasks & Event Loop

FUNCTION AsyncRun(action as Callable, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
    LOCAL lcArgs, lnArgs, i
    m.lcArgs = ""
    m.lnArgs = MAX(PCOUNT() - 1, 0)
    FOR i = 1 TO m.lnArgs
        m.lcArgs = m.lcArgs + IIF(EMPTY(m.lcArgs), "", ",") + "m.p" + TRANSFORM(m.i)
    ENDFOR

    LOCAL task
    IF m.lnArgs = 0
        m.task = CREATEOBJECT("AsyncTask", m.action)
    ELSE
        m.task = CREATEOBJECT("AsyncTask", m.action, &lcArgs)
    ENDIF
    m.task.Start()
    RETURN m.task
ENDFUNC

FUNCTION AsyncRepeat(delay)
    LOCAL repeat
    m.repeat = CREATEOBJECT("empty")
    ADDPROPERTY(m.repeat, "Class", "AsyncRepeat")
    ADDPROPERTY(m.repeat, "delay", MAX(EVL(m.delay,0),0))
    RETURN m.repeat
ENDFUNC


DEFINE CLASS AsyncTask as Custom
    HIDDEN _action
    HIDDEN _payload
    HIDDEN _payloadArgsMacro
    HIDDEN _promise
    Promise = NULL
    runTime = NULL
    runDelay = 0
    
    
    FUNCTION Promise_access
        RETURN This._promise
    ENDFUNC
    FUNCTION Promise_assing
        ERROR 1740, "promise"
    ENDFUNC
    
    
    PROCEDURE Init(action as Callable, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
        IF PEMSTATUS(_VFP, "_AsyncEventLoop", 5) = .F.
            ADDPROPERTY(_VFP, "_AsyncEventLoop", NULL)
        ENDIF
        IF VARTYPE(_VFP._AsyncEventLoop) != "O"
            _VFP._AsyncEventLoop = CREATEOBJECT("_AsyncEventLoop")
        ENDIF

        IF VARTYPE(m.action) = "C" AND NOT EMPTY(m.action)
            This._action = CREATEOBJECT(m.action)
        ELSE
            This._action = m.action
        ENDIF

        LOCAL payload, i
        m.payload = CREATEOBJECT("Empty")
        ADDPROPERTY(m.payload, "pcount", MAX(PCOUNT() - 1, 0))
        ADDPROPERTY(m.payload, "p[" + TRANSFORM(m.payload.pcount) + "]")
        This._payloadArgsMacro = ""
        FOR i = 1 TO m.payload.pcount
            m.payload.p[m.i] = EVALUATE("m.p" + TRANSFORM(m.i))
            This._payloadArgsMacro = This._payloadArgsMacro + IIF(m.i > 1, ",", "") + "This._payload.p[" + TRANSFORM(m.i) + "]"
        ENDFOR
        This._payload = m.payload
        
        This._promise = CREATEOBJECT("Promise")
    ENDPROC

    FUNCTION Start
        _VFP._AsyncEventLoop.AddTask(This)
    ENDFUNC
    
    FUNCTION Stop
        _VFP._AsyncEventLoop.StopTask(This)
    ENDFUNC
    
    FUNCTION RunAction
        LOCAL lcArgs, i
        m.lcArgs = This._payloadArgsMacro
        
        LOCAL repeat, res, err
        m.repeat = .F.
        TRY
            IF EMPTY(m.lcArgs)
                m.res = This._action.call()
            ELSE
                m.res = This._action.call(&lcArgs)
            ENDIF

            DO CASE
            CASE VARTYPE(m.res) = "O" AND VARTYPE(m.res.Class) = "C" AND LOWER(m.res.Class) == LOWER("AsyncRepeat")
                m.repeat = m.res

            CASE VARTYPE(m.res) = "O" AND VARTYPE(m.res.Class) = "C" AND LOWER(m.res.Class) == LOWER("AsyncTask")
                m.res.Promise.then(CREATEOBJECT("PromiseExecutorResolve", This._promise))
                m.res.Promise.catch(CREATEOBJECT("PromiseExecutorReject", This._promise))

            CASE VARTYPE(m.res) = "O" AND VARTYPE(m.res.Class) = "C" AND LOWER(m.res.Class) == LOWER("Promise")
                m.res.then(CREATEOBJECT("PromiseExecutorResolve", This._promise))
                m.res.catch(CREATEOBJECT("PromiseExecutorReject", This._promise))
                
            CASE VARTYPE(m.res) = "O" AND VARTYPE(m.res.BaseClass) = "C" AND LOWER(m.res.BaseClass) == LOWER("Exception")
                This._promise.reject(m.res)

            OTHERWISE
                This._promise.resolve(m.res)
            ENDCASE
        CATCH TO err
            This._promise.reject(m.err)
        ENDTRY
        
        RETURN m.repeat
    ENDFUNC
    
ENDDEFINE


DEFINE CLASS _AsyncEventLoop as Timer
    Interval = 1
    HIDDEN _tasks[1]
    HIDDEN _tasksCnt
    HIDDEN _tasksInd
    HIDDEN _tasksPending[1]
    HIDDEN _tasksPendingCnt
    HIDDEN nWndMsg
    
    PROCEDURE Init
        This._tasksCnt = 0
        This._tasksInd = 1
        This._tasksPendingCnt = 0
        
        DECLARE LONG RegisterWindowMessage IN user32 AS WinApi_RegisterWindowMessage STRING lpString
        This.nWndMsg = WinApi_RegisterWindowMessage("WM_AsyncEventLoop")
        IF EMPTY(This.nWndMsg)
            RETURN .F.
        ENDIF
        BINDEVENT(_VFP.HWnd, This.nWndMsg, This, "OnNextTask")
        
        DECLARE LONG GetTickCount IN kernel32 AS WinApi_GetTickCount
    ENDPROC
    
    PROCEDURE Destroy
        This._tasksCnt = 0
        DIMENSION This._tasks(1)
        This._tasks[1] = NULL

        This._tasksPendingCnt = 0
        DIMENSION This._tasksPending(1)
        This._tasksPending[1] = NULL
    ENDPROC
    
    PROCEDURE AddTask(task as AsyncTask)
        This._tasksCnt = This._tasksCnt + 1
        DIMENSION This._tasks(This._tasksCnt)
        This._tasks[This._tasksCnt] = m.task
        This.InvokeNextTask()
    ENDPROC

    PROCEDURE AddTaskPending(task as AsyncTask)
        This._tasksPendingCnt = This._tasksPendingCnt + 1
        DIMENSION This._tasksPending(This._tasksPendingCnt)
        This._tasksPending[This._tasksPendingCnt] = m.task
        This.InvokeNextTask()
    ENDPROC

    PROCEDURE StopTask(task as AsyncTask)
        LOCAL lSaveEnabled
        m.lSaveEnabled = This.Enabled
        This.Enabled = .F.
        LOCAL ind, m.itask
        FOR m.ind = This._tasksInd TO This._tasksCnt
            m.itask = This._tasks[m.ind]
            IF VARTYPE(m.itask) != "O"
                LOOP
            ENDIF
            IF m.itask != m.task
                LOOP
            ENDIF

            This._tasks[m.ind] = NULL
            This._tasksInd = This._tasksInd + 1
            EXIT
        ENDFOR

        FOR m.ind = 1 TO This._tasksPendingCnt
            m.itask = This._tasksPending[m.ind]
            IF VARTYPE(m.itask) != "O"
                LOOP
            ENDIF
            IF m.itask != m.task
                LOOP
            ENDIF

            This._tasksPendingCnt = This._tasksPendingCnt - 1
            ADEL(This._tasksPending, m.ind)
            EXIT
        ENDFOR
        This.Enabled = m.lSaveEnabled
    ENDPROC
    
    PROCEDURE Timer
        This.InvokeNextTask(.T.)
    ENDPROC

    PROCEDURE InvokeNextTask(force)
        #define SLEEP_MAX 2
        #define WND_QUE_FLAGS 0x0001 + 0x0002 + 0x0004 + 0x0020 + 0x0080 + 0x0400
        
        This.Enabled = .F.
                
        LOCAL wndQS
        TRY
            m.wndQS = WinApi_GetQueueStatus(WND_QUE_FLAGS)
        CATCH
            DECLARE LONG GetQueueStatus IN user32 AS WinApi_GetQueueStatus LONG flags
            m.wndQS = WinApi_GetQueueStatus(WND_QUE_FLAGS)
        ENDTRY

        IF m.wndQS != 0
            This.Interval = MAX(This.Interval + 1, SLEEP_MAX)
            IF This.Interval < SLEEP_MAX OR m.force = .F.
                This.Enabled = (This._tasksCnt > 0)
                RETURN
            ENDIF
        ENDIF

        This.Interval = 0

        TRY
            WinApi_PostMessage(_VFP.HWnd, This.nWndMsg, 0, 0)
        CATCH
        FINALLY
            DECLARE LONG PostMessage IN user32 AS WinApi_PostMessage LONG hWnd, LONG Msg, LONG wParam, LONG lParam
            WinApi_PostMessage(_VFP.HWnd, This.nWndMsg, 0, 0)
        ENDTRY
    ENDPROC

    PROCEDURE OnNextTask
        LPARAMETERS hWnd, Msg, wParam, lParam

        IF This._tasksInd > This._tasksCnt
            IF This._tasksPendingCnt = 0
                RETURN
            ENDIF
            DIMENSION This._tasks(MAX(This._tasksCnt, This._tasksPendingCnt))
            This._tasksCnt = This._tasksPendingCnt
            ACOPY(This._tasksPending, This._tasks, 1, This._tasksPendingCnt)
            DIMENSION This._tasksPending(1)
            This._tasksPending[1] = NULL
            DIMENSION This._tasksPending(This._tasksPendingCnt)
            This._tasksInd = 1
            This._tasksPendingCnt = 0
        ENDIF
                
        LOCAL task, repeat
        m.task = This._tasks[This._tasksInd]
        This._tasks[This._tasksInd] = NULL
        This._tasksInd = This._tasksInd + 1
        
        IF m.task.runDelay > 0 AND m.task.runDelay > (WinApi_GetTickCount() - NVL(m.task.runTime, 0))
            This.AddTaskPending(m.task)
        ELSE
            m.repeat = m.task.RunAction()
            
            IF VARTYPE(m.repeat) = "O"
                m.task.runTime = WinApi_GetTickCount()
                m.task.runDelay = m.repeat.delay
                This.AddTaskPending(m.task)
            ENDIF
        ENDIF
    ENDPROC
    
ENDDEFINE
