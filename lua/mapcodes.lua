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
	A = 0,
	B = 0,
	C = 0,
	D = 0,
	E = 0,
	F = 0,
	G = 0,
	H = 0,
	I = 0,
	J = 0,
	K = 0,
	L = 0,
	M = 0, -- /* 0x10 */
	N = 0,
	O = 0,
	P = 0,
	Q = 0,
	R = 0,
	S = 0,
	T = 0,
	U = 0,
	V = 0,
	W = 0,
	X = 0,
	Y = 0,
	Z = 0,
	N1 = 0,
	N2 = 0,
	N3 = 0, -- /* 0x20 */
	N4 = 0,
	N5 = 0,
	N6 = 0,
	N7 = 0,
	N8 = 0,
	N9 = 0,
	N0 = 0,
	ENTER = 0,
	ESCAPE = 0,
	BSPACE = 0,
	TAB = 0,
	SPACE = 0,
	MINUS = 0,
	EQUAL = 0,
	LBRACKET = 0,
	RBRACKET = 0, -- /* 0x30 */
	BSLASH = 0, --   /* \ and |*/
	NONUS_HASH = 0,
	SCOLON = 0, -- /* ; and : */
	QUOTE = 0, --  /* ' and " */
	GRAVE = 0, --  /* ` and ~ */
	COMMA = 0, --  /* , and < */
	DOT = 0, --    /* . and > */
	SLASH = 0, --  /* / and ? */
	CAPSLOCK = 0,
	F1 = 0,
	F2 = 0,
	F3 = 0,
	F4 = 0,
	F5 = 0,
	F6 = 0,
	F7 = 0, -- /* 0x40 */
	F8 = 0,
	F9 = 0,
	F10 = 0,
	F11 = 0,
	F12 = 0,
	PSCREEN = 0,
	SCROLLLOCK = 0,
	PAUSE = 0,
	INSERT = 0,
	HOME = 0,
	PGUP = 0,
	DELETE = 0,
	END = 0,
	PGDOWN = 0,
	RIGHT = 0,
	LEFT = 0, -- /* 0x50 */
	DOWN = 0,
	UP = 0,
	NUMLOCK = 0, -- /* Numpad keys */
	KP_SLASH = 0,
	KP_ASTERISK = 0,
	KP_MINUS = 0,
	KP_PLUS = 0,
	KP_ENTER = 0,
	KP_1 = 0,
	KP_2 = 0,
	KP_3 = 0,
	KP_4 = 0,
	KP_5 = 0,
	KP_6 = 0,
	KP_7 = 0,
	KP_8 = 0, -- /* 0x60 */
	KP_9 = 0,
	KP_0 = 0,
	KP_DOT = 0,
	NONUS_BSLASH = 0,
	APPLICATION = 0,
	POWER = 0,
	KP_EQUAL = 0,
}

-- Fill out with correct values
for i,v in ipairs(mapped_codes.KEYS) do 
    v = 0x03 + i 
end

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