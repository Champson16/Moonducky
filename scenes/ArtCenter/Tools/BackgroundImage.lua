local ArtCenter = require('scenes.ArtCenter.Scene');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local FreehandDraw = {};

FreehandDraw.graphic = {
	image = 'assets/images/UX/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	width = 40,
	height = 40	
};

FreehandDraw.r = 1.0;
FreehandDraw.g = 0;
FreehandDraw.b = 0;
FreehandDraw.a = 0.05;

FreehandDraw.arbRotate = true;

FreehandDraw.onCanvasTouch = function(self, event)
	return;
end

return FreehandDraw;