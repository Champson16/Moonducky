local ui = require('ui');
local movieclip = {};

-- PUBLIC FUNCTIONS

movieclip.new = function(options)
	local view = display.newGroup();
	view.currentIndex = 1;
	view.intervalTime = 100;
	view._uiType = 'movieclip';
	
	for i=1,#options.images do
		local frame = display.newImageRect(view, options.images[i], options.width, options.height);
		frame.x = 0;
		frame.y = 0;
	end
	
	view.showFrame = movieclip.showFrame;
	view.gotoNext = movieclip.gotoNext;
	view.play = movieclip.play;
	view.stop = movieclip.stop;
	view.dispose = movieclip.dispose;
	
	ui:addDisposable(view);
	return view;
end

movieclip.showFrame = function(self, index)
	if ((not self) or (not self.numChildren) or (type(self.numChildren) ~= 'number')) then return; end
	if (index > self.numChildren) then
		index = 1;
	end
	for i=self.numChildren,1,-1 do
		if (i == index) then
			self[i].isVisible = true;
		else
			self[i].isVisible = false;
		end
	end
	self.currentIndex = index;
end

movieclip.gotoNext = function(self)
	local nextIndex = self.currentIndex + 1;
	if ((self.numChildren) and (nextIndex > self.numChildren)) then
		self.iterations = self.iterations + 1;
		nextIndex = 1;

		if ((self.iterations > self.maxIterations) and (self.maxIterations > 0)) then
			self.iterations = 0;
			ui:cancelTimer(self.animationTimer);
			self.animationTimer = nil;
		else
			if (self.delayTime) then
				ui:cancelTimer(self.animationTimer);
				self.animationTimer = ui:newTimer(self.delayTime, function()
					self.animationTimer = ui:newTimer(self.intervalTime, function() self:gotoNext(); end, 0);
				end, 1);
			end
		end
	end
	self:showFrame(nextIndex);
end

movieclip.play = function(self, options)
	self.maxIterations = 0;
	if (options.noLoop) then
		self.maxIterations = self.numChildren - self.currentIndex;
		if (self.maxIterations <= 0) then
			self.maxIterations = 1;
		end
	end
	
	if (options.startFrame) then
		self:showFrame(options.startFrame);
	end
	
	if (options.intervalTime) then
		self.intervalTime = options.intervalTime;
	end
	
	ui:cancelTimer(self.animationTimer); self.animationTimer = nil;
	self.iterations = 0;
	self.delayTime = options.delay or nil;
	self.currentIndex = 0;
	
	if (self.delayTime) then
		self.animationTimer = ui:newTimer(self.delayTime, function()
			self.animationTimer = ui:newTimer(self.intervalTime, function() self:gotoNext(); end, 0);
		end, 1);
	else
		self.animationTimer = ui:newTimer(self.intervalTime, function() self:gotoNext(); end, 0);
	end
end

movieclip.stop = function(self, atFrame)
	ui:cancelTimer(self.animationTimer); self.animationTimer = nil;	
	if (atFrame) then self:showFrame(atFrame); end
end

movieclip.dispose = function(self)
	ui:cancelTimer(self.animationTimer); self.animationTimer = nil;
	if (self.removeSelf) then self:removeSelf(); end
end

return movieclip;