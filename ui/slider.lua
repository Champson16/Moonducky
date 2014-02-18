local ui = require('ui');
local slider = {};

-- PRIVATE FUNCTIONS

local function format_num(amount, decimal, prefix, neg_prefix)
	function comma_value(amount)
		local formatted = amount
		while true do  
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
		  		break
			end
		end
		return formatted
	end

	function round(val, decimal)
		if (decimal) then
			return math_floor( (val * 10^decimal) + 0.5) / (10^decimal)
		else
			return math_floor(val+0.5)
		end
	end
	local str_amount,  formatted, famount, remain

	decimal = decimal or 2  -- default 2 decimal places
	neg_prefix = neg_prefix or "-" -- default negative sign

	famount = math_abs(round(amount,decimal))
	famount = math_floor(famount)

	remain = round(math_abs(amount) - famount, decimal)

	    -- comma to separate the thousands
	formatted = comma_value(famount)

	    -- attach the decimal portion
	if (decimal > 0) then
		remain = string.sub(tostring(remain),3)
		formatted = formatted .. "." .. remain .. string.rep("0", decimal - string.len(remain))
	end

	    -- attach prefix string e.g '$' 
	formatted = (prefix or "") .. formatted 

	    -- if value is negative then format accordingly
	if (amount<0) then
		if (neg_prefix=="()") then
			formatted = "("..formatted ..")"
		else
			formatted = neg_prefix .. formatted 
		end
	end

	return formatted
end

-- PUBLIC FUNCTIONS

slider.new = function(options)
	local view = display.newGroup();
	view.min = options.min or 0;
	view.max = options.max or 100;
	view.value = options.startValue or 50;
	view._uiType = 'slider';

	local bg = display.newRoundedRect(view, 0, 0, options.width, options.height, 4);
	bg:setFillColor(options.sliderColor[1], options.sliderColor[2], options.sliderColor[3], options.sliderColor[4] or 1.0);

	local handle = display.newCircle(view, 0, 0, options.handleRadius);
	handle:setFillColor(options.handleColor[1], options.handleColor[2], options.handleColor[3], options.handleColor[4] or 1.0);
	handle:addEventListener('touch', slider.touch);
	handle.minX = -(options.width * 0.5) + (handle.contentWidth * 0.5) - 2;
	handle.maxX = (options.width * 0.5) - (handle.contentWidth * 0.5) + 2;
	handle.range = handle.maxX - handle.minX;
	view.handle = handle;
	view.setValue = slider.setValue;
	view.dispose = slider.dispose;

	-- position handle at correct starting location
	local startDecimalValue = format_num((view.value - view.min) / (view.max - view.min), 2);
	handle.x = handle.minX + ((handle.maxX - handle.minX) * startDecimalValue);
	view.percent = math_floor(startDecimalValue * 100);
	
	ui:addDisposable(view);
	return view;
end

slider.setValue = function(self, value)
	self.value = value;
	
	local decimalValue = format_num((self.value - self.min) / (self.max - self.min), 2);
	self.handle.x = self.handle.minX + ((self.handle.maxX - self.handle.minX) * decimalValue);
	self.percent = math_floor(decimalValue * 100);
end

slider.touch = function(event)
	local self = event.target;
	local slider = self.parent;
	local width = slider.contentWidth;

	if (event.phase == "began") then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;
		self.markX = self.x;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then
			local x = (event.x - event.xStart) + self.markX;
			if (x < self.minX) then x = self.minX; end
			if (x > self.maxX) then x = self.maxX; end
			self.x = x;

			local decimalValue = format_num((self.x - self.minX) / self.range, 2);
			slider.value = slider.min + ((slider.max - slider.min) * decimalValue);
			slider.percent = math_floor(decimalValue * 100);
			
			local endTouch = slider:dispatchEvent({
				name = "change",
				target = slider,
				value = slider.value,
				percent = slider.percent,
				handle = self
			});
			
			if (endTouch == true) then
				self._hasFocus = false;
				display.getCurrentStage():setFocus(nil);
				return true;
			end
		else
			slider:dispatchEvent({
				name = "touchEnded",
				target = slider,
				value = slider.value,
				percent = slider.percent,
				handle = self
			});
			self._hasFocus = false;
			display.getCurrentStage():setFocus(nil);
		end
	end

	return true;
end

slider.dispose = function(self)
	if (self.removeSelf) then self:removeSelf(); end
end

return slider;