SET PROCEDURE TO promises.prg

CLEAR

WITH Promise("MyPromiseExecutorInterval")
    WITH .then("MyPromiseThen")
        WITH .then("MyPromiseThen")
            .then("MyPromiseThen")
        ENDWITH
    ENDWITH
    .then("MyPromiseThen")
ENDWITH

WITH Promise("MyPromiseExecutorTimeout")
    .then("MyPromiseThen")
ENDWITH

DEFINE CLASS MyPromiseExecutorInterval as Callable
    FUNCTION call(resolve as Callable, reject as Callable)
        WITH CREATEOBJECT("MyInterval")
            .SetInterval(10, m.resolve, 15, "Hello, Interval!")
        ENDWITH
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyPromiseExecutorTimeout as Callable
    FUNCTION call(resolve as Callable, reject as Callable)
        WITH CREATEOBJECT("MyTimeout")
            .SetTimeout(100, m.resolve, "Hello, Timeout!")
        ENDWITH
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyPromiseThen as Callable
    FUNCTION call(value)
        LOCAL res
        m.res = TRANSFORM(m.value) + " then " + SYS(2015)
        ? m.res
        RETURN m.res
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyInterval as IntervalCallable
    cnt = 0
    FUNCTION call(resolve as Callable, cntMax as Integer, msg as String)
        This.cnt = This.cnt + 1
        ? this.cnt
        IF This.cnt = m.cntMax
            m.resolve.call(m.msg)
            This.ClearInterval()
        ENDIF
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyTimeout as TimeoutCallable
    cnt = 0
    FUNCTION call(resolve as Callable, msg as String)
        This.cnt = This.cnt + 1
        ? this.cnt
        m.resolve.call(m.msg)
        This.ClearTimeout()
    ENDFUNC
ENDDEFINE
