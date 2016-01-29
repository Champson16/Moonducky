-- LAST UPDATED 28 JAN 2016

-- EFM for now order is kinda crappy
-- EFM goal for now is that CCC and Moonducky be consistent

--
-- Localizations (for speedup)
--
local mRand = math.random

local FRC_Util = {}

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


-- ==
--    FRC_Util.easyAlert( title, msg, buttons )
-- ==
-- title - Name on popup.
-- msg - message in popup.
-- buttons - table of tables like this:
-- { { "button 1", opt_func1 }, { "button 2", opt_func2 }, ...}
--
function FRC_Util.easyAlert( title, msg, buttons )

   local function onComplete( event )
      local action = event.action
      local index = event.index
      if( action == "clicked" ) then
         local func = buttons[index][2]
         if( func ) then func() end
      end
      --native.cancelAlert()
   end

   local names = {}
   for i = 1, #buttons do
      names[i] = buttons[i][1]
   end
   --print( title, msg, names, onComplete )
   local alert = native.showAlert( title, msg, names, onComplete )
   return alert
end


-- Easy Blur
--
function FRC_Util.easyBlur( group, time, color )
   group = group or display.getCurrentStage()
   time = time or 0
   color = color or {0.5,0.5,0.5}
   local blur = display.captureScreen()
   blur.x, blur.y = centerX, centerY
   blur:setFillColor(unpack(color))
   --blur.fill.effect = "filter.blur"
   blur.alpha = 0
   group:insert( blur )
   transition.to( blur, { alpha = 1, time = time } )
   return blur
end




return FRC_Util