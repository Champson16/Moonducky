-- FRC_Layout.lua
-- screen layout utility functions for Corona Graphics 2.0 engine (not compatible with 1.x engine)
local m = {};

local function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
  end

   return Table
end

local getScreenDimensions = function()
	local build = tonumber(split(system.getInfo('build'), '%.')[2]);

	if (build < 2109) then
		local screenW = display.actualContentWidth;
		local screenH = display.actualContentHeight;
		if (display.contentWidth > display.contentHeight) then
			screenW = display.actualContentHeight;
			screenH = display.actualContentWidth;
		end
		return screenW, screenH;
	else
		return display.actualContentWidth, display.actualContentHeight;
	end
end
m.getScreenDimensions = getScreenDimensions;

m.left = function(pixelsFromEdge)
	local screenW, screenH = getScreenDimensions();
	return (pixelsFromEdge or 0) - ((screenW - display.contentWidth) * 0.5);
end

m.right = function(pixelsFromEdge)
	local screenW, screenH = getScreenDimensions();
	return screenW - (pixelsFromEdge or 0) - ((screenW - display.contentWidth) * 0.5);
end

m.top = function(pixelsFromEdge)
	local screenW, screenH = getScreenDimensions();
	return (pixelsFromEdge or 0) - ((screenH - display.contentHeight) * 0.5);
end

m.bottom = function(pixelsFromEdge)
	local screenW, screenH = getScreenDimensions();
	return screenH - (pixelsFromEdge or 0) - ((screenH - display.contentHeight) * 0.5);
end

m.alignToLeft = function(displayObject, pixelsFromEdge)
	if (((displayObject) and (type(displayObject) ~= 'number'))) then
		displayObject.x = m.left(pixelsFromEdge) + (displayObject.contentWidth * displayObject.anchorX);
	else
		local pixelsFromEdge = displayObject or 0;
		return m.left(pixelsFromEdge);
	end
end

m.alignToRight = function(displayObject, pixelsFromEdge)
	if (((displayObject) and (type(displayObject) ~= 'number'))) then
		displayObject.x = m.right(pixelsFromEdge) - (displayObject.contentWidth - (displayObject.contentWidth * displayObject.anchorX));
	else
		local pixelsFromEdge = displayObject or 0;
		return m.right(pixelsFromEdge);
	end
end

m.alignToTop = function(displayObject, pixelsFromEdge)
	if (((displayObject) and (type(displayObject) ~= 'number'))) then
		displayObject.y = m.top(pixelsFromEdge) + (displayObject.contentHeight * displayObject.anchorY);
	else
		local pixelsFromEdge = displayObject or 0;
		return m.top(pixelsFromEdge);
	end
end

m.alignToBottom = function(displayObject, pixelsFromEdge)
	if (((displayObject) and (type(displayObject) ~= 'number'))) then
		displayObject.y = m.bottom(pixelsFromEdge) - (displayObject.contentHeight - (displayObject.contentHeight * displayObject.anchorY));
	else
		local pixelsFromEdge = displayObject or 0;
		return m.bottom(pixelsFromEdge);
	end
end

m.alignToCenter = function(displayObject)
  if (((displayObject) and (type(displayObject) ~= 'number'))) then
    displayObject.x = displayObject.contentWidth - (displayObject.contentWidth * displayObject.anchorX);
    displayObject.y = displayObject.contentHeight - (displayObject.contentHeight * displayObject.anchorY);
  end
end

m.scaleToFit = function(displayObject, xOffset, yOffset)
	if (not xOffset) then xOffset = 0; end
	if (not yOffset) then yOffset = 0; end

	local refWidth, refHeight = 1152, 768;

	local screenW, screenH = getScreenDimensions();
	local scale = screenH / refHeight;
	local scaledSize, diffScaled, diff;
	local x, y = 0, 0;

	if ((refWidth * scale) < screenW) then
		scale = screenW / refWidth;
		scaledSize = display.contentWidth * scale;
		diffScaled = ((refWidth * scale) - scaledSize) * 0.5;
		diff = ((refWidth * scale) - display.contentWidth) * 0.5;
		x = -(diff - diffScaled);
	else
		scaledSize = display.contentHeight * scale;
		diffScaled = ((refHeight * scale) - scaledSize) * 0.5;
		diff = ((refHeight * scale) - display.contentHeight) * 0.5;
		y = -(diff - diffScaled);
	end

	displayObject.xScale, displayObject.yScale = scale, scale;
	displayObject.x, displayObject.y = x + (xOffset * scale), y + (yOffset * scale);
end

return m;
