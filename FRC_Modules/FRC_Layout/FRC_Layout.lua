
-- FRC_Layout.lua
-- screen layout utility functions for Corona Graphics 2.0 engine (not compatible with 1.x engine)
local m = {};
local refWidth, refHeight  = 1152, 768;
local debugEn              = true

-- ==
--    round(val, n) - Rounds a number to the nearest decimal places. (http://lua-users.org/wiki/FormattingNumbers)
--    val - The value to round.
--    n - Number of decimal places to round to.
-- ==
local function round(val, n)
   if (n) then
      return math.floor( (val * 10^n) + 0.5) / (10^n)
   else
      return math.floor(val+0.5)
   end
end


local contentW 	   = display.contentWidth
local contentH 	   = display.contentHeight
local centerX 			= display.contentCenterX
local centerY 			= display.contentCenterY
local screenW			= display.actualContentWidth 
local screenH			= display.actualContentHeight
local unusedWidth		= screenW - contentW
local unusedHeight	= screenH - contentH
local left				= 0 - unusedWidth/2
local top 				= 0 - unusedHeight/2
local right 			= contentW + unusedWidth/2
local bottom 			= contentH + unusedHeight/2

contentW 			   = round(contentW)
contentH 			   = round(contentH)
left			         = round(left)
top				      = round(top)
right			         = round(right)
bottom			      = round(bottom)
screenW			      = round(screenW)
screenH			      = round(screenH)

left 			         = (left >= 0) and math.abs(left) or left
top 				      = (top >= 0) and math.abs(top) or top

local isLandscape 	= ( contentW > contentH )
local isPortrait 		= ( contentH > contentW )


if( debugEn ) then
   dprint("\n---------- calcMeasurementSpacing() @ " .. system.getTimer() )	
   dprint( "contentW       = " 	.. contentW )
   dprint( "contentH       = " 	.. contentH )
   dprint( "centerX = " .. centerX )
   dprint( "centerY = " .. centerY )
   dprint( "screenW   = " 	.. screenW )
   dprint( "screenH   = " 	.. screenH )
   dprint( "left    = " 	.. left )
   dprint( "right   = " 	.. right )
   dprint( "top     = " 	.. top )
   dprint( "bottom  = " 	.. bottom )
   dprint("---------------\n\n")
end

m.getScreenDimensions = function()
   -- Note: No longer possible to build with 2109 or before any more, so removed checks - EFM
   return screenW, screenH;
end

-- Returns pixel position of left SCREEN edge PLUS pixelsFromEdge
-- WARNING: IGNORANT OF GROUP/PARENT POSITION
m.left = function(pixelsFromEdge)
   --dprint("EDO left")   
   return left + (pixelsFromEdge or 0)
end

-- Returns pixel position of right SCREEN edge PLUS pixelsFromEdge
-- WARNING: IGNORANT OF GROUP/PARENT POSITION
m.right = function(pixelsFromEdge)
   --dprint("EDO right")
   return right + (pixelsFromEdge or 0)
end

-- Returns pixel position of top SCREEN edge PLUS pixelsFromEdge
-- WARNING: IGNORANT OF GROUP/PARENT POSITION
m.top = function(pixelsFromEdge)
   --dprint("EDO top")
   return top + (pixelsFromEdge or 0)
end

-- Returns pixel position of bottom SCREEN edge PLUS pixelsFromEdge
-- WARNING: IGNORANT OF GROUP/PARENT POSITION
m.bottom = function(pixelsFromEdge)
   --dprint("EDO bottom")
   return bottom + (pixelsFromEdge or 0)
end

-- Aligns this object to the screen left (accounts for offset of parent group(s))
m.alignToLeft = function(displayObject, pixelsFromEdge)
   --dprint("EDO alignToLeft")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.x = m.left(pixelsFromEdge) + (displayObject.contentWidth * displayObject.anchorX);
   else
      return m.left(displayObject);
   end
end

m.alignToRight = function(displayObject, pixelsFromEdge)
   --dprint("EDO alignToRight")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.x = m.right(pixelsFromEdge) - (displayObject.contentWidth - (displayObject.contentWidth * displayObject.anchorX));
   else
      return m.right(displayObject);
   end
end

m.alignToTop = function(displayObject, pixelsFromEdge)
   dprint("EDO alignToTop")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.y = m.top(pixelsFromEdge) + (displayObject.contentHeight * displayObject.anchorY);
   else
      local pixelsFromEdge = displayObject or 0;
      return m.top(pixelsFromEdge);
   end
end

m.alignToBottom = function(displayObject, pixelsFromEdge)
   dprint("EDO alignToBottom")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.y = m.bottom(pixelsFromEdge) - (displayObject.contentHeight - (displayObject.contentHeight * displayObject.anchorY));
   else
      return m.bottom(displayObject);
   end
end

m.alignToCenter = function(displayObject)
   dprint("EDO alignToCenter")
   displayObject.x = contentW - (contentW * displayObject.anchorX);
   displayObject.y = contentH - (contentH * displayObject.anchorY);
end


m.createLayers = function( view )
   local layers = { "all", "underlay", "content", "content2", "overlay" }
   for i = 1, # layers do
      local group = display.newGroup()
      view["_" .. layers[i]] = group
      if( i > 1) then
        view._all:insert( group )         
      end
      --view:insert( group )      
      --m.scaleToFit( group )      
   end
   view:insert( view._all )
   view._all.x = centerX
   view._all.y = centerY
   local scale = m.getScaleFactor()
   
   view._all:scale( scale, scale )

   --view._content2.isVisible = false
   --view._content.isVisible = false
   --table.dump2( view )
end


m.scaleToFit = function(displayObject, xOffset, yOffset)   
   local bx,by = displayObject.x, displayObject.y
   local scale = m.getScaleFactor()
   displayObject.xScale, displayObject.yScale = scale, scale;
   --displayObject.x, displayObject.y = x + (xOffset * scale), y + (yOffset * scale);

   local ax,ay = displayObject.x, displayObject.y
   local dx = ax-bx 
   local dy = ay-by 
   

   dprint("EDO scaleToFit( ", displayObject, xOffset, yOffset, " ) ==> ", scale, ((refWidth * scale) < screenW), bx,by, ax,ay, dx,dy )
end


m.getScaleFactor = function()   
   local refScale = refHeight / refWidth
   local scale = screenH / refHeight;

   if ((refWidth * scale) < screenW) then
      scale = screenW / refWidth;
   end
   return scale
end

m.placeUI = function( uiObj )
   local scale = m.getScaleFactor()
   uiObj.x = uiObj.x * scale
   uiObj.y = uiObj.y * scale
   uiObj:scale( scale, scale )
end
   

m.placeImage = function( displayObject, layoutData, debugEn )
   
   layoutData = layoutData or {}
   local scale = m.getScaleFactor()
   if( debugEn) then 
      --table.dump2( displayObject )
      table.dump2( layoutData )
   end
     
   if (layoutData.left) then
      if( debugEn) then dprint( "scaleAndPlace left" ) end
      m.alignToLeft( displayObject, layoutData.left )

   elseif (layoutData.right) then
      if( debugEn) then dprint( "scaleAndPlace right" ) end
      m.alignToRight( displayObject, layoutData.right )

   elseif (layoutData.xCenter) then
      if( debugEn) then dprint( "scaleAndPlace xCenter" ) end
      displayObject.x = centerX;

   elseif( layoutData.x ) then
      if( debugEn) then dprint( "scaleAndPlace by X" )  end-- EFM IS THIS RIGHT?      
      --displayObject.x = (layoutData.x + contentW/2) * scale
      displayObject.x = layoutData.x * scale + contentW/2
   end

   if (layoutData.top) then
      if( debugEn) then dprint( "scaleAndPlace top" ) end
      --??? displayObject.y = displayObject.y + contentBounds.yMin;

   elseif (layoutData.bottom) then
      if( debugEn) then dprint( "scaleAndPlace bottom" ) end
      m.alignToBottom( displayObject, layoutData.bottom )

   elseif (layoutData.yCenter) then
      if( debugEn) then dprint( "scaleAndPlace yCenter" ) end
      displayObject.y = centerY;

   elseif (layoutData.y) then
      if( debugEn) then dprint( "scaleAndPlace by Y" )  end -- EFM IS THIS RIGHT? 
      --displayObject.y = (layoutData.y + contentH/2) * scale
      displayObject.y = layoutData.y * scale + contentH/2
   end
   
   displayObject.x = displayObject.x - contentW/2  
   displayObject.y = (displayObject.y - contentH/2)

   -- DEBUG
   dprint("scene layout object final x/y: ", layoutData.id, displayObject.x .. " / " .. displayObject.y);
end   

m.placeAnimation = function( displayObject, layoutData, debugEn )
   
   layoutData = layoutData or {}
   
   if( debugEn) then 
      table.dump2( displayObject )
      table.dump2( layoutData )
   end
   
   local scale = m.getScaleFactor()   
   
   if (layoutData.left) then
      displayObject.x = layoutData.left
   elseif (layoutData.right) then
      displayObject.x = layoutData.right
   elseif (layoutData.x) then
      displayObject.x = layoutData.x * scale
   end
   
   if (layoutData.top) then
      displayObject.y = layoutData.top
   elseif (layoutData.bottom) then
      displayObject.y = layoutData.bottom
   elseif (layoutData.y) then
      layoutData.y = layoutData.y * scale
   end
   
   displayObject.x = (displayObject.x - contentW/2) * scale
   displayObject.y = (displayObject.y - contentH/2) * scale
   displayObject:scale(scale, scale)
   
   -- DEBUG
   dprint("scene layout object final x/y: ", layoutData, layoutData.id, displayObject.x .. " / " .. displayObject.y);
end


return m;


---
---
---
--[[

m.scaleToFit = function(displayObject, xOffset, yOffset)   
   local bx,by = displayObject.x, displayObject.y

   --if (true) then return end

   if (not xOffset) then xOffset = 0; end
   if (not yOffset) then yOffset = 0; end

   local refScale = refHeight / refWidth
   local scale = screenH / refHeight;
   local scaledSize, diffScaled, diff;
   local x, y = 0, 0;


   if ((refWidth * scale) < screenW) then
      --
      -- Don't Scale so much that we get black edges on the sides
      --
      scale = screenW / refWidth;
      scaledSize = contentW * scale;
      diffScaled = ((refWidth * scale) - scaledSize) * 0.5;
      diff = ((refWidth * scale) - contentW) * 0.5;
      x = -(diff - diffScaled);

   else   
      scaledSize = contentH * scale;
      diffScaled = ((refHeight * scale) - scaledSize) * 0.5;
      diff = ((refHeight * scale) - contentH) * 0.5;
      y = -(diff - diffScaled);

   end

   displayObject.xScale, displayObject.yScale = scale, scale;
   displayObject.x, displayObject.y = x + (xOffset * scale), y + (yOffset * scale);

   local ax,ay = displayObject.x, displayObject.y
   local dx = ax-bx 
   local dy = ay-by 

   dprint("EDO scaleToFit( ", displayObject, xOffset, yOffset, " ) ==> ", scale, ((refWidth * scale) < screenW), bx,by, ax,ay, dx,dy )
end

--]]