-- What is this? Its a Windows direct HID interface. You can call all the Windows HID
--   calls you need.
--
-- Backstory - after examining the fact that a C# app can happily write to my mini keyboard device
--             but using the hidapi I could not. This did not make any sense. 
--             So instead, this is to talk directly to the HID and use the correct hid pages
--             Looking at the hid api, I think the overlapped event system is the problem - it doesnt work.

local ffi  = require( "ffi" )

-- -------------------------------------------------------------------------------------------------
-- WINDOWS ONLY!!!
-- A table is created so we can add helper functions here. Make everything simple.
local hid_win = {
    kernel32        = ffi.load("kernel32"),      -- Create file etc
    user32          = ffi.load("user32"),        -- Misc win methods
    hid             = ffi.load( "hid" ),         -- load the hid dll 
    setupapi        = ffi.load("setupapi"),

    devices         = {},       -- Devices found when enumerating
    curr_device     = {},
    deviceState     = nil,      -- Is the device open, closed reading, writing.. etc
}

-- -------------------------------------------------------------------------------------------------

ffi.cdef'typedef int64_t ULONG_PTR;'

ffi.cdef[[

enum {
    ANYSIZE_ARRAY       = 1
};

typedef void           VOID, *PVOID, *LPVOID;
typedef VOID*          HANDLE, *PHANDLE;
typedef intptr_t       HDEVINFO;
typedef unsigned short WORD;
typedef unsigned short USAGE;
typedef unsigned long  DWORD, *PDWORD, *LPDWORD;
typedef unsigned int   UINT;
typedef int            BOOL;
typedef int            BOOLEAN;
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

typedef struct _OVERLAPPED {
    ULONG_PTR Internal;
    ULONG_PTR InternalHigh;
    union {
      struct {
        DWORD Offset;
        DWORD OffsetHigh;
      } DUMMYSTRUCTNAME;
      PVOID Pointer;
    } DUMMYUNIONNAME;
    HANDLE    hEvent;
} OVERLAPPED, *LPOVERLAPPED;

typedef struct _GUID {
    unsigned long  Data1;
    unsigned short Data2;
    unsigned short Data3;
    unsigned char  Data4[ 8 ];
} GUID, *LPGUID;

typedef struct _SP_DEVINFO_DATA {
    DWORD     cbSize;
    GUID      ClassGuid;
    DWORD     DevInst;
    ULONG_PTR Reserved;
} SP_DEVINFO_DATA, *PSP_DEVINFO_DATA;

typedef struct _SP_DEVICE_INTERFACE_DATA {
    DWORD     cbSize;
    GUID      InterfaceClassGuid;
    DWORD     Flags;
    ULONG_PTR Reserved;
} SP_DEVICE_INTERFACE_DATA, *PSP_DEVICE_INTERFACE_DATA;

typedef struct _HIDD_ATTRIBUTES {
    ULONG  Size;
    USHORT VendorID;
    USHORT ProductID;
    USHORT VersionNumber;
} HIDD_ATTRIBUTES, *PHIDD_ATTRIBUTES;

typedef struct _HIDP_PREPARSED_DATA HIDP_PREPARSED_DATA, *PHIDP_PREPARSED_DATA;

typedef struct _HIDP_CAPS {
    USAGE  Usage;
    USAGE  UsagePage;
    USHORT InputReportByteLength;
    USHORT OutputReportByteLength;
    USHORT FeatureReportByteLength;
    USHORT Reserved[17];
    USHORT NumberLinkCollectionNodes;
    USHORT NumberInputButtonCaps;
    USHORT NumberInputValueCaps;
    USHORT NumberInputDataIndices;
    USHORT NumberOutputButtonCaps;
    USHORT NumberOutputValueCaps;
    USHORT NumberOutputDataIndices;
    USHORT NumberFeatureButtonCaps;
    USHORT NumberFeatureValueCaps;
    USHORT NumberFeatureDataIndices;
} HIDP_CAPS, *PHIDP_CAPS;

typedef struct _SP_DEVICE_INTERFACE_DETAIL_DATA_W {
    DWORD cbSize;
    WCHAR DevicePath[ANYSIZE_ARRAY];
} SP_DEVICE_INTERFACE_DETAIL_DATA_W, *PSP_DEVICE_INTERFACE_DETAIL_DATA_W;

enum DIGCF
{
	DIGCF_DEFAULT = 1,
	DIGCF_PRESENT = 2,
	DIGCF_ALLCLASSES = 4,
	DIGCF_PROFILE = 8,
	DIGCF_DEVICEINTERFACE = 0x10
};

void HidD_GetHidGuid( LPGUID HidGuid );
BOOLEAN HidD_GetAttributes(HANDLE HidDeviceObject, PHIDD_ATTRIBUTES Attributes);
BOOLEAN HidD_GetSerialNumberString(HANDLE HidDeviceObject,PVOID Buffer,ULONG BufferLength);
BOOLEAN HidD_GetPreparsedData(HANDLE HidDeviceObject, PHIDP_PREPARSED_DATA *PreparsedData);
int HidP_GetCaps(PHIDP_PREPARSED_DATA PreparsedData, PHIDP_CAPS Capabilities);
BOOLEAN HidD_FreePreparsedData(PHIDP_PREPARSED_DATA PreparsedData);

intptr_t SetupDiGetClassDevsW( const GUID *ClassGuid, const wchar_t ** Enumerator, intptr_t hwndParent, uint32_t Flags );
BOOL SetupDiEnumDeviceInterfaces(HDEVINFO DeviceInfoSet, PSP_DEVINFO_DATA DeviceInfoData, const GUID *InterfaceClassGuid, DWORD MemberIndex, PSP_DEVICE_INTERFACE_DATA DeviceInterfaceData);
BOOL SetupDiGetDeviceInterfaceDetailW(HDEVINFO DeviceInfoSet, PSP_DEVICE_INTERFACE_DATA DeviceInterfaceData, PSP_DEVICE_INTERFACE_DETAIL_DATA_W DeviceInterfaceDetailData, DWORD DeviceInterfaceDetailDataSize, PDWORD RequiredSize, PSP_DEVINFO_DATA DeviceInfoData);
BOOL SetupDiDestroyDeviceInfoList(HDEVINFO DeviceInfoSet);

HANDLE CreateFileW(LPCWSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
void CloseHandle(HANDLE fhandle);
BOOL ReadFile( HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
BOOL WriteFile( HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);

DWORD GetLastError();
DWORD FormatMessageA( DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPSTR lpBuffer, DWORD nSize, va_list *Arguments);

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

HANDLE CreateEventA(LPSECURITY_ATTRIBUTES lpEventAttributes, BOOL bManualReset, BOOL bInitialState, LPCSTR lpName);
DWORD WaitForSingleObject(HANDLE hHandle,DWORD  dwMilliseconds);
BOOL GetOverlappedResult(HANDLE hFile, LPOVERLAPPED lpOverlapped, LPDWORD lpNumberOfBytesTransferred, BOOL bWait);
]]

-- -------------------------------------------------------------------------------------------------

local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

-- -------------------------------------------------------------------------------------------------

local function GetErrorString()
    local err = hid_win.kernel32.GetLastError()
    local buf = ffi.new("char[256]")
    hid_win.kernel32.FormatMessageA(bit.bor(0x1000, 0x200), nil, err, bit.lshift(0x01, 10), buf, ffi.sizeof(buf),nil)
    return ffi.string(buf)
end

local CP_UTF8 = 65001
local mbsbuf = function(sz) return ffi.new('char[?]', sz) end

local function mbs(ws, mbuf) --WCHAR* -> string
	local wsz = 0
	while(ws[wsz] ~= 0) do wsz = wsz + 1 end
	if(wsz == 0) then return ffi.string("") end
	wsz = wsz + 1

	mbuf = mbuf or mbsbuf
	local msz = ffi.C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, nil, 0, nil, nil)
	assert(msz > 0) --should never happen otherwise
	local buf = mbuf(msz)
	local sz = ffi.C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, buf, msz, nil, nil)
	assert(sz == msz) --should never happen otherwise
	return ffi.string(buf, sz-1)
