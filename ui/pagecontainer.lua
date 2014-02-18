local ui = require('ui');
local pagecontainer = {};

-- cached functions
local math_abs = math.abs;

-- PUBLIC FUNCTIONS

pagecontainer.new = function(options)
	local view = display.newContainer(options.width, options.height);
	view._uiType = 'pagecontainer';
	view.ignoreMultiTouch = true;
	
	view.bg = display.newRect(view, 0, 0, options.width, options.height);
	view.bg.x, view.bg.y = 0, 0;
	view.bg.isVisible = false;
	view.bg.isHitTestable = true;
	view.pages = display.newGroup(); view:insert(view.pages);
	view.indicator = display.newGroup(); view:insert(view.indicator);
	view.border = display.newRect(view, 0, 0, options.width, options.height);
	view.border.x, view.border.y = 0, 0;
	view.border:setFillColor(1.0, 1.0, 1.0, 0);
	view.border:setStrokeColor(options.borderColor[1], options.borderColor[2], options.borderColor[3], options.borderColor[4]);
	view.border.strokeWidth = options.borderWidth;

	view.borderWidth = options.borderWidth;
	view.pageIndicatorRadius = options.pageIndicatorRadius;
	view.pageIndicatorColor = options.pageIndicatorColor;
	view.pageIndicatorSpacing = options.pageIndicatorSpacing;
	view.defaultPageBgColor = options.defaultPageBgColor;

	view._focusTouch = pagecontainer._focusTouch;
	view.showPageIndicator = pagecontainer.showPageIndicator;
	view.hidePageIndicator = pagecontainer.hidePageIndicator;
	view.updatePageIndicator = pagecontainer.updatePageIndicator;
	view.updatePagePositions = pagecontainer.updatePagePositions;
	view.gotoPage = pagecontainer.gotoPage;
	view.getPage = pagecontainer.getPage;
	view.addPage = pagecontainer.addPage;
	view.removePage = pagecontainer.removePage;
	view.dispose = pagecontainer.dispose;

	view.handleTouch = function(event)
		if (event.phase == "began") then
			view.bg._markTime = event.time;
		elseif (event.phase == "moved") then
			local dt = math_abs(view.bg._markTime - event.time);
			local dx = event.x - event.xStart;
			local direction = 0;
			if (dx < 0) then
				direction = -1;
			elseif (dx > 0) then
				direction = 1;
			end
			dx = math_abs(dx);

			if ((dx > 75) and (dt <= 275) and (direction ~= 0) and (view.pages.numChildren > 1)) then
				if (direction == -1) then
					-- SWIPE LEFT
					if (view.activePage < view.pages.numChildren) then
						view:gotoPage(view.activePage + 1);
					end
				else
					-- SWIPE RIGHT

					if (view.activePage > 1) then
						view:gotoPage(view.activePage - 1);
					end
				end
				view.bg._markTime = 0;
			end
		end
		return true;
	end
	view.bg:addEventListener('touch', view.handleTouch);
	
	ui:addDisposable(view);
	return view;
end

pagecontainer._focusTouch = function(self, event)
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
		y = event.y,
		time = event.time
	};
	nextTarget:dispatchEvent(e);
end

pagecontainer.showPageIndicator = function(self)
	self.indicator.isVisible = true;
end

pagecontainer.hidePageIndicator = function(self)
	self.indicator.isVisible = false;
end

pagecontainer.updatePageIndicator = function(self, activePage)
	if (not self.activePage) then return; end

	if (activePage) then
		self.activePage = activePage;
	end

	for i=1,self.indicator.numChildren do
		if (i == self.activePage) then
			self.indicator[i].alpha = 1.0;
		else
			self.indicator[i].alpha = 0.35;
		end
	end
	if (self.indicator.numChildren <= 1) then
		self.indicator.isVisible = false;
	else
		self.indicator.isVisible = true;
	end

	self.indicator.x = 0;
	self.indicator.y = (self.height * 0.5) - (self.pageIndicatorRadius) - (self.pageIndicatorSpacing);
end

pagecontainer.updatePagePositions = function(self)
	local width = self.width;
	local x = 0;

	for i=1,self.pages.numChildren do
		if (i == self.activePage) then
			self.pages[i].isVisible = true;
		else
			self.pages[i].isVisible = false;
		end
		self.pages[i].x = x;
		x = x + width;
	end
	self.pages.x = -(self.pages[self.activePage].x);
end

pagecontainer.gotoPage = function(self, index)
	if (not self.pages[index]) then return; end
	self.pages[index].isVisible = true;
	self.pageTransition = ui:newTransition(self.pages, {
		x = -(self.pages[index].x),
		time = 200,
		transition = easing.inOutExpo,
		onComplete = function()
			self.pageTransition = ui:cancelTransition(self.pageTransition);
			self:updatePageIndicator(index);
			self:updatePagePositions();
		end
	});
end

pagecontainer.getPage = function(self, index)
	return self.pages[index];
end

pagecontainer.addPage = function(self, options)
	options = options or {};

	local index = options.index or (self.pages.numChildren + 1);
	local pageView = display.newContainer(self.width, self.height);
	self.pages:insert(index, pageView);

	local bgRect = display.newRect(pageView, 0, 0, pageView.width, pageView.height);
	local bgColor = options.pageBgColor or self.defaultPageBgColor;
	bgRect:setFillColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or self.defaultPageBgColor[4]);
	bgRect.x, bgRect.y = 0, 0;

	-- add a new dot to the page indicator
	local dot = display.newCircle(self.indicator, 0, 0, self.pageIndicatorRadius);
	dot:setFillColor(self.pageIndicatorColor[1], self.pageIndicatorColor[2], self.pageIndicatorColor[3]);
	dot.x = (self.pages.numChildren - 1) * ((self.pageIndicatorRadius * 2) + self.pageIndicatorSpacing);
	dot.y = 0;

	if (self.pages.numChildren == 1) then
		self.activePage = 1;
		dot.alpha = 1.0;
	else
		if (index == self.activePage) then
			self.activePage = self.activePage + 1;
		end
		dot.alpha = 0.35;
	end

	self:updatePagePositions();
	self:updatePageIndicator();

	return pageView;
end

pagecontainer.removePage = function(self, index)
	self.pages[index]:removeSelf();
	self.indicator[self.indicator.numChildren]:removeSelf();
	self:updatePagePositions();
	self:updatePageIndicator();
end

pagecontainer.dispose = function(self)
	self.pageTransition = ui:cancelTransition(self.pageTransition);
	if (self.removeSelf) then self:removeSelf(); end
end

return pagecontainer;