local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require('ui');
local settings = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup_Settings');

local FRC_GalleryPopup = {};

FRC_GalleryPopup.new = function(options)
	options = options or {};
	local group = display.newGroup();

	local cancelTouch = function(e)
		if (e.phase == 'began') then
			group:dispatchEvent({ name = "cancelled" });
			group:dispose();
		end
		return true;
	end

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local dimRect = display.newRect(group, 0, 0, screenW, screenH);
	dimRect:setFillColor(0, 0, 0, 0.5);
	dimRect:addEventListener('touch', cancelTouch);
	dimRect:addEventListener('tap', cancelTouch);

	local popupWidth = options.width or settings.DEFAULTS.POPUP_WIDTH;
	local popupHeight = options.height or settings.DEFAULTS.POPUP_HEIGHT;
	local popup = ui.pagecontainer.new({
		width = popupWidth,
		height = popupHeight
	});
	group:insert(popup);
	popup.x, popup.y = 0, 0;
	group.popup = popup;

	local pages = {};

	-- set pageCount to the number of gallery pages you want to offer
	-- there are 6 entries per gallery page
	local pageCount = settings.DEFAULTS.TOTAL_PAGES;
	for i=1, pageCount do
		pages[i] = popup:addPage();
		pages[i].thumbGroup = display.newGroup(); pages[i]:insert(pages[i].thumbGroup);
		pages[i].thumbGroup.anchorChildren = true;
	end

	local thumbImage, baseDirectory, thumbWidth, thumbHeight;
	thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
	thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
	local largestThumbWidth = thumbWidth;
	local largestThumbHeight = thumbHeight;

	local j = 1;
	local removeIndexes = {};
	for i=1,#pages do
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
						local function proceedToSave()
							if (options.callback) then
								options.callback({
									id = self.id,
									page = i,
									row = row,
									column = col,
									data = item
								});
							end
						end
						if ((self.id) and (self.id ~= '') and (not options.isLoadPopup)) then
							native.showAlert('Replace Previously Saved Image?', 'You have asked to replace a previously saved image with the current one. Are you sure?', { 'Cancel', 'OK' }, function(event)
								if (event.index == 2) then proceedToSave(); end
							end);
						else
							proceedToSave();
						end
					end
				});
				if ((not id) and (options.hideBlank)) then
					thumbButton.isVisible = false;
					blankCount = blankCount + 1;
				end
				thumbButton.parentScrollContainer = popup;
				pages[i].thumbGroup:insert(thumbButton);
				thumbButton.x = x;
				thumbButton.y = y;
				x = x + largestThumbWidth + settings.DEFAULTS.THUMBNAIL_SPACING;
				j = j + 1;
			end
			y = y + largestThumbHeight + settings.DEFAULTS.THUMBNAIL_SPACING;
		end
		pages[i].thumbGroup.x = 0;
		pages[i].thumbGroup.y = settings.DEFAULTS.THUMBNAIL_SPACING * 0.5;

		if ((options.hideBlank) and (blankCount >= totalThumbs)) then
			table.insert(removeIndexes, i);
		end
	end

	if (#removeIndexes > 0) then
		for i=#removeIndexes,1,-1 do
			popup:removePage(removeIndexes[i]);
		end
	end

	group.dispose = FRC_GalleryPopup.dispose;

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

FRC_GalleryPopup.dispose = function(self)
	self.popup:dispose();
	if (self.removeSelf) then self:removeSelf(); end
end

return FRC_GalleryPopup;
