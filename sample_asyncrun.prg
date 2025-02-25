SET PROCEDURE TO promises.prg

CLEAR
=RAND(SECONDS())

LOCAL i
FOR i = 1 TO 100
    WITH AsyncRun("MyAsyncFunc", m.i, MAX(INT(RAND() * 1000), 1), TEXTMERGE("AsyncFunc<<m.i>>: "))
        .then("MyPromiseThen")
    ENDWITH
ENDFOR

DEFINE CLASS MyAsyncFunc as Callable
    FUNCTION call(myIndex as Integer, cntMax as Integer, msg as String)
        RETURN AsyncRun("MyAsyncFuncNested", m.myIndex, m.cntMax, m.msg)
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyAsyncFuncNested as Callable
    FUNCTION call(myIndex as Integer, cntMax as Integer, msg as String)
        RETURN AsyncRun("MyAsyncFuncNestedNested", m.myIndex, m.cntMax, m.msg)
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyAsyncFuncNestedNested as Callable
    myIndex = 0
    cnt = 0
    FUNCTION call(myIndex as Integer, cntMax as Integer, msg as String)
        This.cnt = This.cnt + 1
        IF This.cnt != m.cntMax
            IF m.myIndex = 1 && repeat with delay
                RETURN AsyncRepeat(1)
            ELSE
                RETURN AsyncRepeat(0)
            ENDIF
        ENDIF

        RETURN m.msg + TEXTMERGE("counted to <<m.This.cnt>>")
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


