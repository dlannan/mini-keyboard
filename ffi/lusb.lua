local ffi  = require( "ffi" )

local libs = ffi_lusb_dll or {
   OSX     = { x64 = "usb-1.0.dylib" },
   Windows = { x64 = "libusb-1.0.dll" },
   Linux   = { x64 = "usb-1.0.so", arm = "usb-1.0.so" },
   BSD     = { x64 = "usb-1.0.so" },
   POSIX   = { x64 = "usb-1.0.so" },
   Other   = { x64 = "v" },
}

local lib  = ffi_lusb_dll or libs[ ffi.os ][ ffi.arch ]
local lusb_lib   = ffi.load( lib )

ffi.cdef[[

/********** lusb_lib ****************************************************************/

struct libusb_context;
struct libusb_device;
struct libusb_device_handle;
typedef struct libusb_device libusb_device;
typedef struct libusb_device_handle libusb_device_handle;

typedef struct libusb_context libusb_context;

enum {
	LIBUSB_FLEXIBLE_ARRAY 	= 3,
};

enum libusb_endpoint_direction {
	LIBUSB_ENDPOINT_OUT = 0x00,
	LIBUSB_ENDPOINT_IN = 0x80
};


enum libusb_log_level {
	LIBUSB_LOG_LEVEL_NONE = 0,
	LIBUSB_LOG_LEVEL_ERROR = 1,
	LIBUSB_LOG_LEVEL_WARNING = 2,
	LIBUSB_LOG_LEVEL_INFO = 3,
	LIBUSB_LOG_LEVEL_DEBUG = 4
};

enum libusb_option {
	LIBUSB_OPTION_LOG_LEVEL = 0,
	LIBUSB_OPTION_USE_USBDK = 1,
	LIBUSB_OPTION_NO_DEVICE_DISCOVERY = 2,
	LIBUSB_OPTION_LOG_CB = 3,
	LIBUSB_OPTION_MAX = 4
};

enum libusb_bos_type {
	LIBUSB_BT_WIRELESS_USB_DEVICE_CAPABILITY = 0x01,
	LIBUSB_BT_USB_2_0_EXTENSION = 0x02,
	LIBUSB_BT_SS_USB_DEVICE_CAPABILITY = 0x03,
	LIBUSB_BT_CONTAINER_ID = 0x04,
	LIBUSB_BT_PLATFORM_DESCRIPTOR = 0x05
};

struct libusb_device_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t bcdUSB;
	uint8_t  bDeviceClass;
	uint8_t  bDeviceSubClass;
	uint8_t  bDeviceProtocol;
	uint8_t  bMaxPacketSize0;
	uint16_t idVendor;
	uint16_t idProduct;
	uint16_t bcdDevice;
	uint8_t  iManufacturer;
	uint8_t  iProduct;
	uint8_t  iSerialNumber;
	uint8_t  bNumConfigurations;
};

struct libusb_endpoint_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bEndpointAddress;
	uint8_t  bmAttributes;
	uint16_t wMaxPacketSize;
	uint8_t  bInterval;
	uint8_t  bRefresh;
	uint8_t  bSynchAddress;
	const unsigned char *extra;
	int extra_length;
};

struct libusb_interface_association_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bFirstInterface;
	uint8_t  bInterfaceCount;
	uint8_t  bFunctionClass;
	uint8_t  bFunctionSubClass;
	uint8_t  bFunctionProtocol;
	uint8_t  iFunction;
};

struct libusb_interface_association_descriptor_array {
	const struct libusb_interface_association_descriptor *iad;
	int length;
};

struct libusb_interface_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bInterfaceNumber;
	uint8_t  bAlternateSetting;
	uint8_t  bNumEndpoints;
	uint8_t  bInterfaceClass;
	uint8_t  bInterfaceSubClass;
	uint8_t  bInterfaceProtocol;
	uint8_t  iInterface;
	const struct libusb_endpoint_descriptor *endpoint;
	const unsigned char *extra;
	int extra_length;
};

struct libusb_interface {
	const struct libusb_interface_descriptor *altsetting;
	int num_altsetting;
};

struct libusb_config_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t wTotalLength;
	uint8_t  bNumInterfaces;
	uint8_t  bConfigurationValue;
	uint8_t  iConfiguration;
	uint8_t  bmAttributes;
	uint8_t  MaxPower;
	const struct libusb_interface *interface;
	const unsigned char *extra;
	int extra_length;
};

