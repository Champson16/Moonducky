-- layout.lua
-- screen layout utility functions for Corona Graphics 2.0 engine (not compatible with 1.x engine)
local m = {};

local getScreenDimensions = function()
	local screenW = display.actualContentWidth;
	local screenH = display.actualContentHeight;
	if (display.contentWidth > display.contentHeight) then
		screenW = display.actualContentHeight;
		screenH = display.actualContentWidth;
	end
	return screenW, screenH;
end

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
	displayObject.x = m.left(pixelsFromEdge) + (displayObject.contentWidth * displayObject.anchorX);
end

m.alignToRight = function(displayObject, pixelsFromEdge)
	displayObject.x = m.right(pixelsFromEdge) - (displayObject.contentWidth - (displayObject.contentWidth * displayObject.anchorX));
end

m.alignToTop = function(displayObject, pixelsFromEdge)
	displayObject.y = m.top(pixelsFromEdge) + (displayObject.contentHeight * displayObject.anchorY);
end

m.alignToBottom = function(displayObject, pixelsFromEdge)
	displayObject.y = m.bottom(pixelsFromEdge) - (displayObject.contentHeight - (displayObject.contentHeight * displayObject.anchorY));
end

return m;