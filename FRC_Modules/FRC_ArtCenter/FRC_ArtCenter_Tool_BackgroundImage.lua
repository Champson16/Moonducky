local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local FRC_ArtCenter_Tool_FreehandDraw = {};

FRC_ArtCenter_Tool_FreehandDraw.graphic = {
	image = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	width = 40,
	height = 40	
};

FRC_ArtCenter_Tool_FreehandDraw.r = 1.0;
FRC_ArtCenter_Tool_FreehandDraw.g = 0;
FRC_ArtCenter_Tool_FreehandDraw.b = 0;
FRC_ArtCenter_Tool_FreehandDraw.a = 0.05;

FRC_ArtCenter_Tool_FreehandDraw.arbRotate = true;

FRC_ArtCenter_Tool_FreehandDraw.onCanvasTouch = function(self, event)
	return;
end

return FRC_ArtCenter_Tool_FreehandDraw;