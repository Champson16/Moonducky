-- Extensions to the string.* library
local json = require( "json" )

--
-- Localizations (for speedup)
--
local mRand = math.random


-- ==
--    string:rpad( len, char ) - Places padding on right side of a string, such that the new string is at least len characters long.
-- ==
function string:rpad(len, char)
   local theStr = self
   if char == nil then char = ' ' end
   return theStr .. string.rep(char, len - #theStr)
end

