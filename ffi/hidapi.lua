local ffi  = require( "ffi" )

local libs = ffi_hidapi_dll or {
   OSX     = { x64 = "hidapi.dylib" },
   Windows = { x64 = "hidapi.dll" },
   Linux   = { x64 = "hidapi.so", arm = "hidapi.so" },
   BSD     = { x64 = "hidapi.so" },
   POSIX   = { x64 = "hidapi.so" },
   Other   = { x64 = "v" },
}

local lib  = ffi_hidapi_dll or libs[ ffi.os ][ ffi.arch ]
local hidapi_lib   = ffi.load( lib )

ffi.cdef[[

/********** hidapi_lib ****************************************************************/

struct hid_api_version {
	int major; /**< major version number */
	int minor; /**< minor version number */
	int patch; /**< patch version number */
};

struct hid_device_;
typedef struct hid_device_ hid_device; /**< opaque hidapi structure */

typedef enum {
	/** Unknown bus type */
	HID_API_BUS_UNKNOWN = 0x00,

	/** USB bus
	   Specifications:
	   https://usb.org/hid */
	HID_API_BUS_USB = 0x01,

	/** Bluetooth or Bluetooth LE bus
	   Specifications:
	   https://www.bluetooth.com/specifications/specs/human-interface-device-profile-1-1-1/
	   https://www.bluetooth.com/specifications/specs/hid-service-1-0/
	   https://www.bluetooth.com/specifications/specs/hid-over-gatt-profile-1-0/ */
	HID_API_BUS_BLUETOOTH = 0x02,

	/** I2C bus
	   Specifications:
	   https://docs.microsoft.com/previous-versions/windows/hardware/design/dn642101(v=vs.85) */
	HID_API_BUS_I2C = 0x03,

	/** SPI bus
	   Specifications:
	   https://www.microsoft.com/download/details.aspx?id=103325 */
	HID_API_BUS_SPI = 0x04,
} hid_bus_type;

/** hidapi info structure */
struct hid_device_info {
	/** Platform-specific device path */
	char *path;
	/** Device Vendor ID */
	unsigned short vendor_id;
	/** Device Product ID */
	unsigned short product_id;
	/** Serial Number */
	wchar_t *serial_number;
	/** Device Release Number in binary-coded decimal,
		also known as Device Version Number */
	unsigned short release_number;
	/** Manufacturer String */
	wchar_t *manufacturer_string;
	/** Product string */
	wchar_t *product_string;
	/** Usage Page for this Device/Interface
		(Windows/Mac/hidraw only) */
	unsigned short usage_page;
	/** Usage for this Device/Interface
		(Windows/Mac/hidraw only) */
	unsigned short usage;
	/** The USB interface which this logical device
		represents.

		Valid only if the device is a USB HID device.
		Set to -1 in all other cases.
	*/
	int interface_number;

	/** Pointer to the next device */
	struct hid_device_info *next;

	/** Underlying bus type
		Since version 0.13.0, @ref HID_API_VERSION >= HID_API_MAKE_VERSION(0, 13, 0)
	*/
	hid_bus_type bus_type;
};


int hid_init(void);
int hid_exit(void);
struct hid_device_info * hid_enumerate(unsigned short vendor_id, unsigned short product_id);
void  hid_free_enumeration(struct hid_device_info *devs);
hid_device * hid_open(unsigned short vendor_id, unsigned short product_id, const wchar_t *serial_number);
hid_device * hid_open_path(const char *path);
int hid_write(hid_device *dev, const unsigned char *data, size_t length);
void hid_winapi_set_write_timeout(hid_device *dev, unsigned long timeout);
int hid_read_timeout(hid_device *dev, unsigned char *data, size_t length, int milliseconds);
int hid_read(hid_device *dev, unsigned char *data, size_t length);
int hid_set_nonblocking(hid_device *dev, int nonblock);
int hid_send_feature_report(hid_device *dev, const unsigned char *data, size_t length);
int hid_get_feature_report(hid_device *dev, unsigned char *data, size_t length);
int hid_get_input_report(hid_device *dev, unsigned char *data, size_t length);
void hid_close(hid_device *dev);
int hid_get_manufacturer_string(hid_device *dev, wchar_t *string, size_t maxlen);
int hid_get_product_string(hid_device *dev, wchar_t *string, size_t maxlen);
int hid_get_serial_number_string(hid_device *dev, wchar_t *string, size_t maxlen);
int hid_winapi_get_container_id(hid_device *dev, GUID *container_id);
struct hid_device_info * hid_get_device_info(hid_device *dev);
int hid_get_indexed_string(hid_device *dev, int string_index, wchar_t *string, size_t maxlen);
int hid_get_report_descriptor(hid_device *dev, unsigned char *buf, size_t buf_size);
const wchar_t* hid_error(hid_device *dev);
const struct hid_api_version* hid_version(void);
const char* hid_version_str(void);

]]

return hidapi_lib