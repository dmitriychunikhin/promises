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
*  FunCall (function)
*
*  Callable wrapper for any VFP function or method
*  FunCall allows up to 10 arguments to be passed to underlying function|method
*  FunCall input:
*   - funcName as String: name of the function or method
*        method name must by provided in a This.methodName pattern
*   - thisObj as Object: "This" binding for method
*  FunCall return value: Callable object
*  USAGE: sample_asynchttp.prg
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
*  AsyncRun (function)
* 
*  JS ASYNC FUNCTION CONCEPT IMPLEMENTATION ON VFP.
*  AsyncRun input:
*   - Callable object named Action as the first argument
*   - Arguments from 2 to 11: user's arbitrary arguments
*  AsyncRun return value: Promise object. To stop async procedure execution just release the Promise returned by AsyncRun
*  Action's return types:
*   - return value of AsyncRepeat() function: Action will be executed one more time, Promise will not be fulfilled
*   - Promise: Promise returned by AsyncRun will be resolved with resulting value of Promise returned by Action
*              If Promise is returned from AsyncRun() it will be fulfilled automatically, otherwise it is up to creator to fulfill the Promise
*   - Exception: Promise returned by AsyncRun will be rejected with exception returned by Action of throwed by Action
*   - Any other value: Promise returned by AsyncRun will be resolved with a value returned by Action
*  USAGE: sample_asyncrun.prg
* 
*   
*  AsyncRepeat (function)
* 
*  Returned from Action routine of AsyncRun AsyncRepeat instructs Event Loop to repeat Action in a given number of milliseconds
*  AsyncRun input:
*   - repeat delay in milliseconds
*  USAGE: sample_asyncrun.prg



DEFINE CLASS Callable as Custom
    FUNCTION call
    ENDFUNC
ENDDEFINE

FUNCTION FunCall(funcName as String, thisObj as Object)
    RETURN CREATEOBJECT("FunCall", m.funcName, m.thisObj)
ENDFUNC

DEFINE CLASS FunCall as Callable
    HIDDEN _funcName
    HIDDEN _thisObj
    
    PROCEDURE Init(funcName as String, thisObj as Object)
        This._funcName = m.funcName
        This._thisObj = m.thisObj
    ENDPROC
    
    FUNCTION call(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
        LOCAL funcName, thisObj, pcount
        m.funcName = STRTRAN(This._funcName, "This.", "m.thisObj.", 1, 1, 1)
        m.thisObj = This._thisObj
        m.pcount = PCOUNT()
        DO CASE
        CASE m.pcount = 0
            RETURN &funcName()
        CASE m.pcount = 1
            RETURN &funcName(m.p1)
        CASE m.pcount = 2
            RETURN &funcName(m.p1, m.p2)
        CASE m.pcount = 3
            RETURN &funcName(m.p1, m.p2, m.p3)
        CASE m.pcount = 4
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4)
        CASE m.pcount = 5
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5)
        CASE m.pcount = 6
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5, m.p6)
        CASE m.pcount = 7
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5, m.p6, m.p7)
        CASE m.pcount = 8
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5, m.p6, m.p7, m.p8)
        CASE m.pcount = 9
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5, m.p6, m.p7, m.p8, m.p9)
        CASE m.pcount = 10
            RETURN &funcName(m.p1, m.p2, m.p3, m.p4, m.p5, m.p6, m.p7, m.p8, m.p9, m.p10)
        ENDCASE
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
    LOCAL payload, i
    m.payload = CREATEOBJECT("Empty")
    ADDPROPERTY(m.payload, "pcount", MAX(PCOUNT() - 1, 0))
    ADDPROPERTY(m.payload, "p[" + TRANSFORM(EVL(m.payload.pcount,1)) + "]")
    ADDPROPERTY(m.payload, "pMacro", "")
    FOR i = 1 TO m.payload.pcount
        m.payload.p[m.i] = EVALUATE("m.p" + TRANSFORM(m.i))
        m.payload.pMacro = m.payload.pMacro + IIF(m.i > 1, ",", "") + "This._payload.p[" + TRANSFORM(m.i) + "]"
    ENDFOR

    RETURN CREATEOBJECT("_AsyncRunPromise", m.action, m.payload) 
ENDFUNC

FUNCTION AsyncRepeat(delay)
    LOCAL repeat
    m.repeat = CREATEOBJECT("empty")
    ADDPROPERTY(m.repeat, "Class", "AsyncRepeat")
    ADDPROPERTY(m.repeat, "delay", MAX(EVL(m.delay,0),0))
    RETURN m.repeat
ENDFUNC


