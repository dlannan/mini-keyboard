-- A little simple utility for modifying the mappings of the 
--   minikeyboard seen in a number of online sellers (Amazon, Aliexpress etc)
--   Originally I was attempting to use:
--     https://github.com/kriomant/ch57x-keyboard-tool/tree/master
--     This is extremely unstable on windows. And needs some "third party" usb libs installed, which seemed overkill
--     The code looked simple enough (sending some command codes to the device)
--     Determined a luajit + ffi + lusb dll would be far simpler and more flexible (can use in apps etc)

-- Goals of this tool
--   - simple key mapping 
--   - enable/disable leds if needed
--   - check status (current mapping, bt on etc)
--   - support various hardware ids if needed

-- Update:
--   The hidapi library has been added, since keyboards use HID protocols and dont seem to work well
--   with the lusb lib. The lusb will still be used for showing devices and similar.
--   The hidapi will be used mainly in mapping key codes

-- If you have ideas/suggestions, raise an issue and I will take a look.

package.path    = package.path..";./ffi/?.lua"

-- ----------------------------------------------------------------------------------------------

local ffi   = require("ffi")

ffi.cdef[[
void Sleep(uint32_t ms);
]]

-- ----------------------------------------------------------------------------------------------

local codes = require("lua.mapcodes")

-- ----------------------------------------------------------------------------------------------
-- Get lusb interface
local lusb = require("ffi.lusb")

local whid = require("ffi.hidwin")
-- local hapi = require("hidapi")
local wwin = require("lua.wchar_win")

-- ----------------------------------------------------------------------------------------------

local speed_lookup = {
    [0]     = "   Speed Unknown (unreported)",
    [1]     = "        Low Speed (1.5MBit/s)",
    [2]     = "        Full Speed (12MBit/s)",
    [3]     = "       High Speed (480MBit/s)",
    [4]     = "     Super Speed (5000MBit/s)",
    [5]     = "Super Speed Plus(10000MBit/s)",
}

-- ----------------------------------------------------------------------------------------------
-- Print out the args for the app
local function args_usage()

    print(" minikeybd tool usage.")
    print(" luajit minikeybd.lua <command> <options>")
    print(" ")
    print(" Commands:")
    print("  list_devices        - show all the devices detected on usb.")
    print("  device_info         - show info about specific device (needs options).")
    print("  device_reset        - attempt to reset a device - for keyboard devices")
    print("  map_keys            - using options map the keys of a keyboard device")
    print(" ")
    print(" Options:")
    print("  --device-id <id>    - set which device to effect for a command")
    print("  --address <XX:YY>   - set which address to use for a device")
    print("  --map-key           - starts key mapping. can map multiple. will ask for key and type")
    print("  --map-config <file> - uses a lua file to map many keys and layers at once")
    print(" ")
    print(" Examples:")
    print("  luajit minikeybd.lua list_devices")
    print("  luajit minikeybd.lua device_info --device-id 12")
    print("  luajit minikeybd.lua device_info --address 1189:8")
end

-- ----------------------------------------------------------------------------------------------

local function setup_lusb()

    local devs = ffi.new("libusb_device **[1]")

	local  r = lusb.libusb_init_context(nil, nil, 0)
	if (r < 0) then 
        print("[Error] : "..tostring(r))
		return nil
    end

	local cnt = lusb.libusb_get_device_list(nil, devs)
	if (cnt < 0) then
		lusb.libusb_exit(nil)
		print("[Error] : "..tostring(cnt))
        return nil
    end

    return devs
end

-- ----------------------------------------------------------------------------------------------

local function iterate_devs(devs, dev_cb)

    local dev = ffi.new("struct libusb_device *[1]")
	local i = 0
    dev[0] = devs[i]
    i = i + 1

	while (dev[0] ~= nil) do

        if(dev_cb(dev)) then return i end
        dev[0] = devs[i]
        i = i + 1
	end
end

-- ----------------------------------------------------------------------------------------------

