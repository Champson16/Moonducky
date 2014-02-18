local ui = require('ui');
local scrollcontainer = {};

-- cached functions
math_floor = math.floor;
math_abs = math.abs;

-- PUBLIC FUNCTIONS

scrollcontainer.new = function(options)
	local view = display.newContainer(options.width, options.height);
	view.anchorChildren = true;
	view._uiType = 'scrollcontainer';

	-- if bgColor option is set, create a rectangle and insert directly into container (behind content group)
	local rect = display.newRect;
	if (options.borderRadius > 0) then
		rect = display.newRoundedRect;
	end
	local bg = rect(-(options.width * 0.5), -(options.height * 0.5), options.width, options.height, options.borderRadius);
	if ((options.bgColor) and (type(options.bgColor) == "table") and (#options.bgColor >= 3)) then
		bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], options.bgColor[4] or 1.0);
	else
		bg:setFillColor(1, 1, 1);
	end

	if (options.borderWidth > 0) then
		bg:setStrokeColor(options.borderColor[1], options.borderColor[2], options.borderColor[3], options.borderColor[4] or 1);
		bg.strokeWidth = options.borderWidth;
	end

	view:insert(bg, true);
	view.bg = bg;
	bg:addEventListener("touch", scrollcontainer.touch);

	view.content = display.newGroup();
	view:insert(view.content, false);

	view.dispose = scrollcontainer.dispose;

	view.insert = function(self, obj)
		view.content:insert(obj);
	end

	-- set properties (or use defaults)
	for k,v in pairs(options) do
		if (options[k]) then
			view[k] = options[k];
		else
			view[k] = v;
		end
	end

	view._focusTouch = scrollcontainer._focusTouch;
	view.scrollToX = scrollcontainer.scrollToX;

	view._trackingVelocity = false;
	view._prevTime = 0;
	view._markTime = 0;
	view._velocity = 0;
	view._friction = 0.9; --0.935;
	view._moveDirection = nil; -- 'x': horizontal; 'y': vertical

	view.limitMovement = function()
		local content = view.content;
		local containerBounds = view.contentBounds;
		local contentAtLimit = false;

		if (view.xScroll) then
			if (view.contentWidth < content.contentWidth) then
				local left = containerBounds.xMin + view.leftPadding;
				local right = containerBounds.xMax - view.rightPadding;

				if (content.contentBounds.xMin > left) then
					content.x = content.x - (content.contentBounds.xMin - left);
					contentAtLimit = true;
				elseif (content.contentBounds.xMax < right) then
					content.x = content.x + (right - content.contentBounds.xMax);
					contentAtLimit = true;
				end
			end
		end

		if (view.yScroll) then
			if (view.contentHeight < content.contentHeight) then
				local top = containerBounds.yMin + view.topPadding;
				local bottom = containerBounds.yMax - view.bottomPadding;

				if (content.contentBounds.yMin > top) then
					content.y = content.y - (content.contentBounds.yMin - top);
					contentAtLimit = true;
				elseif (content.contentBounds.yMax < bottom) then
					content.y = content.y + (bottom - content.contentBounds.yMax);
					contentAtLimit = true;
				end
			end
		end

		return contentAtLimit;
	end

	-- enterframe listener for view
	view.enterframe = function(event)
		local time = event.time;
		local timePassed = time - view._prevTime;
		view._prevTime = time;

		if ((not view.isVisible) or (not view.content.isVisible)) then
			view._velocity = 0;
			view._moveDirection = nil;
			Runtime:removeEventListener('enterFrame', view.enterframe);
			return;
		end

		if ((not view._trackingVelocity) and (view._moveDirection)) then
			-- handle scrolling based on velocity
			if (math_abs(view._velocity) >= 0.2) then
				view._velocity = view._velocity * view._friction;
				view.content[view._moveDirection] = view.content[view._moveDirection] + (view._velocity * timePassed);
			else
				-- scroller has stopped movement
				view._velocity = 0;
				view._moveDirection = nil;
				Runtime:removeEventListener("enterFrame", view.enterframe);
			end
		end

		local contentAtLimit = view.limitMovement();
		if (contentAtLimit) then
			view._velocity = 0;
			view._moveDirection = nil;
			Runtime:removeEventListener("enterFrame", view.enterframe);
		end
	end

	ui:addDisposable(view);
	return view;
end

