local storyboard = require 'storyboard';
local ui = require('ui');
local json = require('json');
local FRC_SetDesign_Settings = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Util                = require("FRC_Modules.FRC_Util.FRC_Util")

local FRC_SetDesign_Scene = storyboard.newScene();
local FRC_ArtCenter;
local artCenterLoaded = pcall(function()
	FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
end);

local function UI(key)
	return FRC_SetDesign_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_SetDesign_Settings.DATA[key], baseDir);
end


FRC_SetDesign_Scene.setIndex = 1;
FRC_SetDesign_Scene.backdropIndex = 1;

function FRC_SetDesign_Scene:saveCurrentSet(e)
	local id = e.id;
	if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)); end
	local saveGroup = self.view.saveGroup;

	-- [[
	local capture = display.capture(saveGroup);
	capture.x = display.contentCenterX;
	capture.y = display.contentCenterY;
	capture.xScale = UI('THUMBNAIL_WIDTH') / capture.contentWidth;
	capture.yScale = UI('THUMBNAIL_HEIGHT') / capture.contentHeight;
	display.save(capture, { filename=id .. '_thumbnail.jpg', baseDir=system.DocumentsDirectory });
	capture:removeSelf(); capture = nil;
	--]]
	--display.save(saveGroup, { filename=id .. '_thumbnail.jpg', baseDir=system.DocumentsDirectory });

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local saveDataFilename = FRC_SetDesign_Settings.DATA.DATA_FILENAME;
	local newSave = {
		id = id,
		setIndex = FRC_SetDesign_Scene.setIndex,
		backdropIndex = FRC_SetDesign_Scene.backdropIndex,
		thumbWidth = UI('THUMBNAIL_WIDTH'),
		thumbHeight = UI('THUMBNAIL_HEIGHT'),
		thumbSuffix = '_thumbnail.jpg'
	};
	local exists = false;
	for i=1,#self.saveData.savedItems do
		if (self.saveData.savedItems[i].id == id) then
			self.saveData.savedItems[i] = newSave;
			exists = true;
		end
	end
	if (not exists) then
		table.insert(self.saveData.savedItems, newSave);
	end
	FRC_DataLib.saveJSON(saveDataFilename, self.saveData);
	self.id = id;
end

function FRC_SetDesign_Scene:loadSet(e)
	local id = e.id;
	if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)); end
	self.changeSet(e.data.setIndex);
	self.changeBackdrop(e.data.backdropIndex);
	self.id = id;
end

