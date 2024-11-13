# mini-keyboard
A utility for mini-keyboard using luajit + ffi + libusb.

This utility is based on similar tools like:

https://github.com/achushu/CH57x-keyboard-mapper

and

https://github.com/kriomant/ch57x-keyboard-tool

## Update - 13/11/2024

Have changed many things:
- The tool is atm mainly Win64 only. I will fix the Linux/Mac to use libusb soon 
- The protocol used is also changed. It looks like my device uses a newer protocol which I managed to sort out. I will update to test for different USB interfaces and switch protocols to suit.
- There is now a config file (see new command line below) and if you dont pass the config file it will load the example config file in the config folder.
- I will be building a standalone exe for this. Where you only need to pass params and dont need luajit or any of the scripts. This might be a few weeks (depending on my available time). 

## Usage 

At the moment only windows is supported in the binaries. 

It is easy to build the luajit and binaries for libusb available here:

Luajit: https://github.com/LuaJIT/LuaJIT

Libusb: https://github.com/libusb/libusb

I'll add more binaries as I get time to build each platform. 

Running is easy:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua list_devices```

The output should be similar to:

```
046d:c52b (bus 001, device 008) |  Speed:         Full Speed (12MBit/s) | ports: 12.1
1189:8840 (bus 001, device 014) |  Speed:         Full Speed (12MBit/s) | ports: 7
05e3:0610 (bus 001, device 003) |  Speed:        High Speed (480MBit/s) | ports: 10
05e3:0610 (bus 001, device 002) |  Speed:        High Speed (480MBit/s) | ports: 12
046d:0acb (bus 001, device 009) |  Speed:         Full Speed (12MBit/s) | ports: 12.2
058f:6254 (bus 001, device 005) |  Speed:        High Speed (480MBit/s) | ports: 13
0b05:19af (bus 001, device 001) |  Speed:         Full Speed (12MBit/s) | ports: 2
8086:1138 (bus 002, device 000) |  Speed:      Super Speed (5000MBit/s)
8087:0032 (bus 001, device 013) |  Speed:         Full Speed (12MBit/s) | ports: 13.4
0c76:1676 (bus 001, device 011) |  Speed:         Full Speed (12MBit/s) | ports: 10.2
05e3:0610 (bus 001, device 010) |  Speed:        High Speed (480MBit/s) | ports: 12.4
046d:08e5 (bus 001, device 004) |  Speed:        High Speed (480MBit/s) | ports: 3
8086:7ae0 (bus 001, device 000) |  Speed:      Super Speed (5000MBit/s)
05ac:024f (bus 001, device 012) |  Speed:         Full Speed (12MBit/s) | ports: 10.3
05e3:0612 (bus 001, device 007) |  Speed:      Super Speed (5000MBit/s) | ports: 25
```

Running a device info:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua device_info --device-id 2```

The output:
```
[Info] Found device:
   Vendor:Product  | 058f:6254
   Bus             | 1
   Device Id       | 2
   Device CLass    | 9
   Device SubClass | 0
   Device Protocol | 1
   Max PacketSize  | 64
   Num Configs     | 1
   Speed           |        High Speed (480MBit/s)
```

Running the same command but using vendor and product ids:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua device_info --address 1189:8840```

And the output:

```
[Info] Found device:
   Vendor:Product  | 1189:8840
   Bus             | 1
   Device Id       | 5
   Device CLass    | 0
   Device SubClass | 0
   Device Protocol | 0
   Max PacketSize  | 64
   Num Configs     | 1
   Speed           |         Full Speed (12MBit/s)
```

## Mapping keys

The basic premise for how this works is that it loads a set of macros from the config file, applies them to the keys mapped in the config and uploads it to the device.

The format of the config is described in the config/example.lua file itself. There are a couple of examples provided as shown below:

```
--    Example:
--       In the example we will assign the word "Hello" to the first key on the keyboard
--       {
--           key         = codes.MINIKB.KEY1,
--           macrotype   = codes.MACROTYPE.MACROKEYS,
--           layer       = codes.LAYER.LAYER1,
--           combos      = {
--               {
--                   mod = codes.MODIFIERS.SHIFT,
--                   keycode = codes.KEYS.H,    
--               },
--               {
--                   mod = codes.MODIFIERS.NOMOD,
--                   keycode = codes.KEYS.E,    
--               },
--               {
--                   mod = codes.MODIFIERS.NOMOD,
--                   keycode = codes.KEYS.L,    
--               },
--               {
--                   mod = codes.MODIFIERS.NOMOD,
--                   keycode = codes.KEYS.L,    
--               },
--               {
--                   mod = codes.MODIFIERS.NOMOD,
--                   keycode = codes.KEYS.O,    
--               },
--           },
--       },
--
--       Another example opening a cmd window:
--       -- Lauunch a cmd window
--       {
--           key         = codes.MINIKB.KEY4,
--           macrotype   = codes.MACROTYPE.MACROKEYS,
--           layer       = codes.LAYER.LAYER1,
--           combos      = {
--              {
--                  mod = codes.MODIFIERS.WIN,
--                  keycode = codes.KEYS.R,
--              },
--              " cmd /K D:\r",
--           },
--       },
```

The structure of the file is fairly simple. Each marco block has 3 main properties to set:

key         - which key this macro will be applied to 

macrotype   - what type of macro is it (see mapcodes.lua for details)

layer       - which layer is this macro key mapped to (1, 2 or 3)

--

The fourth property combos is a list of individual keys, mouse movements, or media controls that can be added in a list. 

If the combos property comes across a string in the list (instead of a table) it will convert that string into a list of macro keys for you. Please beware that only a small subset of all string values can be converted safely.

A limitation of the combos macros is that there can only be a maximum of 18. 

If you need a complex macro, then create a bat file or shell script and then call it from the macro that way.

--

### Map_keys Commmand Examples

Example use of the macro keys command:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua map_keys --address 1189:8840```

Example loads the config/example.lua keymapping into the device

```.\bin\win64\luajit.exe .\lua\minikeybd.lua map_keys --address 1189:8840 dev```

This loads the config/dev.lua keymapping into the device. This is a more complex example that Im using to control the volume with knob 1 and move windows around with keys 3, 7, and 11. 

Additionally a cmd window is opened with key 4.


Reset also seems to be working ok. Hope to have more commands completed soon.

## Difference

Im often using luajit to make tools and while attempting to use some of the other tools with windows I ran into odd problems like lock-ups, suggestions to install some usb sdk and various other issues, while still having little success actually connecting and controlling the 12 key + 2 knob mini-keyboard I bought.

Thus I decided to leverage libusb and luajit + ffi. 

Initial first tests indicate I can easily:
- Interrogate all connected devices and list their vendor:product ids. 
- List details about a specific device (providing the id or vendor product ids)
- Reset specific devices as needed.

Current work is investigating how to send commands to the keyboard and map new keys. I hope this is fairly straight forward, and the aim is to support uploading a keymap set thats mapped how the user decides.

## Device

Currenly I only have the 12 button 2 knob variant. But with libusb being used, I think it should be easy enough to support multiple device types. Have a look at the single lua script and if you want to help expand its capability then raise an issue or PR. Happy to add any senisble contributions. 

My device:

![alt text](https://github.com/dlannan/mini-keyboard/blob/main/media/keyboard-12-2.png)