scrollcontainer.scrollToX = function(self, x)
	if (not x) then return; end
	if (self.scrollTransition) then transition.cancel(self.scrollTransition); self.scrollTransition = nil; end

	local containerBounds = self.contentBounds;
	local left = containerBounds.xMin + self.leftPadding;
	local right = containerBounds.xMax - self.rightPadding;

	local origin_xMin = self.content.contentBounds.xMin - self.content.x;
	local origin_xMax = self.content.contentBounds.xMax - self.content.x;
	local target_xMin = origin_xMin + x;
	local target_xMax = origin_xMax + x;

	if (target_xMin > left) then
		x = x - (target_xMin - left);
	elseif (target_xMax < right) then
		x = x + (right - target_xMax);
	end

	--print(containerBounds.xMin, current_xMin, current_xMax, self.leftPadding);

	self.scrollTransition = transition.to(self.content, { time = 200, x=x, transition=easing.inOutExpo, onComplete=function()
		self.scrollTransition = nil;
	end })
end

scrollcontainer._focusTouch = function(self, event)
	local target = event.target;
		
	-- if button, restore back to "default" state
	if ((target._uiType) and (target._uiType == "button")) then
		target:release();
	end

	-- remove focus from target
	display.getCurrentStage():setFocus(nil);
	target._hasFocus = false;
	if (target.isFocus) then target.isFocus = nil; end
	
	-- set event.target to scrollView and start back at "began" phase
	local nextTarget = self.bg or self;
	local e = {
		name = event.name,
		target = nextTarget,
		phase = "began",
		x = event.x,
		y = event.y
	};
	nextTarget:dispatchEvent(e);
end

scrollcontainer.touch = function(event)
	local self = event.target;
	local view = self.parent;
	local content = view.content;

	if ((event.phase == "began") and (view.isVisible) and (content.isVisible)) then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;

		self.markX = content.x;
		self.markY = content.y;

		-- Remove enterFrame listener first (to prevent unintended duplicate listeners being added)
		Runtime:removeEventListener("enterFrame", view.enterframe);

		view._velocity = 0;
		view._trackingVelocity = true;
		view._eventX = event.x;
		view._eventY = event.y;
		view._markX = view.content.x;
		view._markY = view.content.y;
		view._markTime = event.time or 0;
		view._eventStep = 0;

		Runtime:addEventListener("enterFrame", view.enterframe);

	elseif (self._hasFocus) then
		if (event.phase == "moved") then

			if (self.parent.scrollLock) then return true; end
			local containerBounds = self.parent.contentBounds;
			local contentBounds = content.contentBounds;
			local dx = (event.x - event.xStart) + self.markX;
			local dy = (event.y - event.yStart) + self.markY;
			local mark, scrollable;

			if (self.parent.xScroll) then
				if (self.parent.contentWidth < content.contentWidth) then
					content.x = dx;
					local left = containerBounds.xMin + self.parent.leftPadding;
					local right = containerBounds.xMax - self.parent.rightPadding;

					if (content.contentBounds.xMin > left) then
						content.x = content.x - (content.contentBounds.xMin - left);
					elseif (content.contentBounds.xMax < right) then
						content.x = content.x + (right - content.contentBounds.xMax);
					end
					view._moveDirection = 'x';
					mark = "_markX";
					scrollable = true;
				else
					scrollable = false;
				end
			end

			if (self.parent.yScroll) then
				if (self.parent.contentHeight < content.contentHeight) then
					content.y = dy;
					local top = containerBounds.yMin + self.parent.topPadding;
					local bottom = containerBounds.yMax - self.parent.bottomPadding;

					if (content.contentBounds.yMin > top) then
						content.y = content.y - (content.contentBounds.yMin - top);
					elseif (content.contentBounds.yMax < bottom) then
						content.y = content.y + (bottom - content.contentBounds.yMax);
					end
					view._moveDirection = 'y';
					mark = "_markY";
					scrollable = true;
				end
			end

			if ((view._moveDirection) and (scrollable)) then
				view._velocity = (view.content[view._moveDirection] - view[mark]) / (event.time - view._markTime);
				view._markTime = event.time or 0;
				view[mark] = view.content[view._moveDirection];
			else
				Runtime:removeEventListener("enterFrame", view.enterframe);
			end

		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then

			view._prevTime = event.time;
			view._trackingVelocity = false;
			view._markTime = 0;

			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
		end
	elseif ((event.phase == "cancelled") or (event.phase == "ended")) then
		view._prevTime = event.time;
		view._trackingVelocity = false;
		view._markTime = 0;
		
		display.getCurrentStage():setFocus(nil);
		self._hasFocus = false;
	end
	return true;
end

scrollcontainer.dispose = function(self)
	Runtime:removeEventListener('enterFrame', self.enterframe);
	if (self.scrollTransition) then transition.cancel(self.scrollTransition); self.scrollTransition = nil; end
	if (self.removeSelf) then self:removeSelf(); end
end

return scrollcontainer;