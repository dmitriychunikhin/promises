* PROMISES (LIB)
* JS PROMISES IMPLEMENTATION FOR VFP
*
* AUTHOR : VICTOR ESPINA, DMITRY CHUNIKHIN
* VERSION: 1.1
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
            m.executor.call(CREATEOBJECT("_PromiseExecutorResolve", This), CREATEOBJECT("_PromiseExecutorReject", This))
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


DEFINE CLASS _PromiseExecutorResolve as Callable
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


DEFINE CLASS _PromiseExecutorReject as Callable
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
    
    PROCEDURE Init(repeat as Boolean, func as Callable, interval as Integer, funcArgsCnt, funcArg1, funcArg2, funcArg3, funcArg4, funcArg5)
        This._repeat = m.repeat
        This._callback = m.func
        This.Interval = m.interval
        This._callbackArgsCnt = m.funcArgsCnt
        IF This._callbackArgsCnt > 0
            DIMENSION This._callbackArgs(This._callbackArgsCnt)
            LOCAL i
            FOR i = 1 TO This._callbackArgsCnt
                This._callbackArgs[m.i] = EVALUATE("m.funcArg" + TRANSFORM(m.i))
            ENDFOR
        ENDIF
        This.Enabled = .T.
    ENDPROC
    
    PROCEDURE Timer
        This.Enabled = .F.
        LOCAL lcArgs
        m.lcArgs = ""
        LOCAL i
        FOR i = 1 TO This._callbackArgsCnt
            m.lcArgs = m.lcArgs + IIF(m.i > 1, ",", "") + "This._callbackArgs[" + TRANSFORM(m.i) + "]"
        ENDFOR

        IF EMPTY(m.lcArgs)
            This._callback.call()
        ELSE
            This._callback.call(&lcArgs)
        ENDIF
        
        This.Enabled = This._repeat
    ENDPROC    
ENDDEFINE
