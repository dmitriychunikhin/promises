#include <pro_ext.h>
#include <stdint.h>

static int EventLoopHandlerID = 0;
static HWND EventLoopWindowHWND = 0;
static int EventLoopWindowMessageID = 0;
static char* EventLoopWindowMessageName = "WM_AsyncEventLoop-9E296D7E-8563-4BD5-936A-C99DC3563AC0";
static uint64_t EventLoopPausedStart = 0;
static uint32_t EventLoopPausedDelay = 0;
static uint32_t EventLoopPausedInfinite = UINT32_MAX;

int _GetValue2i(const Value& pValue)
{
	if (pValue.ev_type == 'I') return static_cast<int>(pValue.ev_long);
	if (pValue.ev_type == 'N') return static_cast<int>(pValue.ev_real);
	return 0;
}

void FAR EventLoopHandler(WHandle theWindow, EventRec FAR* ev)
{
	if (!EventLoopWindowMessageID) return;
	if (EventLoopPausedDelay == EventLoopPausedInfinite) return;
	if (EventLoopPausedDelay) {
		uint64_t now = GetTickCount();
		if (EventLoopPausedStart < now && (EventLoopPausedStart + EventLoopPausedDelay) > now) return;
	}
	if (GetQueueStatus(QS_KEY | QS_MOUSEMOVE | QS_MOUSEBUTTON | QS_PAINT | QS_HOTKEY | QS_HOTKEY | QS_POSTMESSAGE)) return;
	PostMessage(EventLoopWindowHWND, EventLoopWindowMessageID, 0, 0);
}

void FASTCALL PromisesLib_Init(ParamBlk* params)
{
	EventLoopPausedStart = 0;
	EventLoopPausedDelay = 0;
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

void FASTCALL PromisesLib_Release(ParamBlk* params)
{
	if (!EventLoopHandlerID) return;
	_DeActivateIdle(EventLoopHandlerID);
	EventLoopHandlerID = 0;
}

void FASTCALL PromisesLib_EventLoopContinue(ParamBlk* params)
{
	EventLoopPausedStart = 0;
	EventLoopPausedDelay = 0;
}

void FASTCALL PromisesLib_EventLoopPause(ParamBlk* params)
{
	EventLoopPausedStart = GetTickCount();
	EventLoopPausedDelay = EventLoopPausedInfinite;
	if (params->pCount > 0) {
		EventLoopPausedDelay = _GetValue2i(params->p[0].val);
	}
}

void FASTCALL PromisesLib_GetTickCount(ParamBlk* params)
{
	_RetFloat(GetTickCount(), 10, 0);
}


FoxInfo myFoxInfo[] = {
	{"PromisesLib_Release",(FPFI)PromisesLib_Release, CALLONUNLOAD, ""},
	{"PromisesLib_Init",(FPFI)PromisesLib_Init, 1, ".?"},
	{"PromisesLib_EventLoopContinue",(FPFI)PromisesLib_EventLoopContinue, 0, ""},
	{"PromisesLib_EventLoopPause",(FPFI)PromisesLib_EventLoopPause, 1, ".?"},
	{"PromisesLib_GetTickCount",(FPFI)PromisesLib_GetTickCount, 0, ""},
};

extern "C" {
	// the FoxTable structure
	FoxTable _FoxTable = {
		(FoxTable*)0, sizeof(myFoxInfo) / sizeof(FoxInfo), myFoxInfo
	};
}
