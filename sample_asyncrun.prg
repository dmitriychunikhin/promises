SET PROCEDURE TO promises.prg

CLEAR
=RAND(SECONDS())

LOCAL i
FOR i = 1 TO 100
    WITH AsyncRun("MyAsyncFunc", MAX(INT(RAND() * 5000), 1), TEXTMERGE("AsyncFunc<<m.i>>: "))
        .then("MyPromiseThen")
    ENDWITH
ENDFOR

DEFINE CLASS MyAsyncFunc as Callable
    FUNCTION call(cntMax as Integer, msg as String)
        RETURN AsyncRun("MyAsyncFuncNested", m.cntMax, m.msg)
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyAsyncFuncNested as Callable
    FUNCTION call(cntMax as Integer, msg as String)
        RETURN AsyncRun("MyAsyncFuncNestedNested", m.cntMax, m.msg)
    ENDFUNC
ENDDEFINE

DEFINE CLASS MyAsyncFuncNestedNested as Callable
    cnt = 0
    FUNCTION call(cntMax as Integer, msg as String)
        This.cnt = This.cnt + 1
        IF This.cnt != m.cntMax
            RETURN AsyncRepeat()
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
