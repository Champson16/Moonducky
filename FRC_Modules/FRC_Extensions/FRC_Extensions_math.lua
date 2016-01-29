-- Extensions to the math.* library
local json = require( "json" )

--
-- Localizations (for speedup)
--
local mRand = math.random

math.randomseed(os.time())

-- EFM!! - This actually overrides math.round()
function math.round(num, idp)
   return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

