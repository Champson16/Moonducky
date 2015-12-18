
-- FRC_Layout.lua
-- screen layout utility functions for Corona Graphics 2.0 engine (not compatible with 1.x engine)
local m = {}
local refWidth, refHeight  = 1152, 768
local scaleFactor          = 1
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

--
-- General method to get useful screen dimensions
--
m.getScreenDimensions = function()
   -- Note: No longer possible to build with 2109 or before any more, so removed checks - EFM
   return screenW, screenH, contentW, contentH, centerX, centerY
end

--
-- Utility function to re-calculate scale factor based on current refWidth/Height.
-- NOTE: Only used internally.
--
local function calculateScaleFactor()   
   local refScale = refHeight / refWidth
   local scale = screenH / refHeight

   if ( (refWidth * scale) < screenW ) then
      scale = screenW / refWidth
   end
   scaleFactor = scale
end
calculateScaleFactor() -- Calculate on first load of module.

--
-- Utility function that allows you to change your scale factor (basis for all other scaling)
--
-- Initially Normally set at top of file
--
m.setRefDimensions = function( refW, refH )
   refWidth, refHeight = refW, refH
   m.calculateScaleFactor()
end

--
-- Access function to get current scale factor.
--
m.getScaleFactor = function()      
   return scaleFactor
end

--
-- Scale an object using the current scaleFactor and add and additional (auto-scaled) x/y offset
--
m.scaleToFit = function(displayObject, xOffset, yOffset) 
   
   xOffset = xOffset or 0
   yOffset = yOffset or 0
   
   local scale = scaleFactor
      
   displayObject.xScale = scale 
   displayObject.yScale = scale
   
   local bx, by   = displayObject.x, displayObject.y
   
   displayObject.x = (displayObject.x + xOffset) * scale
   displayObject.y = (displayObject.y + yOffset) * scale
   
   local ax,ay    = displayObject.x, displayObject.y
   local dx, dy   = ax-bx, ay-by 

   --dprint("scaleToFit( ", displayObject, xOffset, yOffset, " ) ==> ", scale, ((refWidth * scale) < screenW), bx,by, ax,ay, dx,dy )
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

-- Aligns this object/pixeloffset to the SCREEN left + pixelsFromEdge Offset
-- Accounts for current scaling
m.alignToLeft = function(displayObject, pixelsFromEdge )


   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.x = m.left(pixelsFromEdge) + (displayObject.contentWidth * displayObject.anchorX)
   else
      return m.left(displayObject)
   end
end

-- Aligns this object to the SCREEN right - pixelsFromEdge Offset
-- Accounts for current scaling
m.alignToRight = function(displayObject, pixelsFromEdge)
   --dprint("EDO alignToRight")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.x = m.right(-pixelsFromEdge) - (displayObject.contentWidth - (displayObject.contentWidth * displayObject.anchorX))
      dprint("BILLY", pixelsFromEdge, m.right(pixelsFromEdge), m.right(0) )
   else
      return m.right(displayObject)
   end
end

-- Aligns this object to the SCREEN top + pixelsFromEdge Offset
-- Accounts for current scaling
m.alignToTop = function(displayObject, pixelsFromEdge)
   dprint("EDO alignToTop")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.y = m.top(pixelsFromEdge) + (displayObject.contentHeight * displayObject.anchorY)
   else
      local pixelsFromEdge = displayObject or 0
      return m.top(pixelsFromEdge)
   end
end

-- Aligns this object to the SCREEN bottom - pixelsFromEdge Offset
-- Accounts for current scaling
m.alignToBottom = function(displayObject, pixelsFromEdge)
   dprint("EDO alignToBottom")
   if (((displayObject) and (type(displayObject) ~= 'number'))) then
      displayObject.y = m.bottom(pixelsFromEdge) - (displayObject.contentHeight - (displayObject.contentHeight * displayObject.anchorY))
   else
      return m.bottom(displayObject)
   end
end

-- Align to SCREEN CENTER
-- WARNING: IGNORANT OF GROUP/PARENT POSITION
m.alignToCenter = function(displayObject)
   displayObject.x = centerX
   displayObject.y = centerY
end

--
-- createLayers() - Creates a standard set of layers for use by all scenes.
--
m.createLayers = function( view )
   local layers = { "underlay", "content", "content2", "overlay" } -- ordered bottom-to-top
   for i = 1, # layers do
      local group = display.newGroup()
      view["_" .. layers[i]] = group
      view:insert( group )         
   end   
