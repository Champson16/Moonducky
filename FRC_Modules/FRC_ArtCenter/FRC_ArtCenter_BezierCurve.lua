local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local BezierCurve = {}
BezierCurve.imageFile = nil;
BezierCurve.blotWidth = 32;
BezierCurve.blotHeight = 32;
BezierCurve.blotColor = {1.0, 0, 1.0, 1.0};
local math_abs = math.abs;
local math_random = math.random;

local function swap(a,b)
	local temp = b
	b = a
	a = temp
	return a, b
end

local display_newLine = function(...)
	local parent, x0, y0, x1, y1, blotRotation;
	if (#arg == 6) then
		parent = arg[1]; x0 = arg[2]; y0 = arg[3]; x1 = arg[4]; y1 = arg[5]; blotRotation = arg[6];
	else
		x0 = arg[1]; y0 = arg[2]; x1 = arg[3]; y1 = arg[4]; blotRotation = arg[5];
	end

	local steep = false
    if math_abs(y1 - y0) > math_abs(x1 - x0) then steep = true end

    if steep then
		x0, y0 = swap(x0, y0)
		x1, y1 = swap(x1, y1)
	end

	if x0 > x1 then
		x0, x1 = swap(x0, x1)
		y0, y1 = swap(y0, y1)
	end

	local deltax = x1 - x0
	local deltay = math_abs(y1 - y0)
	local err = deltax / 2
	local ystep = 0
	local y = y0
	if y0 < y1 then ystep = 1 else ystep = -1 end

	for x=x0,x1 do
		local c;
		if steep then
			if (BezierCurve.imageFile) then
				c = display.newImage(BezierCurve.imageFile);
			else
				c = display.newImage(FRC_ArtCenter_Settings.UI.ERASER_BRUSH);
				c.fill.blendMode = { srcColor = "zero", dstColor="oneMinusSrcAlpha" };
				blotRotation = false;
			end
		else
			if (BezierCurve.imageFile) then
				c = display.newImage(BezierCurve.imageFile);
			else
				c = display.newImage(FRC_ArtCenter_Settings.UI.ERASER_BRUSH);
				c.fill.blendMode = { srcColor = "zero", dstColor="oneMinusSrcAlpha" };
				blotRotation = false;
			end
		end
		c:setFillColor(BezierCurve.blotColor[1], BezierCurve.blotColor[2], BezierCurve.blotColor[3], BezierCurve.blotColor[4]);
		c.xScale = BezierCurve.blotWidth / c.width;
		c.yScale = BezierCurve.blotHeight / c.height;
		c.strokeWidth = 0;
		c:setStrokeColor(1.0, 0, 1.0, 0);
		c.anchorX = 0.5; c.anchorY = 0.5;
		if (steep) then
			c.x = y; c.y = x;
		else
			c.x = x; c.y = y;
		end
		if (blotRotation) then c:rotate(math_random(0,359)); end

		if (parent) then parent:insert(c); end
		err = err - deltay
		if err < 0 then
			y = y + ystep
			err = err + deltax
		end
	end
end

function BezierCurve.new(parent, p0, c0, p1, c1, blotRotation)
	-- Creates Instance
	local self = {}
	
	--==============================
	-- Local Functions
	--==============================
	
	-- Returns the square distance between two points
	local function sqDist(pt0, pt1)
		local dx = pt0.x - pt1.x
		local dy = pt0.y - pt1.y
		return dx*dx + dy*dy
	end
	
	-- Calculates line segments and draws them (into specified parent)
	local function drawBezier(granularity, r, g, b)
		-- Setup Variables
		granularity = granularity or 50
		r = r or 1.0
		g = g or 1.0
		b = b or 1.0
		local segments = {}
		local p = bezierPoints
		local inc = (1.0 / granularity)
		local t = 0
		local t1 = 0
		
		-- For granularity, complete crazy formula to compute segments
		for i = 1, granularity do
			t1 = 1.0 - t
			local x = (t1*t1*t1) * p0.x
			x = x + (3*t)*(t1*t1) * c0.x
			x = x + (3*t*t)*(t1) * c1.x
			x = x + (t*t*t) * p1.x
			
			local y = (t1*t1*t1) * p0.y
			y = y + (3*t)*(t1*t1) * c0.y
			y = y + (3*t*t)*(t1) * c1.y
			y = y + (t*t*t) * p1.y
			
			table.insert(segments, {x = x, y = y})
			t = t + inc
		end
		
		-- Add last segment if it doesn't quite reach the last point
		if (sqDist(segments[#segments],p1) < 10*10) then --if close, just change last point to end point
			segments[#segments] = {x = p1.x, y = p1.y}
		else --otherwise, add the last point
			table.insert(segments, {x = p1.x, y = p1.y})
		end
		
		-- Remove previous bezierCurve and draw segments
		display_newLine(parent, segments[1].x, segments[1].y, segments[2].x, segments[2].y, blotRotation)
		local lastPoint = { x=segments[2].x, y=segments[2].y };
		for i = 3, #segments do
			display_newLine(parent, lastPoint.x, lastPoint.y, segments[i].x, segments[i].y, blotRotation);
			lastPoint = { x=segments[i].x, y=segments[i].y };
		end
	end
	
	--==============================
	-- Constructor
	--==============================
	drawBezier(2)
	
	-- Return Instance
	return self
end

return BezierCurve