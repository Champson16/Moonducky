-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar);
--display.setDefault("background", 1.0, 1.0, 1.0);

local function newEventListener()
	return Runtime._super:newClass();
end

local ui = require('modules.ui');
local layout = require('modules.layout');

local button = ui.button.new({
	imageUp = 'button.png',
	imageDown = 'button-down.png',
	width = 120,
	height = 120
});

-- [[
button:addEventListener("press", function(event)
	print("Pressing button.");
end);

button:addEventListener("release", function(event)
	print("Released button.");
end);
--]]



local scroller = ui.scroller.new({
	width = 320,
	height = 480,
	x = display.contentCenterX,
	y = display.contentCenterY,
	bgColor = { 1.0, 1.0, 1.0 },
	scrollLock = false
});

--scroller.anchorX = 0.5;
--scroller.anchorY = 0.5;
--[[
scroller.xScale = 0.75;
scroller.yScale = 0.75;
--]]

local tree = display.newImageRect('tree.png', 800, 1440);
tree.anchorX = 0.5;
scroller:insert(tree);

layout.alignToTop(button);
layout.alignToLeft(button);

--tree.x = 160;
--tree.y = 100;

--scroller:snapTopLeft(scroller.content);

--tree.x = tree.contentWidth * tree.anchorX;
--tree.x = (tree.contentWidth * tree.anchorX) - tree.contentWidth + scroller.width;
--tree.y = tree.contentHeight * tree.anchorY;


--transition.to(scroller, { time=3000, xScale=0.5, yScale=0.5 });

--[[
timer.performWithDelay(3000, function()
	scroller:dispose();
	scroller = nil;
	button = nil;
end, 1);
--]]