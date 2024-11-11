-- ----------------------------------------------------------------------------------------------

local mapped_codes = {}

mapped_codes.MINIKB = {
	KEY1 = 1,
	KEY2 = 2,
	KEY3 = 3,
	KEY4 = 4,
	KEY5 = 5,
	KEY6 = 6,
	KEY7 = 7,
	KEY8 = 8,
	KEY9 = 9,
	KEY10 = 10,
	KEY11 = 11,
	KEY12 = 12,
	ROT1CCW = 13,
	ROT1 = 14,
	ROT1CW = 15,
	ROT2CCW = 16,
	ROT2 = 17,
	ROT2CW = 18,
}

mapped_codes.NOKEY = 0x00
mapped_codes.KEYS = {
	A = 4,
	B = 5,
	C = 6,
	D = 7,
	E = 8,
	F = 9,
	G = 10,
	H = 11,
	I = 12,
	J = 13,
	K = 14,
	L = 15,
	M = 16, -- /* 0x10 */
	N = 17,
	O = 18,
	P = 19,
	Q = 20,
	R = 21,
	S = 22,
	T = 23,
	U = 24,
	V = 25,
	W = 26,
	X = 27,
	Y = 28,
	Z = 29,
	N1 = 30,
	N2 = 31,
	N3 = 32, -- /* 0x20 */
	N4 = 33,
	N5 = 34,
	N6 = 35,
	N7 = 36,
	N8 = 37,
	N9 = 38,
	N0 = 39,
	ENTER = 40,
	ESCAPE = 41,
	BSPACE = 42,
	TAB = 43,
	SPACE = 44,
	MINUS = 45,
	EQUAL = 46,
	LBRACKET = 47,
	RBRACKET = 48, -- /* 0x30 */
	BSLASH = 49, --   /* \ and |*/
	NONUS_HASH = 50,
	SCOLON = 51, -- /* ; and : */
	QUOTE = 52, --  /* ' and " */
	GRAVE = 53, --  /* ` and ~ */
	COMMA = 54, --  /* , and < */
	DOT = 55, --    /* . and > */
	SLASH = 56, --  /* / and ? */
	CAPSLOCK = 57,
	F1 = 58,
	F2 = 59,
	F3 = 60,
	F4 = 61,
	F5 = 62,
	F6 = 63,
	F7 = 64, -- /* 0x40 */
	F8 = 65,
	F9 = 66,
	F10 = 67,
	F11 = 68,
	F12 = 69,
	PSCREEN = 70,
	SCROLLLOCK = 71,
	PAUSE = 72,
	INSERT = 73,
	HOME = 74,
	PGUP = 75,
	DELETE = 76,
	END = 77,
	PGDOWN = 78,
	RIGHT = 79,
	LEFT = 80, -- /* 0x50 */
	DOWN = 81,
	UP = 82,
	NUMLOCK = 83, -- /* Numpad keys */
	KP_SLASH = 84,
	KP_ASTERISK = 85,
	KP_MINUS = 86,
	KP_PLUS = 87,
	KP_ENTER = 88,
	KP_1 = 89,
	KP_2 = 90,
	KP_3 = 91,
	KP_4 = 92,
	KP_5 = 93,
	KP_6 = 94,
	KP_7 = 95,
	KP_8 = 96, -- /* 0x60 */
	KP_9 = 97,
	KP_0 = 98,
	KP_DOT = 99,
	NONUS_BSLASH = 100,
	APPLICATION = 101,
	POWER = 102,
	KP_EQUAL = 103,
}

mapped_codes.MACROTYPE = {
	MACRONONE            = 0x00,
	MACROKEYS            = 0x01,
	MACROPLAY            = 0x02,
	MACROMOUSE           = 0x03,
}

mapped_codes.LAYER =  {
	LAYER1       = 0x10,
	LAYER2       = 0x20,
	LAYER3       = 0x30,
}

-- /* Modifiers */
-- // Simultaneous modifier presses are added
mapped_codes.NOMO   = 0x00
mapped_codes.MODIFIERS = {
	NOMOD           = 0,
	CTRL            = 0x01,
	SHIFT           = 0x02,
	ALT             = 0x04,
	WIN             = 0x08,
	RCTRL           = 0x10,
	RSHIFT          = 0x20,
	RALT            = 0x40,
	RWIN            = 0x80,
}

-- /* Media */
-- // 03 01 12 cd 00 00 00
mapped_codes.MEDIA = {
	PLAY   = 0xcd,
	PREV   = 0xb6,
	NEXT   = 0xb5,
	MUTE   = 0xe2,
	VOL_UP = 0xe9,
	VOL_DN = 0xea,
}

-- // 03 01 13 04 00 00 00
mapped_codes.MOUSE_BUTTON = {
	MS_LEFT             = 0x01,
	MS_RIGHT            = 0x02,
	MS_CENTER           = 0x04,
}

-- /* Mouse wheel */
-- // 03    01  13    00  00  00 ff   01
-- // magic key layer len seq ?? code mod
mapped_codes.MOUSE_WHEEL = {
	MS_WL      = 0x00,
	MS_WL_UP   = 0x01,
	MS_WL_DOWN = 0xff,
}

return mapped_codes