end

-- -------------------------------------------------------------------------------------------------

hid_win.get_error = function()
    return GetErrorString()
end

-- -------------------------------------------------------------------------------------------------

hid_win.enumerate = function(hid_device_types)

    hid_device_types = hid_device_types or bit.bor(ffi.C.DIGCF_PRESENT, ffi.C.DIGCF_DEVICEINTERFACE)
    local devices = {}
    local guid = ffi.new("GUID[1]")
    hid_win.hid.HidD_GetHidGuid( guid )
    local infoset = hid_win.setupapi.SetupDiGetClassDevsW( guid, nil, 0, hid_device_types)
    if(infoset ~= nil) then 

        local ifaceinfo = ffi.new("SP_DEVICE_INTERFACE_DATA[1]")
        ifaceinfo[0].cbSize = ffi.sizeof("SP_DEVICE_INTERFACE_DATA")
        for index = 0, 63 do 
            local setupinfo = hid_win.setupapi.SetupDiEnumDeviceInterfaces( infoset, nil, guid, index, ifaceinfo )
            if(setupinfo == 1) then 

                local buffsize = ffi.new("int[1]", {0})
                hid_win.setupapi.SetupDiGetDeviceInterfaceDetailW( infoset, ifaceinfo, nil, buffsize[0], buffsize, nil)
                local detailraw = ffi.new("uint8_t[?]", buffsize[0])
                local detail = ffi.cast("PSP_DEVICE_INTERFACE_DETAIL_DATA_W", detailraw)
                detail[0].cbSize = ffi.sizeof("PSP_DEVICE_INTERFACE_DETAIL_DATA_W")
                local res = hid_win.setupapi.SetupDiGetDeviceInterfaceDetailW(infoset, ifaceinfo, detail, buffsize[0], buffsize, nil)
                if(res == 1) then 
                    local detailptr = detailraw+4
                    local handlestr = ffi.cast("const unsigned short *",detailptr)
                    table.insert(devices, handlestr)
                else
                    print("[Error get_hid_devices] Invalid Details: "..GetErrorString())
                end
            end
        end
    end
    hid_win.setupapi.SetupDiDestroyDeviceInfoList(infoset)
    return devices
