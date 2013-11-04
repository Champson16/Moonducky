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

FreehandDraw.drawLine = function(parent, x0, y0, x1, y1)
	if (not FreehandDraw.graphic.image) then return; end
	local steep = false;
	if (math_abs(y1 - y0) > math_abs(x1 - x0)) then steep = true; end

	if (steep) then
		x0, y0 = y0, x0;
		x1, y1 = y1, x1;
	end

	if (x0 > x1) then
		x0, x1 = x1, x0;
		y0, y1 = y1, y0;
	end

	local deltax = x1 - x0;
	local deltay = math_abs(y1 - y0);
	local err = deltax * 0.5;
	local ystep = 0;
	local y = y0
	if (y0 < y1) then ystep = 1 else ystep = -1 end

	for x=x0,x1 do
		c = display.newImage(FreehandDraw.graphic.image);
		c.xScale = FreehandDraw.graphic.width / c.width;
		c.yScale = FreehandDraw.graphic.height / c.height;
		c:setFillColor(FreehandDraw.r, FreehandDraw.g, FreehandDraw.b, FreehandDraw.a);
		c.anchorX = 0.5; c.anchorY = 0.5;
		
		if (steep) then
			c.x = y; c.y = x;
		else
			c.x = x; c.y = y;
		end

		if (FreehandDraw.arbRotate) then
			c.rotation = math_random(0,359);
		end

		local parentGroup = parent.group or parent;
		parentGroup:insert(c);

		err = err - deltay;
		if (err < 0) then
			y = y + ystep;
			err = err + deltax;
		end
	end
	parent:invalidate();
end

FreehandDraw.onCanvasTouch = function(self, e)
	if (not FreehandDraw.graphic.image) then return; end

	local event = {};
	for k,v in pairs(e) do
		event[k] = v;
	end

	event.x = event.x - self.parent.x;
	event.y = event.y - self.parent.y;

	if (event.phase == 'began') then
		
		FreehandDraw.points = {};
		FreehandDraw.points[#FreehandDraw.points+1] = { x = event.x, y = event.y };
	
	elseif (event.phase == 'moved') then
		
		FreehandDraw.points[#FreehandDraw.points+1] = { x = event.x, y = event.y };
		local previous = FreehandDraw.points[#FreehandDraw.points-1];
		local current = FreehandDraw.points[#FreehandDraw.points];
		FreehandDraw.drawLine(self.parent.layerDrawing, previous.x, previous.y, current.x, current.y);
	
	elseif (event.phase == 'ended') or (event.phase == 'cancelled') then
		FreehandDraw.points = nil;
		self.parent.layerDrawing:invalidate();
	end
end

return FreehandDraw;