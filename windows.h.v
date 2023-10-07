module windows

#include <windows.h>

pub const (
	wh_mouse_ll    = 14
	wh_keyboard_ll = 13
	wm_mousemove   = u64(0x0200)
	wm_keyup       = u64(0x0101)
	m_left_up      = u32(0x0004)
	m_left_down    = u32(0x0002)
	null           = unsafe { nil }
)

[typedef]
struct C.COORD {
	X i16
	Y i16
}

[typedef]
struct C.SMALL_RECT {
	Left   i16
	Top    i16
	Right  i16
	Bottom i16
}

[typedef]
struct C.CONSOLE_SCREEN_BUFFER_INFO {
	dwSize              C.COORD
	dwCursorPosition    C.COORD
	wAttributes         u16
	srWindow            C.SMALL_RECT
	dwMaximumWindowSize C.COORD
}

[typedef]
struct C.POINT {
	x i32
	y i32
}

[typedef]
struct C.MSLLHOOKSTRUCT {
	pt          C.POINT
	mouseData   u32
	flags       u32
	time        u32
	dwExtraInfo &u64
}

[typedef]
struct C.KBDLLHOOKSTRUCT {
	vkCode      u32
	scanCode    u32
	flags       u32
	time        u32
	dwExtraInfo &u64
}

type HOOKPROC = fn (int, u64, i64) i64

fn C.FindWindowW(lpClassName &u16, lpWindowName &u16) voidptr
fn C.GetForegroundWindow() voidptr
fn C.GetConsoleWindow() voidptr
fn C.SetWindowLong(hWnd voidptr, nIndex int, dwNewLong i64)
fn C.GetWindowLong(hWnd voidptr, nIndex int) i64
fn C.GetStdHandle(nStdHandle u32) voidptr
fn C.GetConsoleScreenBufferInfo(hConsoleOutput voidptr, lpConsoleScreenBufferInfo &C.CONSOLE_SCREEN_BUFFER_INFO) bool
fn C.SetConsoleScreenBufferSize(hConsoleOutput voidptr, dwSize C.COORD) bool
fn C.SetWindowsHookEx(int, &HOOKPROC, voidptr, u32) voidptr
fn C.GetMessage(voidptr, voidptr, u64, u64) bool
fn C.TranslateMessage(voidptr) bool
fn C.DispatchMessage(voidptr) i64
fn C.UnhookWindowsHookEx(voidptr) bool
fn C.CallNextHookEx(voidptr, int, u64, i64) i64

[typedef]
struct C.HARDWAREINPUT {
	uMsg    u32
	wParamL u16
	wParamH u16
}

[typedef]
struct C.KEYBDINPUT {
	wVk         u16
	wScam       u16
	dwFlags     u32
	time        u32
	dwExtraInfo &u64
}

[typedef]
struct C.MOUSEINPUT {
	dx          i64
	dy          i64
	mouseData   u32
	dwFlags     u32
	time        u32
	dwExtraInfo &u64 = unsafe { nil }
}

[typedef]
struct C.INPUT {
	@type u32
	mi    C.MOUSEINPUT
}

fn C.SendInput(u64, &C.INPUT, int) u64

pub struct Point {
pub:
	x i32
	y i32
}

pub struct MouseData {
pub:
	point      Point
	mouse_data u32
	flags      u32
	time       u32
	extra_info &u64
	action     u64
}

pub struct MouseHook {
mut:
	hook voidptr
pub:
	handler ?fn (MouseData)
}

pub fn (mut h MouseHook) hook() {
	h.hook = C.SetWindowsHookEx(windows.wh_mouse_ll, h.callback, 0, 0)
}

pub fn (h MouseHook) unhook() {
	C.UnhookWindowsHookEx(h.hook)
}

fn (h MouseHook) callback(nCode int, wParam u64, lParam i64) i64 {
	mouse_struct := &C.MSLLHOOKSTRUCT(lParam)
	d := MouseData{
		point: Point{
			x: mouse_struct.pt.x
			y: mouse_struct.pt.y
		}
		mouse_data: mouse_struct.mouseData
		flags: mouse_struct.flags
		time: mouse_struct.time
		extra_info: mouse_struct.dwExtraInfo
		action: wParam
	}
	h.handler(d) or {}

	return C.CallNextHookEx(h.hook, nCode, wParam, lParam)
}

pub fn send_mouse_input(flags u32) {
	input := C.INPUT{
		@type: 0
		mi: C.MOUSEINPUT{
			dwFlags: flags
		}
	}
	C.SendInput(1, &input, sizeof(C.INPUT))
}

pub struct KeyboardData {
pub:
	vk_code    u32
	scan_code  u32
	flags      u32
	time       u32
	extra_info &u64
	action     u64
}

pub struct KeyboardHook {
mut:
	hook voidptr
pub:
	handler ?fn (KeyboardData)
}

pub fn (mut h KeyboardHook) hook() {
	h.hook = C.SetWindowsHookEx(windows.wh_keyboard_ll, h.callback, 0, 0)
}

pub fn (h KeyboardHook) unhook() {
	C.UnhookWindowsHookEx(h.hook)
}

fn (h KeyboardHook) callback(nCode int, wParam u64, lParam i64) i64 {
	keyboard_struct := &C.KBDLLHOOKSTRUCT(lParam)
	d := KeyboardData{
		vk_code: keyboard_struct.vkCode
		scan_code: keyboard_struct.scanCode
		flags: keyboard_struct.flags
		time: keyboard_struct.time
		extra_info: keyboard_struct.dwExtraInfo
		action: wParam
	}
	h.handler(d) or {}

	return C.CallNextHookEx(h.hook, nCode, wParam, lParam)
}
