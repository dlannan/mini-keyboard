
--portable filesystem API for LuaJIT / Windows backend
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local bor, band, shl = bit.bor, bit.band, bit.lshift

local C = ffi.C
local cdef = ffi.cdef

--types, consts, utils -------------------------------------------------------

cdef'typedef int64_t ULONG_PTR;'

cdef[[
typedef void           VOID, *PVOID, *LPVOID;
typedef VOID*          HANDLE, *PHANDLE;
typedef unsigned short WORD;
typedef unsigned long  DWORD, *PDWORD, *LPDWORD;
typedef unsigned int   UINT;
typedef int            BOOL;
typedef ULONG_PTR      SIZE_T;
typedef const void*    LPCVOID;
typedef char*          LPSTR;
typedef const char*    LPCSTR;
typedef wchar_t        WCHAR;
typedef WCHAR*         LPWSTR;
typedef const WCHAR*   LPCWSTR;
typedef BOOL           *LPBOOL;
typedef void*          HMODULE;
typedef unsigned char  UCHAR;
typedef unsigned short USHORT;
typedef long           LONG;
typedef unsigned long  ULONG;
typedef long long      LONGLONG;

typedef union {
	struct {
		DWORD LowPart;
		LONG HighPart;
	};
	struct {
		DWORD LowPart;
		LONG HighPart;
	} u;
	LONGLONG QuadPart;
} LARGE_INTEGER, *PLARGE_INTEGER;

typedef struct {
	DWORD  nLength;
	LPVOID lpSecurityDescriptor;
	BOOL   bInheritHandle;
} SECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
]]

local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

--error handling -------------------------------------------------------------

cdef[[
DWORD GetLastError(void);

DWORD FormatMessageA(
	DWORD dwFlags,
	LPCVOID lpSource,
	DWORD dwMessageId,
	DWORD dwLanguageId,
	LPSTR lpBuffer,
	DWORD nSize,
	va_list *Arguments
);
]]

local FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

local errbuf = function(sz) return ffi.new('char[?]', sz) end

local errors = {
	[0x002] = 'not_found'       , --ERROR_FILE_NOT_FOUND, CreateFileW
	[0x003] = 'not_found'       , --ERROR_PATH_NOT_FOUND, CreateDirectoryW
	[0x005] = 'access_denied'   , --ERROR_ACCESS_DENIED, CreateFileW
	[0x01D] = 'io_error'        , --ERROR_WRITE_FAULT, WriteFile
	[0x01E] = 'io_error'        , --ERROR_READ_FAULT, ReadFile
	[0x050] = 'already_exists'  , --ERROR_FILE_EXISTS, CreateFileW
	[0x091] = 'not_empty'       , --ERROR_DIR_NOT_EMPTY, RemoveDirectoryW
	[0x0b7] = 'already_exists'  , --ERROR_ALREADY_EXISTS, CreateDirectoryW
	[0x10B] = 'not_found'       , --ERROR_DIRECTORY, FindFirstFileW
	[0x06D] = 'eof'             , --ERROR_BROKEN_PIPE ReadFile, WriteFile
}

local mmap_errors = { --CreateFileMappingW, MapViewOfFileEx
	[0x0008] = 'file_too_short' , --ERROR_NOT_ENOUGH_MEMORY, readonly file too short
	[0x0057] = 'out_of_mem'     , --ERROR_INVALID_PARAMETER, size or address too large
	[0x0070] = 'disk_full'      , --ERROR_DISK_FULL
	[0x01E7] = 'out_of_mem'     , --ERROR_INVALID_ADDRESS, address in use
	[0x03EE] = 'file_too_short' , --ERROR_FILE_INVALID, file has zero size
	[0x05AF] = 'out_of_mem'     , --ERROR_COMMITMENT_LIMIT, swapfile too short
}

local function checkneq(fail_ret, ok_ret, err_ret, ret, err, xtra_errors)
	if ret ~= fail_ret then
		return ok_ret
	end
	err = err or C.GetLastError()
	local msg = errors[err] or (xtra_errors and xtra_errors[err])
	if not msg then
		local buf, bufsz = errbuf(512)
		local sz = C.FormatMessageA(
			FORMAT_MESSAGE_FROM_SYSTEM, nil, err, 0, buf, bufsz, nil)
		msg = sz > 0 and ffi.string(buf, sz):gsub('[\r\n]+$', '') or 'Error '..err
	end
	return err_ret, msg
end

local function checkh(ret, err)
	return checkneq(INVALID_HANDLE_VALUE, ret, nil, ret, err)
end

local function checknz(ret, err)
	return checkneq(0, true, false, ret, err)
end

local function checknil(ret, err, errors)
	return checkneq(nil, ret, nil, ret, err, errors)
end

local function checknum(ret, err)
	return checkneq(0, ret, nil, ret, err)
end

--utf16/utf8 conversion ------------------------------------------------------

cdef[[
int MultiByteToWideChar(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCSTR   lpMultiByteStr,
	int      cbMultiByte,
	LPWSTR   lpWideCharStr,
	int      cchWideChar
);
int WideCharToMultiByte(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCWSTR  lpWideCharStr,
	int      cchWideChar,
	LPSTR    lpMultiByteStr,
	int      cbMultiByte,
	LPCSTR   lpDefaultChar,
	LPBOOL   lpUsedDefaultChar
);
]]

local CP_UTF8 = 65001

local wcsbuf = function(sz) return ffi.new('WCHAR[?]', sz) end

local function wcs(s, msz, wbuf) --string -> WCHAR[?]
	msz = msz and msz + 1 or #s + 1
	wbuf = wbuf or wcsbuf
	local wsz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, nil, 0)
	assert(wsz > 0) --should never happen otherwise
	local buf = wbuf(wsz)
	local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, buf, wsz)
	assert(sz == wsz) --should never happen otherwise
	return buf
end

local mbsbuf = function(sz) return ffi.new('char[?]', sz) end

local function mbs(ws, unused, mbuf) --WCHAR* -> string
	local wsz = 0	
	while(ws[wsz] ~= 0) do wsz = wsz + 1 end
	if(wsz == 0) then return ffi.string("") end

	mbuf = mbuf or mbsbuf
	local msz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, nil, 0, nil, nil)
	assert(msz > 0) --should never happen otherwise
	local buf = mbuf(msz)
	local sz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, buf, msz, nil, nil)
	assert(sz == msz) --should never happen otherwise
	return ffi.string(buf, sz-1)
end


return {
    mbs     = mbs,
    wcs     = wcs,
}