local function print_devs(devs)

    local ports = ffi.new("uint8_t[8]")

    iterate_devs(devs, function(dev)
        local desc = ffi.new("struct libusb_device_descriptor[1]")
        local r = lusb.libusb_get_device_descriptor(dev[0], desc)
        if (r < 0) then
            print("failed to get device descriptor")
            return
        end

        io.write(string.format("%04x:%04x (bus %03d, device %03d) | ",
            desc[0].idVendor, desc[0].idProduct,
            lusb.libusb_get_bus_number(dev[0]), lusb.libusb_get_device_address(dev[0])))

        io.write(" Speed: "..speed_lookup[lusb.libusb_get_device_speed(dev[0])])

        r = lusb.libusb_get_port_numbers(dev[0], ports, ffi.sizeof(ports))
        if (r > 0) then 
            io.write(" | ports: "..(ports[0]))
            for j = 1, r-1 do 
                io.write(string.format(".%d", ports[j]))
            end
        end
        io.write("\n")
    end)
end

-- ----------------------------------------------------------------------------------------------

local function list_devices()

	local devs = setup_lusb()
    if(devs) then 
	    print_devs(devs[0])
	    lusb.libusb_free_device_list(devs[0], 1)

	    lusb.libusb_exit(nil)
    end
end

-- ----------------------------------------------------------------------------------------------

local function device_info(inarg)

    local params = nil 
    local matchtype = nil

    if(inarg[2] == "--device-id" and inarg[3]) then 
        matchtype = "device_id"
        params = inarg[3]
    elseif(inarg[2] == "--address" and inarg[3]) then 
        matchtype = "address"
        params = inarg[3]
    else 
        print("[Error] No valid device_id or address provided.")
        return nil
    end

	local devs = setup_lusb()
    if(devs) then 

        local matched = nil 

        -- Only match the first with the same address! or same id!
        local dev_id = iterate_devs(devs[0], function(dev)

            local desc = ffi.new("struct libusb_device_descriptor[1]")
            local r = lusb.libusb_get_device_descriptor(dev[0], desc)
            if (r < 0) then
                print("failed to get device descriptor")
                return
            end

            local addr = string.format("%04x:%04x", desc[0].idVendor, desc[0].idProduct)

            if(matchtype == "device_id") then 
                if(lusb.libusb_get_device_address(dev[0]) == tonumber(params)) then matched = true end
            elseif(matchtype == "address") then
                if(addr == params) then matched = true end
            end

            if(matched) then 
                print("[Info] Found device:")
                print("   Vendor:Product  | "..addr)
                print("   Bus             | "..lusb.libusb_get_bus_number(dev[0])) 
                print("   Device Id       | "..lusb.libusb_get_device_address(dev[0]))
                print("   Device CLass    | "..desc[0].bDeviceClass)
                print("   Device SubClass | "..desc[0].bDeviceSubClass)
                print("   Device Protocol | "..desc[0].bDeviceProtocol)
                print("   Max PacketSize  | "..desc[0].bMaxPacketSize0)
                print("   Num Configs     | "..desc[0].bNumConfigurations)
                print("   Speed           | "..speed_lookup[lusb.libusb_get_device_speed(dev[0])] )
                return true
            end            
        end)

        if(matched == nil) then print("[Error] No matching device found.") end

	    lusb.libusb_free_device_list(devs[0], 1)

	    lusb.libusb_exit(nil)
    end
end

-- ----------------------------------------------------------------------------------------------

local function device_reset(inarg)

    local params = nil 

    if(inarg[2] == "--address" and inarg[3]) then 
        params = inarg[3]
    else 
        print("[Error] No valid vendor:product provided.")
        return nil
    end

    local ctx = ffi.new("libusb_context *[1]")
    local r = lusb.libusb_init(ctx)
    if( r < 0 ) then 
        print("[Error] Unable to init libusb context.")
        return 
    end 
    
    local vid, pid = string.match(params, "^(.-)%:(.-)$")
    local handle = lusb.libusb_open_device_with_vid_pid(ctx[0], tonumber(vid,16), tonumber(pid,16) )
    if(handle) then lusb.libusb_reset_device(handle) end
    
	lusb.libusb_exit(nil)