function FRC_SetDesign_Scene:createScene(event)
	local view = self.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20); end

	if (FRC_SetDesign_Scene.preCreateScene) then
		FRC_SetDesign_Scene:preCreateScene(event);
	end

	-- load existing save data
	self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory);
	require('FRC_Modules.FRC_SetDesign.FRC_SetDesign').saveData = self.saveData;

	local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));
	bg.x, bg.y = display.contentCenterX, display.contentCenterY;
	bg.xScale = screenW / display.contentWidth;
	bg.yScale = bg.xScale;

	-- Get lua tables from JSON data
	local categoryData = DATA('CATEGORIES');
	local setData = DATA('SETS');
	local backdropData = DATA('BACKDROPS');
	--local lightingData = DATA('LIGHTING');

	-- Load in existing ArtCenter images as Backdrops
	if (artCenterLoaded) then
		FRC_ArtCenter.getSavedData();
		if ((FRC_ArtCenter.savedData) and (#FRC_ArtCenter.savedData.savedItems > 0)) then
			for i=#FRC_ArtCenter.savedData.savedItems,1,-1 do
				local item = FRC_ArtCenter.savedData.savedItems[i];
				table.insert(backdropData, 1, {
					id = item.id,
					imageFile = item.id .. item.fullSuffix,
					thumbFile = item.id .. item.thumbSuffix,
					width = item.fullWidth,
					height = item.fullHeight,
					baseDir = "DocumentsDirectory"
				});
			end
		end
	end

	local setScale = 0.65;
	view.saveGroup = display.newGroup(); view:insert(view.saveGroup);
	local backdropGroup = display.newGroup(); view.saveGroup:insert(backdropGroup);
	local setGroup = display.newGroup(); view.saveGroup:insert(setGroup);

	local repositionSet = function()
		view.saveGroup.xScale = setScale;
		view.saveGroup.yScale = setScale;
		view.saveGroup.x = (display.contentWidth - (display.contentWidth * setScale)) * 0.5;
		view.saveGroup.y = (display.contentHeight - (display.contentHeight * setScale)) * 0.5;
		view.saveGroup.y = view.saveGroup.y - 80;
	end

	local changeSet = function(index)
		if (index == FRC_SetDesign_Scene.setIndex) then return; end
		index = index or FRC_SetDesign_Scene.setIndex;
		if (setGroup.numChildren > 0) then
			setGroup[1]:removeSelf();
			setGroup[1] = nil;
		end

		local setBackground = display.newImageRect(setGroup, UI('IMAGES_PATH') .. setData[index].imageFile, setData[index].width, setData[index].height);
		setBackground.x = display.contentCenterX;
		setBackground.y = display.contentCenterY;
		local frameRect = setData[index].frameRect;
		setBackground.frameRect = frameRect;
		FRC_SetDesign_Scene.setIndex = index;

		-- resize selected backdrop to fit in selected set
		local selectedBackdrop = backdropGroup[1];
		if (not selectedBackdrop) then return; end
		local currentWidth = backdropData[FRC_SetDesign_Scene.backdropIndex].width;
		local currentHeight = backdropData[FRC_SetDesign_Scene.backdropIndex].height;
		selectedBackdrop.xScale = (frameRect.width / currentWidth);
		selectedBackdrop.yScale = (frameRect.height / currentHeight);
		selectedBackdrop.x = frameRect.left - ((setBackground.width - display.contentWidth) * 0.5);
		selectedBackdrop.y = frameRect.top - ((setBackground.height - display.contentHeight) * 0.5);
	end
	self.changeSet = changeSet;
	changeSet();

	local changeBackdrop = function(index)
		if (index == FRC_SetDesign_Scene.backdropIndex) then return; end
		if (not backdropData[index]) then index = 1; end -- ArtCenter image set as backdrop, but image was deleted (reset index to 1)
		index = index or FRC_SetDesign_Scene.backdropIndex;
		if (backdropGroup.numChildren > 0) then
			backdropGroup[1]:removeSelf();
			backdropGroup[1] = nil;
		end

		local frameRect = setGroup[1].frameRect;
		local imageFile = UI('IMAGES_PATH') .. backdropData[index].imageFile;
		local baseDir = system.ResourceDirectory;
		if (backdropData[index].baseDir) then
			imageFile = backdropData[index].imageFile;
			baseDir = system[backdropData[index].baseDir];
		end
		local backdropBackground = display.newImageRect(backdropGroup, imageFile, baseDir, backdropData[index].width, backdropData[index].height);
		backdropBackground.anchorX = 0;
		backdropBackground.anchorY = 0;
		backdropBackground.xScale = (frameRect.width / backdropData[index].width);
		backdropBackground.yScale = (frameRect.height / backdropData[index].height);
		backdropBackground.x = frameRect.left - ((setGroup[1].width - display.contentWidth) * 0.5);
		backdropBackground.y = frameRect.top - ((setGroup[1].height - display.contentHeight) * 0.5);
		FRC_SetDesign_Scene.backdropIndex = index;
	end
	self.changeBackdrop = changeBackdrop;
	changeBackdrop();
	repositionSet();

	local category_button_spacing = 48;
	local category_button_scale = 0.75;
	local categoriesWidth = category_button_spacing;
	local categoriesHeight = 0;
	local button_spacing = 24;
	local itemScrollers = {};

	-- calculate panel dimensions for category buttons
	for i=1,#categoryData do
		categoriesWidth = categoriesWidth + (categoryData[i].width * category_button_scale) + category_button_spacing;
		if ((categoryData[i].height * category_button_scale) > categoriesHeight) then
			categoriesHeight = categoryData[i].height * category_button_scale;
		end
	end
	categoriesHeight = categoriesHeight + (category_button_spacing * 1.25);

	-- create button panel for categories (aligned to the bottom of the screen)
	local categoriesContainer = display.newContainer(categoriesWidth, categoriesHeight);
	local categoriesBg = display.newRoundedRect(categoriesContainer, 0, 0, categoriesWidth, categoriesHeight, 11);
	categoriesBg:setFillColor(1.0, 1.0, 1.0, 0.35);
	categoriesBg.x, categoriesBg.y = 0, 0;
	categoriesContainer.x = display.contentCenterX;
	categoriesContainer.y = display.contentHeight - (categoriesHeight * 0.5) + (category_button_spacing * 1.65);

	-- create individual buttons for each category
	for i=1,#categoryData do
		local button = ui.button.new({
			id = categoryData[i].id,
			imageUp = UI('IMAGES_PATH') .. categoryData[i].imageUp,
			imageDown = UI('IMAGES_PATH') .. categoryData[i].imageDown,
			focusState = UI('IMAGES_PATH') .. categoryData[i].imageFocused,
			disabled = UI('IMAGES_PATH') .. categoryData[i].imageDisabled,
			width = categoryData[i].width * category_button_scale,
			height = categoryData[i].height * category_button_scale,
			onPress = function(e)
				local self = e.target;
				self:setFocusState(true);
				itemScrollers[self.id].isVisible = true;
				for i=2,categoriesContainer.numChildren do
					if (categoriesContainer[i] ~= self) then
						categoriesContainer[i]:setFocusState(false);
						itemScrollers[categoriesContainer[i].id].isVisible = false;
					end
				end
			end
		});
		categoriesContainer:insert(button);
		button.x = (-(categoriesWidth * 0.5) + (button.contentWidth * 0.5) + category_button_spacing) + (i - 1) * (button.contentWidth + category_button_spacing);
		button.y = -category_button_spacing * 0.75;

		-- create corresponding item scroll containers
		local scroller = ui.scrollcontainer.new({
			width = screenW,
			height = UI('THUMBNAIL_HEIGHT') + 20,
			xScroll = true,
			yScroll = false,
			leftPadding = button_spacing,
			rightPadding = button_spacing,
			bgColor = { 1.0, 1.0, 1.0, 1.0 }
		});
		scroller.bg.alpha = 0.65;
		view:insert(scroller);
		scroller.x = display.contentCenterX;
		scroller.y = categoriesContainer.contentBounds.yMin - (scroller.contentHeight * 0.5);
		scroller.isVisible = false;
		itemScrollers[categoryData[i].id] = scroller;
		if (i == 1) then
			button:setFocusState(true);
			scroller.isVisible = true;
		end
	end

	-- populate SetSelector scroll container with buttons
	local x = -(screenW * 0.5) + button_spacing;
	local buttonHeight = 0;
	for i=1,#setData do
		local scroller = itemScrollers['SetSelector'];
		buttonHeight = UI('THUMBNAIL_HEIGHT');
		local button = ui.button.new({
			id = setData[i].id,
			imageUp = UI('IMAGES_PATH') .. setData[i].thumbFile,
			imageDown = UI('IMAGES_PATH') .. setData[i].thumbFile,
			width = buttonHeight * (setData[i].width / setData[i].height),
			height = buttonHeight,
			parentScrollContainer = scroller,
			pressAlpha = 0.5,
			onRelease = function(e)
				local self = e.target;
				changeSet(self.dataIndex);
			end
		});
		button.dataIndex = i;
		button.categoryId = 'SetSelector';
		scroller:insert(button);
		x = x + (button.contentWidth * 0.5);
		button.x, button.y = x, 0;
		x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5);
	end

	-- populate BackdropSelector scroll container with buttons
	local x = -(screenW * 0.5) + button_spacing;
	local buttonHeight = 0;
	for i=1,#backdropData do
		local scroller = itemScrollers['BackdropSelector'];
		buttonHeight = UI('THUMBNAIL_HEIGHT');
		local imageFile = UI('IMAGES_PATH') .. backdropData[i].thumbFile;
		local baseDir = system.ResourceDirectory;
		if (backdropData[i].baseDir) then
			imageFile = backdropData[i].thumbFile;
			baseDir = system[backdropData[i].baseDir];
		end
		local button = ui.button.new({
			id = backdropData[i].id,
			imageUp = imageFile,
			imageDown = imageFile,
			baseDirectory = baseDir,
			width = buttonHeight * (backdropData[i].width / backdropData[i].height),
			height = buttonHeight,
			parentScrollContainer = scroller,
			pressAlpha = 0.5,
			onRelease = function(e)
				local self = e.target;
				changeBackdrop(self.dataIndex);
			end
		});
		button.dataIndex = i;
		button.categoryId = 'BackdropSelector';
		scroller:insert(button);
		x = x + (button.contentWidth * 0.5);
		button.x, button.y = x, 0;
		x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5);
	end

	view:insert(categoriesContainer);

	if (FRC_SetDesign_Scene.postCreateScene) then
		FRC_SetDesign_Scene:postCreateScene(event);
	end
