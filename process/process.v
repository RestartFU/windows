module process

#include <processthreadsapi.h>
#include <tlhelp32.h>
#include <handleapi.h>
#include <memoryapi.h>

pub const (
	th32cs_snapprocess  = 0x00000002
	process_all_access  = 0x000F0000 | 0x00100000 | 0xFFFF
	th32cs_snapmodule   = 0x08
	th32cs_snapmodule32 = 0x10
)

[typedef]
struct C.PROCESSENTRY32 {
	mut:
	dwSize              u32
	cntUsage            u32
	th32ProcessID       u32
	th32DefaultHeapID   i64
	th32ModuleID        u32
	cntThreads          u32
	th32ParentProcessID u32
	pcPriClassBase      i32
	dwFlags             u32
	szExeFile           [260]u8
}

[typedef]
struct C.MODULEENTRY32 {
	mut:
	dwSize        u32
	th32ModuleID  u32
	th32ProcessID u32
	GlblcntUsage  u32
	ProccntUsage  u32
	modBaseAddr   &u8 = unsafe { nil }
	modBaseSize   u32
	hModule       voidptr
	szModule      [256]u8
	szExePath     [260]u8
}

fn C.OpenProcess(dwDesiredAccess u32, bInheritHandle bool, dwProcessId u32) voidptr
fn C.CloseHandle(voidptr) bool
fn C.CreateToolhelp32Snapshot(dwFlags u32, th32ProcessID u32) voidptr
fn C.Process32First(hSnapshot voidptr, lppe &C.PROCESSENTRY32) bool
fn C.Process32Next(hSnapshot voidptr, lppe &C.PROCESSENTRY32) bool
fn C.Module32First(hSnapshot voidptr, lpme &C.MODULEENTRY32) bool
fn C.Module32Next(hSnapshot voidptr, lpme &C.MODULEENTRY32) bool

fn C.WriteProcessMemory(hProcess voidptr, lpBaseAddress voidptr, lpBuffer voidptr, nSize u64, lpNumberOfBytesWritten &u64) bool
fn C.VirtualProtectEx(hProcess voidptr, lpAddress voidptr, dwSize u32, flNewProtect u32, lpflOldProtect &u32) bool

pub struct Process {
	pub:
	handle voidptr
	id     u32
	app_id voidptr
}

pub fn (p Process) write_memory(addr voidptr, buf voidptr, size u32) (bool, u64) {
	n_wr := u64(0)
	num := u32(0)
	C.VirtualProtectEx(p.handle, addr, size, 0x40, &num)
	return C.WriteProcessMemory(p.handle, addr, buf, size, &n_wr), n_wr
}

pub fn process_by_name(name string) !Process {
	mut entry := C.PROCESSENTRY32{}
	entry.dwSize = sizeof(entry)

	snapshot := C.CreateToolhelp32Snapshot(th32cs_snapprocess, voidptr(0))
	defer {
		C.CloseHandle(snapshot)
	}

	if C.Process32First(snapshot, &entry) {
		for {
			mut dst := []u8{}
			for _, c in entry.szExeFile {
				dst << c
			}
			if cstr_to_vstr(dst).to_lower() == name.to_lower() {
				h := C.OpenProcess(process_all_access, true, entry.th32ProcessID)
				p := Process{
					handle: h
					id: entry.th32ProcessID
					app_id: module_by_name(entry.th32ProcessID, name)
				}
				return p
			}
			if !C.Process32Next(snapshot, &entry) {
				break
			}
		}
	}
	return error("process not found")
}

pub fn module_by_name(id u32, name string) voidptr {
	mut entry := C.MODULEENTRY32{}
	entry.dwSize = sizeof(C.MODULEENTRY32)

	snapshot := C.CreateToolhelp32Snapshot(th32cs_snapmodule | th32cs_snapmodule32,
		id)
	defer {
		C.CloseHandle(snapshot)
	}

	if C.Module32First(snapshot, &entry) {
		for {
			mut dst := []u8{}
			for _, c in entry.szModule {
				dst << c
			}
			if cstr_to_vstr(dst).to_lower() == name.to_lower() {
				return voidptr(entry.modBaseAddr)
			}
			if !C.Module32Next(snapshot, &entry) {
				break
			}
		}
	}
	return 0
}

fn cstr_to_vstr(s []u8) string {
	mut str := ''
	for _, c in s {
		if c != 0 {
			unsafe {
				mut ch := c.vstring().runes()
				ch.trim(1)
				str += ch.string()
			}
		}
	}
	return str
}