end

-- ----------------------------------------------------------------------------------------------

local function dump_caps()
    local dev = whid.curr_device
    local attr = dev.attributes[0] 
    local caps = dev.caps[0]

    print("Device "..(string.format("0x%04x",attr.VendorID))..":"..(string.format("0x%04x",attr.ProductID)))
    print("  Path:               "..wwin.mbs(dev.path))
    print("  Version No:         "..attr.VersionNumber)
    print("  Usage Page:         "..string.format("0x%04x", caps.UsagePage))
    print("  Usage:              "..caps.Usage)
    print("  Input Report Len:   "..caps.InputReportByteLength)
    print("  Output Report Len:  "..caps.OutputReportByteLength)
    print("  Feature Report Len: "..caps.FeatureReportByteLength)
    print("  InputButtonsCaps:   "..caps.NumberInputButtonCaps)
    print("  InputValueCaps:     "..caps.NumberInputValueCaps)
end

-- ----------------------------------------------------------------------------------------------

local function check_error(handle, res)
    if(res < 0) then 
        local err = whid.get_error()
        print("[Error] "..err)
        return true
    end 
    return nil
end

-- ----------------------------------------------------------------------------------------------

local function get_report(handle) 
    local report_len = 64
    local report = ffi.new("unsigned char[?]", report_len)
    local desc = hapi.hid_get_report_descriptor(handle, report, report_len)
    check_error(handle, desc)
    for i=0, desc-1 do io.write(string.format("0x%02x ", report[i])) end; print()
    return desc
end

-- ----------------------------------------------------------------------------------------------

local function download_map(handle)
    local buf = ffi.new("unsigned char[?]", 65) 
    ffi.fill(buf, 65, 0)
    buf[0] = 0x01
	buf[1] = 0xa1
	buf[2] = 0x01
	local res = hapi.hid_write(handle, buf, 65);
    if(check_error(handle, res)) then return end
end

-- ----------------------------------------------------------------------------------------------

local function send_data( handle, buffer, count, reportid )

    reportid = reportid or 3
    buffer[0] = reportid 
    -- local res = hapi.hid_write(handle, buffer, count);
    local res = whid.write(buffer, count)
    if(check_error(handle, res)) then return res end
    return 0
end

-- ----------------------------------------------------------------------------------------------

local function send_hello(handle)

    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
    send_data(handle, buf, count);
end


-- ----------------------------------------------------------------------------------------------

local function send_start(handle, layer)

    layer = layer or 0x01
    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
	buf[1] = 0xa1
    buf[2] = layer
    send_data(handle, buf, count);
end

-- ----------------------------------------------------------------------------------------------

local function send_stop(handle)

    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
	buf[1] = 0xaa
	buf[2] = 0xaa
    send_data(handle, buf, count);
end

-- ----------------------------------------------------------------------------------------------

local function send_flash_led(handle)

    send_start(handle) 

    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
	buf[1] = 0xaa
    buf[2] = 0xa1
    send_data(handle, buf, count);
end

-- ----------------------------------------------------------------------------------------------

local function process_combos(macro)

    local newcombos = {}
    for i,com in ipairs(macro.combos) do 

        if(type(com) == "string") then 
            -- Iterate string and map char to the key codes.
            for c in string.gmatch(com, ".") do
                local keycode = 0
                local mod = codes.MODIFIERS.NOMOD

                local ch = string.byte(c)
                if(ch >=65 and ch <= 90) then 
                    keycode = ch-65 + codes.KEYS.A 
                    mod = codes.MODIFIERS.SHIFT
                elseif(ch >=97 and ch <= 122) then 
                    keycode = ch-97 + codes.KEYS.A 
                elseif(ch == 92) then 
                    keycode = codes.KEYS.BSLASH
                elseif(ch == 13) then 
                    keycode = codes.KEYS.ENTER
                elseif(ch == 32) then 
                    keycode = codes.KEYS.SPACE
                elseif(ch == 34) then 
                    keycode = codes.KEYS.QUOTE
                elseif(ch == 47) then 
                    keycode = codes.KEYS.SLASH  
                elseif(ch == 44) then 
                    keycode = codes.KEYS.COMMA
                elseif(ch == 45) then 
                    keycode = codes.KEYS.MINUS
                elseif(ch == 46) then 
                    keycode = codes.KEYS.DOT
                elseif(ch == 58) then 
                    mod = codes.MODIFIERS.SHIFT
                    keycode = codes.KEYS.SCOLON
                elseif(ch == 59) then 
                    keycode = codes.KEYS.SCOLON
                end
