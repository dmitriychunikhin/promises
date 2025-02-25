#include <pro_ext.h>

static int EventLoopHandlerID = 0;
static HWND EventLoopWindowHWND = 0;
static int EventLoopWindowMessageID = 0;
static char* EventLoopWindowMessageName = "WM_AsyncEventLoop-9E296D7E-8563-4BD5-936A-C99DC3563AC0";

int _GetValue2i(const Value& pValue)
{
	if (pValue.ev_type == 'I') return static_cast<int>(pValue.ev_long);
	if (pValue.ev_type == 'N') return static_cast<int>(pValue.ev_real);
	return 0;
}

void FAR EventLoopHandler(WHandle theWindow, EventRec FAR* ev)
{
	if (!EventLoopWindowMessageID) return;
	if (GetQueueStatus(QS_KEY | QS_MOUSEMOVE | QS_MOUSEBUTTON | QS_PAINT | QS_HOTKEY | QS_HOTKEY | QS_POSTMESSAGE)) return;

	PostMessage(EventLoopWindowHWND, EventLoopWindowMessageID, 0, 0);
}

void FASTCALL PromisesLibInit(ParamBlk* params)
{
	if (params->pCount > 0) {
		EventLoopWindowHWND = (HWND)_GetValue2i(params->p[0].val);
	}
	if (!EventLoopWindowMessageID) {
		EventLoopWindowMessageID = RegisterWindowMessage(EventLoopWindowMessageName);
	}
	if (!EventLoopHandlerID) {
		EventLoopHandlerID = _ActivateIdle((FPFI)EventLoopHandler);
	}
	_RetInt(EventLoopWindowMessageID, 15);
}

void FASTCALL PromisesLibRelease(ParamBlk* params)
{
	if (!EventLoopHandlerID) return;
	_DeActivateIdle(EventLoopHandlerID);
	EventLoopHandlerID = 0;
}


FoxInfo myFoxInfo[] = {
	{"PromisesLibRelease",(FPFI)PromisesLibRelease, CALLONUNLOAD, ""},
	{"PromisesLibInit",(FPFI)PromisesLibInit, 1, ".?"},
};

extern "C" {
	// the FoxTable structure
	FoxTable _FoxTable = {
		(FoxTable*)0, sizeof(myFoxInfo) / sizeof(FoxInfo), myFoxInfo
	};
}
