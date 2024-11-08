# mini-keyboard
A utility for mini-keyboard using luajit + ffi + libusb.

This utility is based on similar tools like:

https://github.com/achushu/CH57x-keyboard-mapper

and

https://github.com/kriomant/ch57x-keyboard-tool

## Difference

Im often using luajit to make tools and while attempting to use some of these tools with windows I ran into odd problems like lock-ups, suggestions to install some usb sdk and various other issues, while still having little success actually connecting and controlling the 12 key + 2 knob mini-keyboard I bought.

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