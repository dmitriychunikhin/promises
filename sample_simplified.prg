SET PROCEDURE TO promises.prg

CLEAR

* Interval
WITH CREATEOBJECT("MyInterval")
    .promise = Promise()
    .SetInterval(10, 15, "Hello, Interval!")

    WITH .promise
        WITH .then(CREATEOBJECT("MyPromiseThen"))
            WITH .then("MyPromiseThen")
                .then(CREATEOBJECT("MyPromiseThen"))
            ENDWITH
        ENDWITH
        .then(CREATEOBJECT("MyPromiseThen"))
    ENDWITH
ENDWITH


* Timeout
WITH CREATEOBJECT("MyTimeout")
    .promise = Promise()
    .SetTimeout(100, "Hello, Timeout!")
    
    WITH .promise.then("MyPromiseThen")
        .then("MyPromiseThen")
    ENDWITH
ENDWITH


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
    promise = NULL
    FUNCTION call(cntMax as Integer, msg as String)
        This.cnt = This.cnt + 1
        ? this.cnt
        IF This.cnt = m.cntMax
            This.promise.resolve(m.msg)
            This.ClearInterval()
        ENDIF
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyTimeout as TimeoutCallable
    promise = NULL
    FUNCTION call(msg as String)
        This.promise.resolve(m.msg)
        This.ClearTimeout()
    ENDFUNC
ENDDEFINE
