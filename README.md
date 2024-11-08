# mini-keyboard
A utility for mini-keyboard using luajit + ffi + libusb.

This utility is based on similar tools like:

https://github.com/achushu/CH57x-keyboard-mapper

and

https://github.com/kriomant/ch57x-keyboard-tool

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
046d:c52b (bus 1, device 9) path: 12.1 Speed: Full Speed (12MBit/s)
1189:8840 (bus 1, device 2) path: 7 Speed: Full Speed (12MBit/s)
05e3:0610 (bus 1, device 6) path: 10 Speed: High Speed (480MBit/s)
05e3:0610 (bus 1, device 1) path: 12 Speed: High Speed (480MBit/s)
046d:0acb (bus 1, device 8) path: 12.2 Speed: Full Speed (12MBit/s)
058f:6254 (bus 1, device 3) path: 13 Speed: High Speed (480MBit/s)
0b05:19af (bus 1, device 7) path: 2 Speed: Full Speed (12MBit/s)
8086:1138 (bus 2, device 0) Speed: Super Speed (5000MBit/s)
8087:0032 (bus 1, device 13) path: 13.4 Speed: Full Speed (12MBit/s)
0c76:1676 (bus 1, device 11) path: 10.2 Speed: Full Speed (12MBit/s)
05e3:0610 (bus 1, device 10) path: 12.4 Speed: High Speed (480MBit/s)
046d:08e5 (bus 1, device 5) path: 3 Speed: High Speed (480MBit/s)
8086:7ae0 (bus 1, device 0) Speed: Super Speed (5000MBit/s)
05ac:024f (bus 1, device 12) path: 10.3 Speed: Full Speed (12MBit/s)
05e3:0612 (bus 1, device 4) path: 25 Speed: Super Speed (5000MBit/s)
```

Running a device info:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua device_info --device-id 2```

The output:
```
[Info] Found device:
    Bus            | 1
    Device Id      | 2
    Vendor:Product | 1189:8840
    Speed          | Full Speed (12MBit/s)
```

Running the same command but using vendor and product ids:

```.\bin\win64\luajit.exe .\lua\minikeybd.lua device_info --address 1189:8840```

And the output:

```
[Info] Found device:
    Bus            | 1
    Device Id      | 2
    Vendor:Product | 1189:8840
    Speed          | Full Speed (12MBit/s)
```

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

Currenly I only have the 12 button 2 knob variant. But with libusb being used, I think it should be easy enough to support multiple device types. Have a look at the single lua script and if you want to help expand its capability then raise and issue or PR. Happy to add any senisble contributions. 

My device:

![alt text](https://github.com/dlannan/mini-keyboard/blob/main/media/keyboard-12-2.png)