DEFINE CLASS _AsyncRunPromise as Custom
    HIDDEN _promise
    HIDDEN _task
    
    PROCEDURE Init(action as Callable, payload as Object)
        IF PEMSTATUS(_VFP, "_AsyncEventLoop", 5) = .F.
            ADDPROPERTY(_VFP, "_AsyncEventLoop", NULL)
        ENDIF
        IF VARTYPE(_VFP._AsyncEventLoop) != "O"
            _VFP._AsyncEventLoop = CREATEOBJECT("_AsyncEventLoop")
        ENDIF
        
        This._promise = Promise()
        This._task = CREATEOBJECT("_AsyncTask", m.action, m.payload, This._promise)
        
        _VFP._AsyncEventLoop.AddTask(This._task)
    ENDPROC
    
    PROCEDURE Destroy
        IF PEMSTATUS(_VFP, "_AsyncEventLoop", 5) = .F.
            RETURN
        ENDIF
        IF VARTYPE(_VFP._AsyncEventLoop) != "O"
            RETURN
        ENDIF
        IF VARTYPE(This._task) = "O"
            _VFP._AsyncEventLoop.RemoveTaskById(This._task._taskId)
        ENDIF
    ENDPROC
    
    PROCEDURE THIS_ACCESS(member)
        IF INLIST(LOWER(m.member), "_promise", "_task")
            RETURN This
        ENDIF
        RETURN This._promise
    ENDPROC
ENDDEFINE


DEFINE CLASS _AsyncTask as Callable
    _taskId = ""
    _runTime = NULL
    _runDelay = 0

    HIDDEN _action
    HIDDEN _payload
    HIDDEN _promise
    HIDDEN _actionPromise
    
    PROCEDURE Init(action as Callable, payload as Object, promise as Promise)        
        IF VARTYPE(m.action) = "C" AND NOT EMPTY(m.action)
            This._action = CREATEOBJECT(m.action)
        ELSE
            This._action = m.action
        ENDIF
        This._payload = m.payload
        This._promise = m.promise
        This._taskId = SYS(2015)
    ENDPROC
    
    FUNCTION RunAction
        LOCAL lcArgs
        m.lcArgs = This._payload.pMacro

        This._actionPromise = NULL

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

            CASE VARTYPE(m.res) = "O" AND VARTYPE(m.res.Class) = "C" AND LOWER(m.res.Class) == LOWER("Promise")
                m.res.then(CREATEOBJECT("PromiseExecutorResolve", This._promise))
                m.res.catch(CREATEOBJECT("PromiseExecutorReject", This._promise))
                This._actionPromise = m.res &&hold ref to action promise to protect nested task from being destroyed after exit from this method

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


DEFINE CLASS _AsyncEventLoop as Custom
    HIDDEN nEventLoopWndMsg
    HIDDEN _tasks
    
    PROCEDURE Init
        This._tasks = CREATEOBJECT("Collection")

        LOCAL lcAppPath, lcAppFolder
        m.lcAppPath = STREXTRACT(SYS(16), " ", "", 2, 2)
        m.lcAppFolder = JUSTPATH(m.lcAppPath)
        
        SET LIBRARY TO &lcAppFolder\promises.fll ADDITIVE
        
        This.nEventLoopWndMsg = PromisesLib_Init(_VFP.HWnd)
        IF EMPTY(This.nEventLoopWndMsg)
            RETURN .F.
        ENDIF
        BINDEVENT(_VFP.HWnd, This.nEventLoopWndMsg, This, "RunTask", 4)
    ENDPROC
    
    PROCEDURE Destroy
        LOCAL lcAppPath, lcAppFolder
        m.lcAppPath = STREXTRACT(SYS(16), " ", "", 2, 2)
        m.lcAppFolder = JUSTPATH(m.lcAppPath)

        RELEASE LIBRARY &lcAppFolder\promises.fll
    ENDPROC
    
    PROCEDURE AddTask(task as _AsyncTask)
        This._tasks.Add(m.task, m.task._taskId)
        PromisesLib_EventLoopContinue()
    ENDPROC

    PROCEDURE RemoveTask(ind)
        This._tasks.Remove(m.ind)
    ENDPROC

    PROCEDURE RemoveTaskById(taskId)
        LOCAL ind
        m.ind = This._tasks.GetKey(m.taskId)
        IF m.ind > 0
            This._tasks.Remove(m.ind)
        ENDIF
    ENDPROC

    PROCEDURE RunTask
        LPARAMETERS hWnd, Msg, wParam, lParam

        IF This._tasks.Count = 0
            PromisesLib_EventLoopPause()
            RETURN
        ENDIF
        
        LOCAL task, repeat
        m.task = This._tasks.Item(1)
        This.RemoveTask(1)
        
        IF m.task._runDelay > 0 AND m.task._runDelay > (PromisesLib_GetTickCount() - NVL(m.task._runTime, 0))
            This.AddTask(m.task)
        ELSE
            m.repeat = m.task.RunAction()
            
            IF VARTYPE(m.repeat) = "O" 
                m.task._runTime = PromisesLib_GetTickCount()
                m.task._runDelay = m.repeat.delay
                This.AddTask(m.task)
            ENDIF
        ENDIF
    ENDPROC
    
ENDDEFINE