struct libusb_ss_endpoint_companion_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bMaxBurst;
	uint8_t  bmAttributes;
	uint16_t wBytesPerInterval;
};

struct libusb_bos_dev_capability_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t  dev_capability_data[LIBUSB_FLEXIBLE_ARRAY];
};

struct libusb_bos_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t wTotalLength;
	uint8_t  bNumDeviceCaps;
	struct libusb_bos_dev_capability_descriptor *dev_capability[LIBUSB_FLEXIBLE_ARRAY];
};

struct libusb_usb_2_0_extension_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint32_t bmAttributes;
};

struct libusb_ss_usb_device_capability_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t  bmAttributes;
	uint16_t wSpeedSupported;
	uint8_t  bFunctionalitySupport;
	uint8_t  bU1DevExitLat;
	uint16_t bU2DevExitLat;
};

struct libusb_container_id_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t  bReserved;
	uint8_t  ContainerID[16];
};

struct libusb_platform_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t  bReserved;
	uint8_t  PlatformCapabilityUUID[16];
	uint8_t  CapabilityData[LIBUSB_FLEXIBLE_ARRAY];
};

typedef void ( *libusb_log_cb)(libusb_context *ctx, enum libusb_log_level level, const char *str);

struct libusb_init_option {
    enum libusb_option option;
    union {
      	int ival;
      	libusb_log_cb log_cbval;
    } value;
};

int libusb_init(libusb_context **ctx);  
int libusb_init_context(libusb_context **ctx, const struct libusb_init_option options[], int num_options);
void libusb_exit(libusb_context *ctx);

int libusb_get_device_list(libusb_context *ctx,	libusb_device ***list);
void libusb_free_device_list(libusb_device **list,	int unref_devices);

int libusb_get_device_descriptor(libusb_device *dev, struct libusb_device_descriptor *desc);
int libusb_get_bos_descriptor(libusb_device_handle *dev_handle,	struct libusb_bos_descriptor **bos);
void libusb_free_bos_descriptor(struct libusb_bos_descriptor *bos);

int libusb_has_capability(uint32_t capability);
uint8_t libusb_get_bus_number(libusb_device *dev);
uint8_t libusb_get_port_number(libusb_device *dev);
int libusb_get_port_numbers(libusb_device *dev, uint8_t *port_numbers, int port_numbers_len);
libusb_device * libusb_get_parent(libusb_device *dev);
uint8_t libusb_get_device_address(libusb_device *dev);

int libusb_get_device_speed(libusb_device *dev);
int libusb_get_max_packet_size(libusb_device *dev, unsigned char endpoint);
int libusb_get_max_iso_packet_size(libusb_device *dev, unsigned char endpoint);
int libusb_get_max_alt_packet_size(libusb_device *dev, int interface_number, int alternate_setting, unsigned char endpoint);

int libusb_open(libusb_device *dev, libusb_device_handle **dev_handle);
void libusb_close(libusb_device_handle *dev_handle);

libusb_device_handle * libusb_open_device_with_vid_pid(libusb_context *ctx, uint16_t vendor_id, uint16_t product_id);
libusb_device * libusb_get_device(libusb_device_handle *dev_handle);
int libusb_reset_device(libusb_device_handle *dev_handle);
int libusb_get_configuration(libusb_device_handle *dev,	int *config);

const char * libusb_strerror(int errcode);

int libusb_bulk_transfer(libusb_device_handle *dev_handle,
	unsigned char endpoint, unsigned char *data, int length,
	int *actual_length, unsigned int timeout);

int libusb_control_transfer(libusb_device_handle *dev_handle,
	uint8_t request_type, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	unsigned char *data, uint16_t wLength, unsigned int timeout);

int libusb_interrupt_transfer(libusb_device_handle *dev_handle,
	unsigned char endpoint, unsigned char *data, int length,
	int *actual_length, unsigned int timeout);

int libusb_kernel_driver_active(libusb_device_handle *dev_handle, int interface_number);
int libusb_detach_kernel_driver(libusb_device_handle *dev_handle, int interface_number);
int libusb_claim_interface(libusb_device_handle *dev_handle, int interface_number);
int libusb_release_interface(libusb_device_handle *dev_handle, int interface_number);
]]


return lusb_lib