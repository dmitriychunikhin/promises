* PROMISES (LIB)
* JS PROMISES LOOESLY IMPLEMENTATION FOR VFP
*
* AUTHOR : VICTOR ESPINA
* VERSION: 1.0
*

*
*  Promise (class)
*
*  PROMISE CONCEPT IMPLEMENTATION ON VFP. USAGE:
*
*  1) AN ASYNC PROCESS CREATES AND RETURNS A PROMISE
*     OBJECT BACK TO THE CALLER:
*
*     LOCAL oPromise
*     oPromise = CREATE("Promise")
*     RETURN oPromise
*
*  b) CALLER INVOKE THE ASYNC PROCESS AND RECEIVES
*     THE PROMISE, CONFIGURING THE CALLBACKS FOR
*     HANDLING AN OK RESPONSE OR AN ERROR RESPONSE:
*
*     LOCAL oPromise
*     oPromise = myAsyncProc()
*     oPromise.Then("procedureToBeCalled")
*     oPromise.Catch("instance.methodToBeCalled")
*
*  c) ASYNC PROCESS CALL RESOLVE OR REJECT METHODS ON
*     THE PROMISE AT SOME POINT:
*
*     oPromise.Resolve(puData) -> procedureToBeCalled(puData)
*     oPromise.Reject(puData) -> instance.methodToBeCalled(puData)
*
DEFINE CLASS Promise AS Custom

	HIDDEN _thenHandler
	HIDDEN _catchHandler
	HIDDEN _timeoutHandler
	HIDDEN _oTimeoutTimer
	HIDDEN _oAsyncTimer
	HIDDEN _Data
	HIDDEN _HasData
	HIDDEN _calledback
	HIDDEN _callbackEvent
	resolved = .F.
	
	
	PROCEDURE Init
		LPARAMETERS pcName
		pcName = EVL(pcName, "Promise_" + SYS(2015))
		THIS.Name = LOWER(pcName)
		THIS._Data = NULL
		THIS._HasData = .F.
		THIS._calledback = .F.
		PUBLIC (pcName)
		STORE THIS TO (pcName)
		RETURN

	PROCEDURE Resolve(puData)
	    IF PCOUNT() = 1
			THIS._callback("resolve", puData)
		ELSE
			THIS._callback("resolve")
		ENDIF
		RETURN
	
	PROCEDURE Reject(puErr)
	    IF PCOUNT() = 1
			THIS._callback("reject", puData)
		ELSE
			THIS._callback("reject")
		ENDIF
		RETURN
		
	PROCEDURE Timedout()
	    THIS._oTimeoutTimer.Enabled = .F.	
	    IF PCOUNT() = 1
			THIS._callback("timedout", puData)
		ELSE
			THIS._callback("timedout")
		ENDIF
		RETURN

	PROCEDURE Then(pcHandler)
		THIS._thenHandler = pcHandler
		IF THIS.Resolved AND !THIS._calledback 
			THIS._callBack("resolve")
		ENDIF
		RETURN
	
	PROCEDURE Catch(pcHandler)
		THIS._catchHandler = pcHandler
		IF THIS.Resolved AND !THIS._calledback 
			THIS._callBack("reject")
		ENDIF
		RETURN

	PROCEDURE Timeout(pcHandler)
		THIS._timeoutHandler = pcHandler
		IF THIS.Resolved AND !THIS._calledback 
			THIS._callBack("timedout")
		ENDIF
		RETURN		
		
    PROCEDURE setTimeout(pnSecs)
    	THIS._oTimeoutTimer = CREATEOBJECT("Timer")
    	WITH THIS._oTimeoutTimer
    		.Enabled = .F.
    		.Interval = pnSecs * 1000
    	ENDWITH
    	BINDEVENT(THIS._oTimeoutTimer, "Timer", THIS, "Timedout")
    	THIS._oTimeoutTimer.Enabled = .T.
    	RETURN
    	
    	
    PROCEDURE asyncRun(pcCallback, pnSecs)    
    	THIS._oAsyncTimer = CREATEOBJECT("Timer")
    	WITH THIS._oAsyncTimer
    		.Enabled = .F.
    		.Interval = EVL(pnSecs,1) * 1000
    		.addProperty("callback", pcCallback)
    	ENDWITH	
    	BINDEVENT(THIS._oAsyncTimer, "Timer", THIS, "_asyncRun")
    	THIS._oAsyncTimer.Enabled = .T.
    	RETURN
    	
    	
    PROCEDURE _asyncRun        
    	LOCAL cCallback
    	cCallback = THIS._oAsyncTimer.callback
    	THIS._oAsyncTimer.Enabled = .F.
    	UNBINDEVENT(THIS._oAsyncTimer, "Timer", THIS, "_asyncRun")
    	THIS._oAsyncTimer = NULL
    	EVALUATE(cCallback)
    	RETURN	
    	
		
	HIDDEN PROCEDURE _callback
		PARAMETERS pcEvent, puData
		IF THIS.Resolved AND !THIS._calledBack AND pcEvent <> THIS._callbackEvent
			RETURN
		ENDIF
		IF PCOUNT() = 1 AND THIS._HasData
			puData = THIS._Data
		ELSE
			THIS._hasData = (PCOUNT() > 1)		
		ENDIF
		LOCAL cHandler
		cHandler = THIS._getEventHandler(pcEvent)
		IF NOT EMPTY(cHandler)
			LOCAL cCmd
			cCmd = cHandler
			IF AT("(",cHandler) = 0
				cCmd = cHandler + "(" + IIF(THIS._hasData,"puData","") + ")"
			ENDIF
			STORE NULL TO (THIS.Name)
			THIS._calledback = .T.
			EVALUATE(cCmd)
		ELSE
			IF THIS._HasData
				THIS._Data = puData
			ENDIF
			THIS._callBackEvent = pcEvent
		ENDIF
		THIS.Resolved = .T.
		RETURN		


	HIDDEN PROCEDURE _getEventHandler(pcEvent)
		LOCAL cHandler
		DO CASE
	       CASE pcEvent == "resolve"
	       	    cHandler = THIS._thenHandler

	       CASE pcEvent == "reject"
	       	    cHandler = THIS._catchHandler

	       CASE pcEVent == "timedout"
	       	    cHandler = THIS._timeoutHandler
		ENDCASE
		RETURN cHandler
		
ENDDEFINE  && Promise



*
*  Promise (function)
*
*  RETURNS A NEW INSTANCE OF Promise CLASS
*
FUNCTION Promise(pcName)
    LOCAL oPromise
    oPromise = CREATEOBJECT("Promise", pcName)
    RETURN oPromise