end

-- Adjusts position of object relative to the center
-- 
-- WARNING DOES NOT ACCOUNT FOR ANCHORS (anchorX/Y must be 0.5)
--
m.placeUI = function( uiObj )
   local scale = scaleFactor
   local dx = uiObj.x - centerX
   local dy = uiObj.y - centerY
   
   dx = dx * scale
   dy = dy * scale
   
   uiObj.x = dx + centerX
   uiObj.y = dy + centerY
   
   uiObj.xScale = scale
   uiObj.yScale = scale
end

-- Adjusts position of object relative to the center
-- 
-- WARNING DOES NOT ACCOUNT FOR ANCHORS (anchorX/Y must be 0.5)
--
m.placeUIDebuger = function( uiObj )
   uiObj.x = uiObj.x + centerX
   uiObj.y = uiObj.y + centerY   
   dprint( "placeUIDebuger", uiObj.x, uiObj.y )
end


m.placeImage = function( displayObject, layoutData, debugEn )

   layoutData = layoutData or {}
   
   local scale = scaleFactor
   if( debugEn) then 
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
      displayObject.x = centerX

   elseif( layoutData.x ) then
      if( debugEn) then dprint( "scaleAndPlace by X" )  end-- EFM IS THIS RIGHT?      
      displayObject.x = centerX + layoutData.x * scale
   end

   if (layoutData.top) then
      if( debugEn) then dprint( "scaleAndPlace top" ) end
      --??? displayObject.y = displayObject.y + contentBounds.yMin

   elseif (layoutData.bottom) then
      if( debugEn) then dprint( "scaleAndPlace bottom" ) end
      m.alignToBottom( displayObject, layoutData.bottom )

   elseif (layoutData.yCenter) then
      if( debugEn) then dprint( "scaleAndPlace yCenter" ) end
      displayObject.y = centerY

   elseif (layoutData.y) then
      if( debugEn) then dprint( "scaleAndPlace by Y" )  end -- EFM IS THIS RIGHT? 
      displayObject.y = centerY + layoutData.y * scale
   end
   local scale = scaleFactor
   displayObject.xScale = scale
   displayObject.yScale = scale
   
   -- DEBUG
   dprint("scene layout object final x/y: ", layoutData.id, displayObject.x .. " / " .. displayObject.y)
end   

m.placeAnimation = function( displayObject, layoutData, debugEn )
   
   --dprint("Before - scene layout object final x/y: ", displayObject.x .. " / " .. displayObject.y)

   layoutData = layoutData or {}

   if( debugEn) then 
      table.dump2( displayObject )
      table.dump2( layoutData )
   end

   local scale = scaleFactor

   if (layoutData.left) then
      displayObject.x = layoutData.left  -- EFM NOT WORKING RIGHT NOW?
   
   elseif (layoutData.right) then
      displayObject.x = layoutData.right -- EFM NOT WORKING RIGHT NOW?
      --m.alignToRight( displayObject, layoutData.right + contentW  )
      --local x = m.right( -contentW/2 - displayObject.contentWidth/2 ) - layoutData.right
      --dprint("*****************************", x, displayObject.contentWidth)
      --displayObject.x = x
   
   elseif (layoutData.x) then
      displayObject.x = layoutData.x-- * scale -- EFM DOES NOT ALIGN WITH IMAGES and VICE VERSA
   
   end

   if (layoutData.top) then
      displayObject.y = layoutData.top  -- EFM NOT WORKING RIGHT NOW?
   
   elseif (layoutData.bottom) then
      displayObject.y = layoutData.bottom  -- EFM NOT WORKING RIGHT NOW?
   
   elseif (layoutData.y) then
      dprint("*****************************", layoutData.y)
      displayObject.y = layoutData.y --* scale -- EFM DOES NOT ALIGN WITH IMAGES and VICE VERSA
   end
         
   local scale = scaleFactor
   local dx = displayObject.x - centerX
   local dy = displayObject.y - centerY
   
   dx = dx * scale
   dy = dy * scale
   
   displayObject.x = dx + centerX
   displayObject.y = dy + centerY
   
   displayObject.xScale = scale
   displayObject.yScale = scale

   -- DEBUG
   --dprint("After - scene layout object final x/y: ", displayObject.x .. " / " .. displayObject.y, displayObject.numChildren)
end

return m
