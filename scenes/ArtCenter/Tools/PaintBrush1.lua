local ArtCenter = require('scenes.ArtCenter.Scene');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();
local PaintBrush1 = {};
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;

PaintBrush1.graphic = {
	image = 'assets/images/UX/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	width = 40,
	height = 40	
};

PaintBrush1.incrementor = 0;
PaintBrush1.applyNextFrame = false;
PaintBrush1.touchX = nil;
PaintBrush1.touchY = nil;

PaintBrush1.r = 1.0;
PaintBrush1.g = 0;
PaintBrush1.b = 0;
PaintBrush1.a = 0.05;

PaintBrush1.draw = function(parent, x, y)
	if ((not x) or (not y)) then return; end
	local paint = display.newImageRect(parent, PaintBrush1.graphic.image, PaintBrush1.graphic.width, PaintBrush1.graphic.height);
	paint:setFillColor(PaintBrush1.r, PaintBrush1.g, PaintBrush1.b, PaintBrush1.a);
	paint.anchorX = 0.5; paint.anchorY = 0.5;
	paint.x = x; paint.y = y;
	paint.rotation = math_random(0,359);
	return paint;
end

PaintBrush1.onCanvasTouch = function(self, event)
	if (event.phase == 'began') then
		
		PaintBrush1.points = {};
		table.insert(PaintBrush1.points, { x = event.x, y = event.y });
		PaintBrush1.draw(self.parent.layerDrawing, event.x, event.y);
	
	elseif (event.phase == 'moved') then
		
		table.insert(PaintBrush1.points, { x = event.x, y = event.y });
		local previous = PaintBrush1.points[#PaintBrush1.points-1];
		local current = PaintBrush1.points[#PaintBrush1.points];
		
		local x1 = math_floor(previous.x - ((screenW - ArtCenter.canvasWidth) * 0.5));
		local y1 = math_floor(previous.y - ((screenH - ArtCenter.canvasHeight) * 0.5));
		local x2 = math_floor(current.x - ((screenW - ArtCenter.canvasWidth) * 0.5));
		local y2 = math_floor(current.y - ((screenH - ArtCenter.canvasHeight) * 0.5));
		local path = ArtCenter.finder:getPath(x1, y1, x2, y2);
		
		local distance = math_sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));
		if (distance < (44 * 0.25)) then
			table.remove(PaintBrush1.points, #PaintBrush1.points);
			return;
		end
		
		if (path) then
			local length = path:getLength();
			local thresh = 0; --length - 100;
			for i=1,length do
				if (path._nodes[i]) and (i > thresh) then
					local x = path._nodes[i]:getX() + ((screenW - ArtCenter.canvasWidth) * 0.5);
					local y = path._nodes[i]:getY() + ((screenH - ArtCenter.canvasHeight) * 0.5);
					PaintBrush1.draw(self.parent.layerDrawing, x, y);
					PaintBrush1.points = {};
					table.insert(PaintBrush1.points, { x = event.x, y = event.y });
				end
			end
		else
			table.remove(PaintBrush1.points, #PaintBrush1.points);
		end
	
	elseif (event.phase == 'ended') or (event.phase == 'cancelled') then
		--print('Total plots: ' .. self.parent.layerDrawing.numChildren);		
		PaintBrush1.points = nil;
	end
end

PaintBrush1.onUpdate = function(canvas)
	if true then return; end
	if (PaintBrush1.applyNextFrame) then
		PaintBrush1.draw(canvas.layerDrawing, PaintBrush1.touchX, PaintBrush1.touchY);
		PaintBrush1.touchX = nil;
		PaintBrush1.touchY = nil;
		PaintBrush1.applyNextFrame = false;
	end
end

return PaintBrush1;