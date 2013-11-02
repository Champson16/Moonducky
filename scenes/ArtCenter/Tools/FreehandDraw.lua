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

FreehandDraw.onCanvasTouch = function(self, event)
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

		if (not _G.COMPAT_DRAWING_MODE) then
			local bounds = {
				xMin = self.parent.layerDrawing.contentBounds.xMin,
				yMin = self.parent.layerDrawing.contentBounds.yMin,
				xMax = self.parent.layerDrawing.contentBounds.xMax,
				yMax = self.parent.layerDrawing.contentBounds.yMax
			};
			self.parent.layerBgImage.isVisible = false;
			local capture = display.captureBounds(bounds);
			self.parent.layerBgImage.isVisible = true;
			capture.x = 0;
			capture.y = 0;
			self.parent.drawingBuffer.group:insert(capture);
			self.parent.drawingBuffer:invalidate();

			for i=self.parent.layerDrawing.group.numChildren,1,-1 do
				self.parent.layerDrawing.group[i]:removeSelf();
				self.parent.layerDrawing.group[i] = nil;
			end
			self.parent.layerDrawing:invalidate();
			collectgarbage("collect");
		else
			-- [[ TODO: once display.captureBounds works on device, remove the following
			self.parent.layerDrawing = display.newSnapshot(self.parent.width, self.parent.height);
			self.parent.layerDrawing.x = self.parent.x;
			self.parent.layerDrawing.y = self.parent.y;
			self.parent.snapshots[#self.parent.snapshots+1] = self.parent.layerDrawing;
			
			timer.performWithDelay(20, function()
				local previousSnapshotGroup = self.parent.snapshots[#self.parent.snapshots-1].group;
				local num = previousSnapshotGroup.numChildren;
				for i=previousSnapshotGroup.numChildren,1,-1 do
					previousSnapshotGroup[i]:removeSelf();
					previousSnapshotGroup[i] = nil;
				end
				collectgarbage("collect");
			end, 1);

			self.parent.layerBgImage:toFront();
			--]]
		end
	end
end

return FreehandDraw;