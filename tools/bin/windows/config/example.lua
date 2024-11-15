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
--
--       The primary difference here is that the cmd can be done as a string
--
--    Recommended Use:
--       Copy this example.lua and create your own. 
--       The config can be passed as a parameter to the program as the final parameter.
--       If the config isnt found it will use config.example instead (it will report this)
--
--    Notes: 
--       Warning: 18 is a hard limit on the number of events that can be assigned a key.
--                If you need to do complex commands, make a bat file and then call it
--                from the macro.


-- ----------------------------------------------------------------------------------------------

local macros = {

    -- Make sure each key mapping is wrapped in a single table {} 
    {
        -- Assign an uppercase C to the second key
        key         = codes.MINIKB.KEY2,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.SHIFT,
                keycode = codes.KEYS.C,    
            },
        },     
    },

    {
        -- The example of assigning Hello to the first key
        key         = codes.MINIKB.KEY1,
        macrotype   = codes.MACROTYPE.MACROKEYS,
        layer       = codes.LAYER.LAYER1,
        combos      = {
            {
                mod = codes.MODIFIERS.SHIFT,
                keycode = codes.KEYS.J,
            },
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = codes.KEYS.E,    
            },
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = codes.KEYS.L,    
            },
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = codes.KEYS.L,    
            },
            {
                mod = codes.MODIFIERS.NOMOD,
                keycode = codes.KEYS.O,    
            },
        },       
    }
}

-- ----------------------------------------------------------------------------------------------
return macros
-- ----------------------------------------------------------------------------------------------