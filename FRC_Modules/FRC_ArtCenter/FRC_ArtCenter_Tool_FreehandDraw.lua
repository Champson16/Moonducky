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

FRC_ArtCenter_Tool_FreehandDraw.drawLine = function(parent, x0, y0, x1, y1)
	if (not FRC_ArtCenter_Tool_FreehandDraw.graphic.image) then return; end
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
		c = display.newImage(FRC_ArtCenter_Tool_FreehandDraw.graphic.image);
		c.xScale = FRC_ArtCenter_Tool_FreehandDraw.graphic.width / c.width;
		c.yScale = FRC_ArtCenter_Tool_FreehandDraw.graphic.height / c.height;
		c:setFillColor(FRC_ArtCenter_Tool_FreehandDraw.r, FRC_ArtCenter_Tool_FreehandDraw.g, FRC_ArtCenter_Tool_FreehandDraw.b, FRC_ArtCenter_Tool_FreehandDraw.a);
		c.anchorX = 0.5; c.anchorY = 0.5;
		
		if (steep) then
			c.x = y; c.y = x;
		else
			c.x = x; c.y = y;
		end

		if (FRC_ArtCenter_Tool_FreehandDraw.arbRotate) then
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

FRC_ArtCenter_Tool_FreehandDraw.onCanvasTouch = function(self, e)
	if (not FRC_ArtCenter_Tool_FreehandDraw.graphic.image) then return; end

	local event = {};
	for k,v in pairs(e) do
		event[k] = v;
	end

	event.x = event.x - self.parent.x;
	event.y = event.y - self.parent.y;

	if (event.phase == 'began') then
		
		FRC_ArtCenter_Tool_FreehandDraw.points = {};
		FRC_ArtCenter_Tool_FreehandDraw.points[#FRC_ArtCenter_Tool_FreehandDraw.points+1] = { x = event.x, y = event.y };
	
	elseif (event.phase == 'moved') then
		
		FRC_ArtCenter_Tool_FreehandDraw.points[#FRC_ArtCenter_Tool_FreehandDraw.points+1] = { x = event.x, y = event.y };
		local previous = FRC_ArtCenter_Tool_FreehandDraw.points[#FRC_ArtCenter_Tool_FreehandDraw.points-1];
		local current = FRC_ArtCenter_Tool_FreehandDraw.points[#FRC_ArtCenter_Tool_FreehandDraw.points];
		FRC_ArtCenter_Tool_FreehandDraw.drawLine(self.parent.layerDrawing, previous.x, previous.y, current.x, current.y);
	
	elseif (event.phase == 'ended') or (event.phase == 'cancelled') then
		FRC_ArtCenter_Tool_FreehandDraw.points = nil;
		self.parent.layerDrawing:invalidate();
	end
end

return FRC_ArtCenter_Tool_FreehandDraw;