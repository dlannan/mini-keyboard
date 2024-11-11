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

print(hid_win.hid)

-- -------------------------------------------------------------------------------------------------

--types, consts, utils -------------------------------------------------------

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
]]

local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

-- -------------------------------------------------------------------------------------------------

hid_win.get_hid_devices = function()
    local devices = {}
    local guid = ffi.new("GUID[1]")
    hid_win.hid.HidD_GetHidGuid( guid )
    local infoset = hid_win.setupapi.SetupDiGetClassDevsW( guid, nil, 0, 18)
    if(infoset ~= nil) then 

        local ifaceinfo = ffi.new("SP_DEVICE_INTERFACE_DATA[1]")
        ifaceinfo[0].cbSize = ffi.sizeof("SP_DEVICE_INTERFACE_DATA")
        for index = 0, 63 do 
            local setupinfo = hid_win.setupapi.SetupDiEnumDeviceInterfaces( infoset, nil, guid, index, ifaceinfo )
            if(setupinfo ~= nil) then 

                local buffsize = ffi.new("int[1]", {0})
                hid_win.setupapi.SetupDiGetDeviceInterfaceDetailW( infoset, ifaceinfo, nil, buffsize[0], buffsize, nil)
                local detail = ffi.new("uint8_t[?]", buffsize[0])
                detail = ffi.cast("SP_DEVICE_INTERFACE_DETAIL_DATA_W *", detail)
                
                local res = hid_win.setupapi.SetupDiGetDeviceInterfaceDetailW(infoset, ifaceinfo, detail, buffsize[0], buffsize, nil)
                if(res == true) then 
                    table.insert(devices, detail)
                end
            end
        end
    end
    hid_win.setupapi.SetupDiDestroyDeviceInfoList(infoset)
    return devices
end

-- -------------------------------------------------------------------------------------------------

hid_win.begin_async_read = function()

    -- byte[] inputBuff = new byte[InputReportLength];
    -- _ = hidDevice.Handle;
    -- readResult = hidDevice.BeginRead(inputBuff, 0, InputReportLength, ReadCompleted, inputBuff);
end

-- -------------------------------------------------------------------------------------------------
-- Open a usb device based on its Vendor Id and Product Id
hid_win.open_device = function( vid, pid )
    if(hid_win.deviceState ~= "opened") then 

        hid_win.devices = hid_win.get_hid_devices()
        if( table.getn(hid_win.devices) == 0) then 
            return INVALID_HANDLE_VALUE 
        end

        for idx, dev in ipairs(hid_win.devices) do 
            local device = hid_win.kernel32.CreateFileW(dev, 3221225472, 0, 0, 3, 1073741824, 0)
            if(device ~= -1) then 
                local attributes = ffi.new("HIDD_ATTRIBUTES[1]")
                if (hid_win.hid.HidD_GetAttributes(device, attributes) == false) then
                    hid_win.kernel32.CloseHandle(device);
                    return INVALID_HANDLE_VALUE
                end
                local buf = ffi.new("uint8_t[?]", 512)
                hid_win.hid.HidD_GetSerialNumberString(device, buf, 512)
                -- Check matching stuff!!
                if (attributes.VendorID == vid and attributes.ProductID == pid) then 

                    local preparseData = ffi.new("HIDP_PREPARSED_DATA[1]")
                    hid_win.hid.HidD_GetPreparsedData(device, preparseData)
                    local caps = ffi.new("HIDP_CAPS[1]")
                    hid_win.hid.HidP_GetCaps(preparseData, caps)
                    hid_win.hid.HidD_FreePreparsedData(preparseData)
                    hid_win.curr_device.outputReportLength = caps.OutputReportByteLength
                    hid_win.curr_device.inputReportLength = caps.InputReportByteLength
                    
                    hid_win.deviceState = "opened"
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

return hid_win

-- -------------------------------------------------------------------------------------------------
