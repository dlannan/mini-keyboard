-- ----------------------------------------------------------------------------------------------

local codes = require("lua.mapcodes")

-- ----------------------------------------------------------------------------------------------
-- Macro builder for the mini-keyboard. 
--    Structure:
--       A macros table stores a list of marcos to assign to a specific key on the keyboard
--       Each macro can be assigned up to 18 key presses/combos. Even words.
--       Macros can also be assigned to the multimedia commands as well.
--
--    Example:
--       In the example we will assign the word "Hello" to the first key on the keyboard
--          key         = codes.MINIKB.KEY1,
--          macrotype   = codes.MACROTYPE.MACROKEYS,
--          layer       = codes.LAYER.LAYER1,
--          combos      = {
--              {
--                  mod = codes.MODIFIERS.SHIFT,
--                  keycode = codes.KEYS.H,    
--              },
--              {
--                  mod = codes.MODIFIERS.NOMOD,
--                  keycode = codes.KEYS.E,    
--              },
--              {
--                  mod = codes.MODIFIERS.NOMOD,
--                  keycode = codes.KEYS.L,    
--              },
--              {
--                  mod = codes.MODIFIERS.NOMOD,
--                  keycode = codes.KEYS.L,    
--              },
--              {
--                  mod = codes.MODIFIERS.NOMOD,
--                  keycode = codes.KEYS.O,    
--              },
--          },
--
-- ----------------------------------------------------------------------------------------------

local macros = {

    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY3,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.WIN,
                keycode = codes.KEYS.LEFT,
            },
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = codes.KEYS.ESCAPE,
            },            
        }
    },

    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY7,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.WIN,
                keycode = codes.KEYS.UP,
            },
        }
    },

    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY11,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.WIN,
                keycode = codes.KEYS.RIGHT,
            },
        }
    },

    {
        -- Lauunch a cmd window
        key         = codes.MINIKB.KEY4,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.WIN,
                keycode = codes.KEYS.R,
            },
            " cmd /K D:\r",
        }
    },
    
    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY8,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            "cd dev\\mycode\r",
        }
    },

    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.ROT1,
        macrotype   = codes.MACROTYPE.MACROPLAY,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MEDIA.MUTE,
                keycode = 0,
            }             
        },       
    },
    {
        -- Volume down
        key         = codes.MINIKB.ROT1CCW,
        macrotype   = codes.MACROTYPE.MACROPLAY,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MEDIA.VOL_DN,
                keycode = 0,
            }
        },       
    },
    {
        -- Volume up
        key         = codes.MINIKB.ROT1CW,
        macrotype   = codes.MACROTYPE.MACROPLAY,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MEDIA.VOL_UP,
                keycode = 0,
            }
        },       
    },
    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY9,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.NOMOD,     -- Browser forward
                keycode = 0xA6,
            }             
        },       
    },    
    {
        -- Mute using the button on the knob
        key         = codes.MINIKB.KEY10,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = 0xA7,     -- Launch App2
            }             
        },       
    },    

}

-- ----------------------------------------------------------------------------------------------
return macros
-- ----------------------------------------------------------------------------------------------