end

function FRC_SetDesign_Scene:enterScene(event)
	local view = self.view;

	if (FRC_SetDesign_Scene.preEnterScene) then
		FRC_SetDesign_Scene:preEnterScene(event);
	end

	native.setActivityIndicator(false);

	if (FRC_SetDesign_Scene.postEnterScene) then
		FRC_SetDesign_Scene:postEnterScene(event);
	end
end

function FRC_SetDesign_Scene:exitScene(event)
	local view = self.view;

	if (FRC_SetDesign_Scene.preExitScene) then
		FRC_SetDesign_Scene:preExitScene(event);
	end

	if (FRC_SetDesign_Scene.postExitScene) then
		FRC_SetDesign_Scene:postExitScene(event);
	end
end

function FRC_SetDesign_Scene:didExitScene(event)
	local view = self.view;

	if (FRC_SetDesign_Scene.preDidExitScene) then
		FRC_SetDesign_Scene:preDidExitScene(event);
	end

	if (FRC_SetDesign_Scene.postDidExitScene) then
		FRC_SetDesign_Scene:postDidExitScene(event);
	end
end

FRC_SetDesign_Scene:addEventListener('createScene', FRC_SetDesign_Scene);
FRC_SetDesign_Scene:addEventListener('enterScene', FRC_SetDesign_Scene);
FRC_SetDesign_Scene:addEventListener('exitScene', FRC_SetDesign_Scene);
FRC_SetDesign_Scene:addEventListener('didExitScene', FRC_SetDesign_Scene);

return FRC_SetDesign_Scene;
