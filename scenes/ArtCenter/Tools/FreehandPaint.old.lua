local ArtCenter = require('scenes.ArtCenter.Scene');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;

local FreehandPaint = {};

FreehandPaint.graphic = {
	image = 'assets/images/UX/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	width = 40,
	height = 40	
};

FreehandPaint.incrementor = 0;
FreehandPaint.applyNextFrame = false;
FreehandPaint.touchX = nil;
FreehandPaint.touchY = nil;

FreehandPaint.r = 1.0;
FreehandPaint.g = 0;
FreehandPaint.b = 0;
FreehandPaint.a = 0.05;

FreehandPaint.draw = function(parent, x, y)
	if ((not x) or (not y)) then return; end
	local paint = display.newImageRect(parent, FreehandPaint.graphic.image, FreehandPaint.graphic.width, FreehandPaint.graphic.height);
	paint:setFillColor(FreehandPaint.r, FreehandPaint.g, FreehandPaint.b, FreehandPaint.a);
	paint.anchorX = 0.5; paint.anchorY = 0.5;
	paint.x = x; paint.y = y;
	paint.rotation = math_random(0,359);
	return paint;
end

FreehandPaint.onCanvasTouch = function(self, event)
	if (event.phase == 'began') then
		
		FreehandPaint.points = {};
		table.insert(FreehandPaint.points, { x = event.x, y = event.y });
		FreehandPaint.draw(self.parent.layerDrawing, event.x, event.y);
	
	elseif (event.phase == 'moved') then
		
		table.insert(FreehandPaint.points, { x = event.x, y = event.y });
		local previous = FreehandPaint.points[#FreehandPaint.points-1];
		local current = FreehandPaint.points[#FreehandPaint.points];
		
		local x1 = math_floor(previous.x - ((screenW - ArtCenter.canvasWidth) * 0.5));
		local y1 = math_floor(previous.y - ((screenH - ArtCenter.canvasHeight) * 0.5));
		local x2 = math_floor(current.x - ((screenW - ArtCenter.canvasWidth) * 0.5));
		local y2 = math_floor(current.y - ((screenH - ArtCenter.canvasHeight) * 0.5));
		local path = ArtCenter.finder:getPath(x1, y1, x2, y2);
		
		local distance = math_sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));
		if (distance < (44 * 0.25)) then
			table.remove(FreehandPaint.points, #FreehandPaint.points);
			return;
		end
		
		if (path) then
			local length = path:getLength();
			local thresh = 0; --length - 100;
			for i=1,length do
				if (path._nodes[i]) and (i > thresh) then
					local x = path._nodes[i]:getX() + ((screenW - ArtCenter.canvasWidth) * 0.5);
					local y = path._nodes[i]:getY() + ((screenH - ArtCenter.canvasHeight) * 0.5);
					FreehandPaint.draw(self.parent.layerDrawing, x, y);
					FreehandPaint.points = {};
					table.insert(FreehandPaint.points, { x = event.x, y = event.y });
				end
			end
		else
			table.remove(FreehandPaint.points, #FreehandPaint.points);
		end
	
	elseif (event.phase == 'ended') or (event.phase == 'cancelled') then
		--print('Total plots: ' .. self.parent.layerDrawing.numChildren);		
		FreehandPaint.points = nil;
	end
end

FreehandPaint.onUpdate = function(canvas)
	if true then return; end
	if (FreehandPaint.applyNextFrame) then
		FreehandPaint.draw(canvas.layerDrawing, FreehandPaint.touchX, FreehandPaint.touchY);
		FreehandPaint.touchX = nil;
		FreehandPaint.touchY = nil;
		FreehandPaint.applyNextFrame = false;
	end
end

return FreehandPaint;