-- print(c, mod, keycode, ch)

                table.insert(newcombos, { mod = mod, keycode = keycode })
            end

        elseif(type(com) == "table") then 
            table.insert(newcombos, com)
        end
    end
    return newcombos
end

-- ----------------------------------------------------------------------------------------------

local function send_macro_proto1(handle, macro)

    -- Check combos - if its a string then generate the appropriate combo for it.
    local combos = process_combos(macro)
    if(combos == nil) then 
        return nil 
    end

    send_start(handle)

    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
    buf[1] = 254
	buf[2] = macro.key
    buf[3] = macro.layer
    buf[4] = macro.macrotype
    buf[5] = 0
    buf[6] = 0

    buf[7] = 0
    buf[8] = 0
    buf[9] = 0
    buf[10] = table.getn(combos)

    local startindex = 11
    if(macro.macrotype == codes.MACROTYPE.MACROKEYS) then startindex = 11 end

    for i,v in ipairs(combos) do 
        buf[startindex] = v.mod
        buf[startindex+1] = v.keycode
        startindex = startindex + 2
    end
    send_data(handle, buf, count);

    send_stop(handle)
end

-- ----------------------------------------------------------------------------------------------

local function keyboard_check( handle )

    local reportid = 3
    local count = 65
    local buf = ffi.new("unsigned char[?]", count)
    ffi.fill(buf, count, 0)
    buf[1] = 0
    buf[2] = 0
    local res = send_data(handle, buf, count, reportid)
    if(res == 0) then print("Report Id: "..reportid) end   
end

-- ----------------------------------------------------------------------------------------------

local function map_keys(inarg)

    local params = nil 

    if(inarg[2] == "--address" and inarg[3]) then 
        params = inarg[3]
    else 
        print("[Error] No valid vendor:product provided.")
        return nil
    end

    local vid, pid = string.match(params, "^(.-)%:(.-)$")

    if(vid == nil) then print("[Error] map_keys: Invalid vid.") end 
    if(pid == nil) then print("[Error] map_keys: Invalid pid.") end

    local device = whid.open_device(tonumber(vid, 16), tonumber(pid, 16))

    dump_caps(device)

    keyboard_check(device)
    send_hello(device)

    -- Load in the macro configs
    local config = inarg[4] or "example"
    local macros = require("config."..config)
    for i,v in pairs(macros) do
        send_macro_proto1(device, v)
    end

    whid.close_device()
end

-- ----------------------------------------------------------------------------------------------

local commands = {
    ["--help"]      = { func = args_usage, param = nil},
    ["?"]           = { func = args_usage, param = nil},
    list_devices    = { func = list_devices, param = nil },
    device_info     = { func = device_info, param = nil },
    device_reset    = { func = device_reset, param = nil },
    map_keys        = { func = map_keys, param = nil },
}


-- ----------------------------------------------------------------------------------------------
-- Set some config based on args incoming
local function check_args()

    local command = arg[1]
    if(command) then 

        local cmd = commands[command]
        if(cmd) then 
            if(cmd.func) then cmd.func(arg) end
            return 1
        else
            print("[Error] Command not found: "..command.."\n")
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------------------------
-- This will bail if args are weird or none given
local res = check_args()
if(res == nil) then return args_usage() end 
