--
-- This file is a unified location to instantiate all 'common' FRC utility functions
--

local FRC_Util = {}

--
-- Init random seed
--
math.randomseed(os.time());


--
-- Localizations (for speedup)
--
local mRand = math.random

function FRC_Util.generateUniqueIdentifier( digits )
   digits = digits or 20
   local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' }
   local s = ''
   for i=1,digits do
      if (i == 1) then
         s = s .. alphabet[mRand(1, #alphabet)]
      elseif (mRand(0,1) == 1) then
         s = s .. mRand(0, 9)
      else
         s = s .. alphabet[mRand(1, #alphabet)]
      end
   end
   return tostring(s)
end



function FRC_Util.copyFile( srcName, srcPath, dstName, dstPath, overwrite )
  local results = true;               -- assume no errors

  -- Copy the source file to the destination file
  local rfilePath = system.pathForFile( srcName, srcPath );
  local wfilePath = system.pathForFile( dstName, dstPath );

  local rfh = io.open( rfilePath, "rb" );
  local wfh = io.open( wfilePath, "wb" );

  if  not wfh then
    print( "writeFileName open error!" );
    results = false;                 -- error
  else
    -- Read the file from the Resource directory and write it to the destination directory
    local data = rfh:read( "*a" );

    if not data then
      print( "read error!" );
      results = false;     -- error
    else
      if not wfh:write( data ) then
        print( "write error!" );
        results = false; -- error
      end
    end
  end

  -- Clean up our file handles
  rfh:close();
  wfh:close();

  return results;
end

return FRC_Util