module windows

pub fn dispatch_messages() {
	msg := unsafe { nil }
	for C.GetMessage(msg, windows.null, 0, 0) {
		C.TranslateMessage(msg)
		C.DispatchMessage(msg)
	}
}

pub fn find_window(lpClassName &u16, lpWindowName &u16) voidptr {
	return C.FindWindowW(lpClassName, lpWindowName)
}
pub fn get_foreground_window() voidptr {
	return C.GetForegroundWindow()
}

pub fn prevent_console_resize() {
	console_window := C.GetConsoleWindow()
	C.SetWindowLong(console_window, -16, C.GetWindowLong(console_window, -16) & ~0x00010000 & ~0x00040000)
}

pub fn prevent_console_scroll() {
	info := C.CONSOLE_SCREEN_BUFFER_INFO{}
	h_console_output := C.GetStdHandle(-11)
	if C.GetConsoleScreenBufferInfo(h_console_output, &info) {
		coord := C.COORD{
			X: info.srWindow.Right - info.srWindow.Left + 1
			Y: info.srWindow.Bottom - info.srWindow.Top + 1
		}
		C.SetConsoleScreenBufferSize(h_console_output, coord)
	}
}