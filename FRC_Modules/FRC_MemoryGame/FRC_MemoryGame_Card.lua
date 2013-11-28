local FRC_MemoryGame_Settings = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Settings');
local FRC_MemoryGame_Card = {};

FRC_MemoryGame_Card.disableTouches = false;

local function onCardTouch(event)
	local self = event.target;
	if (FRC_MemoryGame_Card.disableTouches) then return true; end
	if (not self.back.isVisible) then return true; end

	if (event.phase == "began") then
		self:flipToFront();
	end

	return true;
end

local function flipToFront(self)
	FRC_MemoryGame_Card.disableTouches = true;
	if (self.rotateTransition) then transition.cancel(self.rotateTransition); self.rotateTransition = nil; end
	if (self.flipTransition) then transition.cancel(self.flipTransition); self.flipTransition = nil; end

	local result = self.game:dispatchEvent({
		name = "cardFlipToFront",
		target = self.game,
		card = self,
		phase = "began"
	});
	if (not result) then
		FRC_MemoryGame_Card.disableTouches = false;
		return;
	end

	local flipTime = FRC_MemoryGame_Settings.UI.CARD_FLIP_TIME * 0.5;

	self.rotateTransition = transition.to(self, { time=flipTime, rotation=math.random(-2,2) });

	self.flipTransition = transition.to(self.back.path, { time=flipTime, x1=self.contentWidth*0.5, y1=self.contentHeight*0.25, x2=self.contentWidth*0.5, y2 = -(self.contentHeight*0.25), x4=-(self.contentWidth * 0.5), x3=(-self.contentWidth * 0.5), onComplete=function()
		self.back.isVisible = false;

		self.front.path.x1 = self.contentWidth * 0.5;
		self.front.path.y1 = 0;
		self.front.path.x2 = self.contentWidth * 0.5;
		self.front.path.y2 = 0;
		self.front.path.x3 = -(self.contentWidth * 0.5);
		self.front.path.y3 = -(self.contentHeight * 0.25);
		self.front.path.x4 = -(self.contentWidth * 0.5);
		self.front.path.y4 = self.contentHeight * 0.25;
		self.front.isVisible = true;

		self.rotateTransition = transition.to(self, { time=flipTime, rotation=math.random(-2,2), onComplete=function() self.rotateTransition = nil; end });

		self.flipTransition = transition.to(self.front.path, { time=flipTime, x1=0, y1=0, x2=0, y2=0, x3=0, y3=0, x4=0, y4=0, onComplete=function()
			self.flipTransition = nil;
			FRC_MemoryGame_Card.disableTouches = false;
			self.game:dispatchEvent({
				name = "cardFlipToFront",
				target = self.game,
				card = self,
				phase = "ended"
			});
		end });
	end });
end

local function flipToBack(self)
	FRC_MemoryGame_Card.disableTouches = true;
	if (self.rotateTransition) then transition.cancel(self.rotateTransition); self.rotateTransition = nil; end
	if (self.flipTransition) then transition.cancel(self.flipTransition); self.flipTransition = nil; end

	local result = self.game:dispatchEvent({
		name = "cardFlipToBack",
		target = self.game,
		card = self,
		phase = "began"
	});

	local flipTime = FRC_MemoryGame_Settings.UI.CARD_FLIP_TIME * 0.5;

	self.rotateTransition = transition.to(self, { time=flipTime, rotation=math.random(-2,2) });

	self.flipTransition = transition.to(self.front.path, { time=flipTime, x1=self.contentWidth*0.5, y1=0, x2=self.contentWidth*0.5, y2=0, x3=-(self.contentWidth * 0.5), y3=-(self.contentHeight*0.25), x4=-(self.contentWidth*0.5), y4=self.contentHeight*0.25, onComplete=function()
		self.front.isVisible = false;

		self.back.path.x1 = self.contentWidth * 0.5;
		self.back.path.y1 = self.contentHeight * 0.25;
		self.back.path.x2 = self.contentWidth * 0.5;
		self.back.path.y2 = -(self.contentHeight * 0.25);
		self.back.path.x3 = -(self.contentWidth * 0.5);
		self.back.path.y3 = 0;
		self.back.path.x4 = -(self.contentWidth * 0.5);
		self.back.path.y4 = 0
		self.back.isVisible = true;

		self.rotateTransition = transition.to(self, { time=flipTime, rotation=math.random(-2,2), onComplete=function() self.rotateTransition = nil; end });

		self.flipTransition = transition.to(self.back.path, { time=flipTime, x1=0, y1=0, x2=0, y2=0, x3=0, y3=0, x4=0, y4=0, onComplete=function()
			self.flipTransition = nil;
			FRC_MemoryGame_Card.disableTouches = false;
			local result = self.game:dispatchEvent({
				name = "cardFlipToBack",
				target = self.game,
				card = self,
				phase = "ended"
			});
		end });
	end });
end

local function hide(self)
	if (self.rotateTransition) then transition.cancel(self.rotateTransition); self.rotateTransition = nil; end
	if (self.flipTransition) then transition.cancel(self.flipTransition); self.flipTransition = nil; end
	if (self.hideTransition) then transition.cancel(self.hideTransition); self.hideTransition = nil; end

	self.hideTransition = transition.to(self, { time=FRC_MemoryGame_Settings.UI.CARD_HIDE_TIME, alpha=0, onComplete=function()
		self.hideTransition = nil;

		self.game:dispatchEvent({
			name = "cardDisappear",
			target = self.game,
			card = self
		});
	end});
end

local function dispose(self)
	if (self.rotateTransition) then transition.cancel(self.rotateTransition); self.rotateTransition = nil; end
	if (self.flipTransition) then transition.cancel(self.flipTransition); self.flipTransition = nil; end
	if (self.hideTransition) then transition.cancel(self.hideTransition); self.hideTransition = nil; end
	self:removeSelf();
end

FRC_MemoryGame_Card.new = function(gameGroup, id, image, x, y)
	local cardGroup = display.newGroup();

	local cardWidth = FRC_MemoryGame_Settings.UI.CARD_WIDTH;
	local cardHeight = FRC_MemoryGame_Settings.UI.CARD_HEIGHT;

	local cardfront = display.newSnapshot(cardGroup, cardWidth, cardHeight);
	local frontBg = display.newImageRect(cardfront.group, FRC_MemoryGame_Settings.UI.CARDFRONT_IMAGE, cardWidth, cardHeight);
	local frontImage = display.newImage(image);
	frontImage.xScale = (cardWidth - 20) / frontImage.width;
	frontImage.yScale = frontImage.xScale;
	cardfront.group:insert(frontImage);

	cardfront.isVisible = false;
	local cardback = display.newImageRect(cardGroup, FRC_MemoryGame_Settings.UI.CARDBACK_IMAGE, cardWidth, cardHeight);

	gameGroup:insert(cardGroup);
	cardGroup.x = x or 0;
	cardGroup.y = y or 0;

	-- touch listener
	cardGroup:addEventListener('touch', onCardTouch);

	-- properties and methods
	cardGroup.id = id;
	cardGroup.game = gameGroup;
	cardGroup.front = cardfront;
	cardGroup.back = cardback;
	cardGroup.flipToFront = flipToFront;
	cardGroup.flipToBack = flipToBack;
	cardGroup.hide = hide;
	cardGroup.dispose = dispose;

	return cardGroup;
end

return FRC_MemoryGame_Card;