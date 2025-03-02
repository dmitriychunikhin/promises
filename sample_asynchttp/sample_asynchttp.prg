#define SAMPLE_URL "https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
#define SAMPLE_URL "https://www.google.com/"

CLEAR
SET CLASSLIB TO
SET PROCEDURE TO ..\promises.prg
SET CLASSLIB TO "async_progressbar.vcx" ADDITIVE

IF MESSAGEBOX("Do you want to download file from " + SAMPLE_URL, 4+32+256, "HTTP download") = 7
    RETURN
ENDIF
PUBLIC goDownloadForm
goDownloadForm = CREATEOBJECT("MyDownloadForm")
goDownloadForm.Show()
goDownloadForm.StartDownload()


DEFINE CLASS MyDownloadForm as async_progressbar_frm
    
    fetchPromise = NULL
    Caption = "HTTP download"
    
    FUNCTION StartDownload
        This.fetchPromise = fetch(SAMPLE_URL, NULL, FunCall("This.onProgress", This))
        This.fetchPromise.then(FunCall("This.onFinish", This))
        This.fetchPromise.catch(FunCall("This.onError", This))
    ENDFUNC
    
    FUNCTION StopDownload
        This.fetchPromise = NULL
    ENDFUNC
    
    FUNCTION onProgress(readyState)
        Thisform.cpbarcaption = ICASE(m.readyState = 3, 'Loading...', m.readyState = 4, 'Request is Completed', '')
        Thisform.npbarvalue = EVL(Thisform.npbarvalue,0) + 1
        IF m.readyState = 3 AND Thisform.npbarvalue >= 100
            Thisform.npbarvalue = 1
        ENDIF
        IF m.readyState = 4
            Thisform.npbarvalue = 100
        ENDIF
        Thisform.UpdateState()
    ENDFUNC

    FUNCTION onFinish(statusText)
        Thisform.cpbarcaption = "Download is completed with statusText: " + NVL(m.statusText,"")
        Thisform.npbarvalue = 100
        Thisform.UpdateState()
    ENDFUNC

    FUNCTION onError(err)
        Thisform.cpbarcaption = "Error: " + NVL(m.err.UserValue,'') + " " + NVL(m.err.details,'')
        Thisform.npbarvalue = 0
        Thisform.UpdateState()
    ENDFUNC
    
    FUNCTION Destroy
        This.StopDownload()
    ENDFUNC
    
ENDDEFINE


#define HTTP_UNSENT             0
#define HTTP_OPENED             1
#define HTTP_HEADERS_RECEIVED   2
#define HTTP_LOADING            3
#define HTTP_DONE               4
#define HTTP_STATUS_OK          200

FUNCTION fetch(url, requestParams, onProgress as Callable)
    RETURN AsyncRun("fetch", m.url, m.requestParams, m.onProgress)
ENDFUNC

DEFINE CLASS fetch as Callable
    FUNCTION call(url, requestParams, onProgress as Callable)
        LOCAL xmlHTTP
        m.xmlHTTP = CREATEOBJECT("Microsoft.XMLHTTP")
        m.xmlHTTP.Open("GET", m.url, .T.)
        IF m.xmlHTTP.readyState != HTTP_OPENED
            THROW "The request could not be initialized"
        ENDIF
        
        m.xmlHTTP.SetRequestHeader("Cache-Control", "no-cache")
        declare integer DeleteUrlCacheEntry in WinInet.DLL string
        DeleteUrlCacheEntry(m.url)
        
        m.xmlHTTP.Send()

        RETURN AsyncRun("FetchResultProcessor", m.xmlHTTP, onProgress)
    ENDFUNC
ENDDEFINE

DEFINE CLASS FetchResultProcessor as Callable
    HIDDEN xmlHTTP
    FUNCTION call(xmlHTTP, onProgress as Callable)
        IF VARTYPE(This.xmlHTTP) != "O"
            This.xmlHTTP = m.xmlHTTP
        ENDIF
        IF m.xmlHTTP.readyState != HTTP_DONE
            IF VARTYPE(m.onProgress) = "O"
                m.onProgress.call(m.xmlHTTP.readyState)
            ENDIF
            RETURN AsyncRepeat(100)
        ENDIF
        
        IF m.xmlHTTP.Status != HTTP_STATUS_OK
            THROW TEXTMERGE("Request ended with error status = <<m.xmlHTTP.Status>>")
        ENDIF
        
        RETURN m.xmlHTTP.StatusText
    ENDFUNC
    
    FUNCTION destroy
        IF VARTYPE(This.xmlHTTP) = "O" AND NOT INLIST(This.xmlHTTP.readyState, HTTP_UNSENT, HTTP_DONE)
            This.xmlHTTP.abort()
        ENDIF
    ENDFUNC
ENDDEFINE