end

-- -------------------------------------------------------------------------------------------------

hid_win.begin_async_read = function()

    local device = hid_win.curr_device.device
    local buflen = hid_win.curr_device.inputReportLength
    local buffer = ffi.new("uint8_t[?]", buflen)
    local readbytes = ffi.new("int[1]", {0})
    ffi.C.ReadFile(device, buffer, buflen, readbytes, hid_win.curr_device.overlapped)

    local bytesread = ffi.new("int[1]", {0})
    
    while(bytesread[0] < buflen) do
        ffi.C.GetOverlappedResult(device, hid_win.curr_device.overlapped ,bytesread, false)
        print(bytesread[0])
    end
end

-- -------------------------------------------------------------------------------------------------
-- Open a usb device based on its Vendor Id and Product Id
hid_win.open_device = function( vid, pid )

    if(hid_win.deviceState ~= "opened") then 

        hid_win.devices = hid_win.enumerate()
        if( table.getn(hid_win.devices) == 0) then 
            return INVALID_HANDLE_VALUE 
        end

        for idx, dev in ipairs(hid_win.devices) do 
            local device = hid_win.kernel32.CreateFileW(dev, 0xC0000000, 0, nil, 3, 0x40000000, nil)
            if(device ~= -1) then 
                local attributes = ffi.new("HIDD_ATTRIBUTES[1]")
                if (hid_win.hid.HidD_GetAttributes(device, attributes) == false) then
                    hid_win.kernel32.CloseHandle(device);
                    return INVALID_HANDLE_VALUE
                end
                local buf = ffi.new("uint8_t[?]", 512)
                hid_win.hid.HidD_GetSerialNumberString(device, buf, 512)
                -- Check matching stuff!!
                
                -- local tpath = mbs(dev)
                -- local is_m1_01 = string.match(tpath, "mi_01")
                -- print(string.format("VID: 0x%04x PID: 0x%04x   %s", attributes[0].VendorID, attributes[0].ProductID, is_m1_01))

                if (attributes[0].VendorID == vid and attributes[0].ProductID == pid) then 

                    local preparseData = ffi.new("struct _HIDP_PREPARSED_DATA *[1]")
                    hid_win.hid.HidD_GetPreparsedData(device, preparseData)
                    local caps = ffi.new("HIDP_CAPS[1]")
                    hid_win.hid.HidP_GetCaps(preparseData[0], caps)
                    hid_win.hid.HidD_FreePreparsedData(preparseData[0])
                    hid_win.curr_device.path = dev
                    hid_win.curr_device.caps = caps
                    hid_win.curr_device.attributes = attributes
                    hid_win.curr_device.outputReportLength = caps[0].OutputReportByteLength
                    hid_win.curr_device.inputReportLength = caps[0].InputReportByteLength
                    
                    -- Create a file stream here for reading.
                    -- local devpath = mbs(dev)\
                    -- Do an initial read... checking that the handle works.
                    hid_win.curr_device.overlapped = ffi.new("OVERLAPPED[1]")
                    hid_win.curr_device.overlapped[0].hEvent = ffi.C.CreateEventA(nil, 1, 0, nil)

                    hid_win.deviceState = "opened"
                    hid_win.curr_device.device = device
                    return device
                end
            end
            hid_win.kernel32.CloseHandle(device)
        end
        return INVALID_HANDLE_VALUE 
    end
    return INVALID_HANDLE_VALUE
end

-- -------------------------------------------------------------------------------------------------

hid_win.close_device = function()

    if( hid_win.curr_device.hiddevice ) then 
        io.close( hid_win.curr_device.hiddevice )
    end
    if(hid_win.curr_device.device ~= nil) then
        hid_win.kernel32.CloseHandle(hid_win.curr_device.device)
    end
    hid_win.curr_device.device = nil
end

-- -------------------------------------------------------------------------------------------------

hid_win.write = function(buf, buflen)

    local device = hid_win.curr_device.device
    if(device==nil) then return -1 end
    
    local bytes_written = ffi.new("int[1]")

    local err = ffi.C.WriteFile(hid_win.curr_device.device, buf, buflen, bytes_written, hid_win.curr_device.overlapped)
    if(err ~= 0) then 
        print("[Error] write: "..hid_win.get_error())
        return -1
    end
    -- Wait for a little bit.

    local res = ffi.C.WaitForSingleObject( hid_win.curr_device.overlapped[0].hEvent, 1000);
    res = ffi.C.GetOverlappedResult(device, hid_win.curr_device.overlapped, bytes_written, false)
    if(res <= 0) then print( hid_win.get_error()) end
    if(res ~= 0) then return bytes_written[0] end
    return -1
end 

-- -------------------------------------------------------------------------------------------------

return hid_win

-- -------------------------------------------------------------------------------------------------
