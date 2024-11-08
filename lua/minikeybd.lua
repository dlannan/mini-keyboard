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
    print("  luajit minikeybd.lua device_info --address 1189:8840")
end


-- ----------------------------------------------------------------------------------------------
-- Set some config based on args incoming
local function check_args()

    return nil
end

-- ----------------------------------------------------------------------------------------------

local function print_devs(devs)

    print(devs)
    local dev = ffi.new("struct libusb_device *[1]")
    print(dev)
	local i = 0
    local j = 0
	local path = ffi.new("uint8_t[8]")

    dev[0] = devs[i]
    i = i + 1

	while (dev[0] ~= nil) do

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
		io.write("\n")
        dev[0] = devs[i]
        i = i + 1
	end
end

-- ----------------------------------------------------------------------------------------------

local function list_devices()
	local devs = ffi.new("libusb_device **[1]")

	local  r = lusb.libusb_init_context(nil, nil, 0)
	if (r < 0) then 
        print("[Error] : "..tostring(r))
		return r
    end

	local cnt = lusb.libusb_get_device_list(nil, devs)
	if (cnt < 0) then
		lusb.libusb_exit(nil)
		print("[Error] : "..tostring(cnt))
    end

	print_devs(devs[0])
	lusb.libusb_free_device_list(devs[0], 1)

	lusb.libusb_exit(nil)
end

-- ----------------------------------------------------------------------------------------------
-- This will bail if args are weird or none given
local res = check_args()
if(res == nil) then return args_usage() end 


list_devices()