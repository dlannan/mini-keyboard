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

-- If you have ideas/suggestions, raise an issue and I will take a look.

package.path    = package.path..";./ffi/?.lua"

local ffi   = require("ffi")

-- Get lusb interface
local lusb = require("lusb")

local speed_lookup = {
    [0]     = "Speed Unknown (unreported)",
    [1]     = "Low Speed (1.5MBit/s)",
    [2]     = "Full Speed (12MBit/s)",
    [3]     = "High Speed (480MBit/s)",
    [4]     = "Super Speed (5000MBit/s)",
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

    local path = ffi.new("uint8_t[8]")

    iterate_devs(devs, function(dev)
        local desc = ffi.new("struct libusb_device_descriptor[1]")
        local r = lusb.libusb_get_device_descriptor(dev[0], desc)
        if (r < 0) then
            print("failed to get device descriptor")
            return
        end

        io.write(string.format("%04x:%04x (bus %d, device %d)",
            desc[0].idVendor, desc[0].idProduct,
            lusb.libusb_get_bus_number(dev[0]), lusb.libusb_get_device_address(dev[0])))

        r = lusb.libusb_get_port_numbers(dev[0], path, ffi.sizeof(path))
        if (r > 0) then 
            io.write(" path: "..(path[0]))
            for j = 1, r-1 do 
                io.write(string.format(".%d", path[j]))
            end
        end
        io.write(" Speed: "..speed_lookup[lusb.libusb_get_device_speed(dev[0])])
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
                print("    Bus            | "..lusb.libusb_get_bus_number(dev[0])) 
                print("    Device Id      | "..lusb.libusb_get_device_address(dev[0]))
                print("    Vendor:Product | "..addr)
                print("    Speed          | "..speed_lookup[lusb.libusb_get_device_speed(dev[0])] )
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

local function map_keys()
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
