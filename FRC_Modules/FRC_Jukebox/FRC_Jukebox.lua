local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require('ui');
local settings = require('FRC_Modules.FRC_Jukebox.FRC_Jukebox_Settings');

local FRC_Jukebox = {};

FRC_Jukebox.new = function(options)
	options = options or {};
	local group = display.newGroup();

	local cancelTouch = function(e)
		if (e.phase == 'began') then
			group:dispatchEvent({ name = "cancelled" });
         if( options and options.onCancel ) then
            options.onCancel()
         end
			group:dispose();
		end
		return true;
	end

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local dimRect = display.newRect(group, 0, 0, screenW, screenH);
	dimRect:setFillColor(0, 0, 0, 0.5);
	dimRect:addEventListener('touch', cancelTouch);
	dimRect:addEventListener('tap', cancelTouch);

  -- setup the background animation
	-- setup the frame
	-- close box
	-- startover control
	-- pause control
	-- ticker box
	-- ticker text
	local tickerText = "Coming in the next build will be an interactive Jukebox which will show song titles in a ticker display like this!"

	local chunkSize=160
	-- This variable defines the number of characters by which to divide long ticker text
	-- strings. This prevents errors by ensuring that your ticker's width doesn't exceed the
	-- device's maximum display object width. If your ticker isn't displaying properly, decrease
	-- this number. But unless you are using an absurdly large font, you shouldn't need to adjust
	-- this variable.

	local tickerGroup = display.newGroup();

	local startTickerTextCrawl = function()

		local tickerLength = string.len(tickerText)
		local objectCount = math.ceil(tickerLength/chunkSize)

		for i=1,objectCount do
			local ticker = display.newText(string.sub(tickerText, chunkSize*(i-1)+1, chunkSize*i),0,0,"ticker",24)

			if (i == 1) then
				ticker.x = display.contentWidth; -- TODO change this
			else
				ticker.x = tickerGroup[i-1].x + tickerGroup[i-1].contentWidth
			end

			ticker.y = display.contentHeight-25
			ticker:setTextColor(255,255,255)
			tickerGroup:insert(ticker)
			ticker = nil
		end

		local textMove = function()
			if tickerGroup then
				if tickerGroup.x + tickerGroup.contentWidth + display.contentWidth > 0 then
					tickerGroup:translate(-3,0)
				else
					tickerGroup.x = display.contentWidth; -- 0;
				end
			end
		end

		Runtime:addEventListener("enterFrame",textMove)
	end
	FRC_Jukebox.startTickerTextCrawl = startTickerTextCrawl;

	local stopTickerTextCrawl = function()
		Runtime:removeEventListener("enterFrame",textMove);
		tickerGroup:removeSelf();
		tickerGroup = nil;
	end
	FRC_Jukebox.stopTickerTextCrawl = stopTickerTextCrawl;

	startTickerTextCrawl(); -- Loads and starts the Text Ticker

	-- selection box
	-- prev media selector
	-- left media selector
	-- right media selector
	-- next media selector


	local thumbImage, baseDirectory, thumbWidth, thumbHeight;
	thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
	thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
	local largestThumbWidth = thumbWidth;
	local largestThumbHeight = thumbHeight;

  local pageCount = settings.DEFAULTS.TOTAL_PAGES;
	local j = 1;
	local removeIndexes = {};
	for i=1,pageCount do
		local x, y = 0, 0;
		local max = 0; --settings.UI.PER_PAGE_ROWS * settings.UI.PER_PAGE_COLS;
		if (options.data) then
			max = #options.data;
		end

		local blankCount = 0;
		local totalThumbs = settings.DEFAULTS.PER_PAGE_ROWS * settings.DEFAULTS.PER_PAGE_COLS;

		for row=1,settings.DEFAULTS.PER_PAGE_ROWS do
			x = 0;
			for col=1,settings.DEFAULTS.PER_PAGE_COLS do
				local baseDirectory = system.ResourceDirectory;
				local id = nil;
				local item;

				if ((options.data) and (options.data[j])) then
					item = options.data[j];
					id = item.id;
					thumbImage = id .. item.thumbSuffix;
					if (item.thumbWidth > thumbWidth) then
						largestThumbWidth = item.thumbWidth;
					end
					if (item.thumbHeight > thumbHeight) then
						largestThumbHeight = item.thumbHeight;
					end
					thumbWidth = item.thumbWidth;
					thumbHeight = item.thumbHeight;
					baseDirectory = system.DocumentsDirectory;
				else
					id = nil;
					thumbImage = settings.DEFAULTS.BLANK_SLOT_IMAGE;
					if (settings.DEFAULTS.BLANK_SLOT_WIDTH > thumbWidth) then
						largestThumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					end
					if (settings.DEFAULTS.BLANK_SLOT_HEIGHT > thumbHeight) then
						largestThumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					end
					thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					baseDirectory = system.ResourceDirectory;
				end

				local thumbButton = ui.button.new({
					id = id,
					baseDirectory = baseDirectory,
					imageUp = thumbImage,
					imageDown = thumbImage,
					width = thumbWidth,
					height = thumbHeight,
					pressAlpha = 0.5,
					onRelease = function(e)
						local self = e.target;
						local function proceedToPlay()
							--[[if (options.callback) then
								options.callback({
									id = self.id,
									page = i,
									row = row,
									column = col,
									data = item
								});
						--]]
							end
						proceedToPlay();
					end
				});
			end
		end
	end

	if (#removeIndexes > 0) then
		for i=#removeIndexes,1,-1 do
			popup:removePage(removeIndexes[i]);
		end
	end

	group.dispose = FRC_Jukebox.dispose;

	if (options.title) then
		local titleText = display.newText(popup, options.title, 0, 0, native.systemFontBold, 36);
		titleText:setFillColor(0, 0, 0, 1.0);
		titleText.x = 0;
		titleText.y = -(popup.height * 0.5) + (titleText.contentHeight * 0.5) + (settings.DEFAULTS.THUMBNAIL_SPACING);
	end

	if (options.parent) then options.parent:insert(group); end
	group.x, group.y = display.contentCenterX, display.contentCenterY;
	return group;

end

FRC_Jukebox.dispose = function(self)
	FRC_Jukebox.stopTickerTextCrawl();
	if (self.removeSelf) then self:removeSelf(); end
end

return FRC_Jukebox;
