local storyboard = require 'storyboard';
local ui = require('ui');
local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_DressingRoom_Scene = storyboard.newScene();

local character_x = 0;
local character_y = -16;
local eyeTimer;

function math.round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num));
end

local function UI(key)
	return FRC_DressingRoom_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
end

local generateUniqueIdentifier = function(digits)
	digits = digits or 20;
	local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };
	local s = '';
	for i=1,digits do
		if (i == 1) then
			s = s .. alphabet[math.random(1, #alphabet)];
		elseif (math.random(0,1) == 1) then
			s = s .. math.random(0, 9);
		else
			s = s .. alphabet[math.random(1, #alphabet)];
		end
	end
	return tostring(s);
end

function FRC_DressingRoom_Scene:save(e)
	local id = e.id;
	if ((not id) or (id == '')) then id = (generateUniqueIdentifier(20)); end
	local saveGroup = self.view.saveGroup;
	
	-- create mask (to be used for Stamp in ArtCenter)
	-- mask must have a minimum of 3px padding on all sides, and be a multiple of 4
	local capture = display.capture(saveGroup);
	local cw = ((capture.contentWidth + 12) * display.contentScaleX);
	local ch = ((capture.contentHeight + 12) * display.contentScaleY);
	local sx = display.contentScaleX;
	local sy = display.contentScaleY;
	if (display.contentScaleX < 1.0) then
		cw = cw * 2;
		capture.xScale = display.contentScaleX;
		sx = 1.0;
	end
	if (display.contentScaleY < 1.0) then
		ch = ch * 2;
		capture.yScale = display.contentScaleY;
		sy = 1.0;
	end
	local maskWidth = math.round(((cw) - ((cw) % 4)) * sx);
	local maskHeight = math.round(((ch) - ((ch) % 4)) * sy);
	local maskContainer = display.newContainer(maskWidth, maskHeight);
	local blackRect = display.newRect(maskContainer, 0, 0, maskWidth, maskHeight);
	blackRect:setFillColor(0, 0, 0, 1.0);
	blackRect.x, blackRect.y = 0, 0;
	maskContainer:insert(capture);
	capture.fill.effect = 'filter.colorMatrix';
	capture.fill.effect.coefficients =
	{
	    0, 0, 0, 1,  --red coefficients
	    0, 0, 0, 1,  --green coefficients
	    0, 0, 0, 1,  --blue coefficients
	    0, 0, 0, 0   --alpha coefficients
	};
	capture.fill.effect.bias = { 0, 0, 0, 1 };
	maskContainer.x = display.contentCenterX;
	maskContainer.y = display.contentCenterY;
	--display.save(maskContainer, id .. '_mask.png', system.DocumentsDirectory);
	display.save(maskContainer, {
		filename = id .. '_mask.png',
		baseDir = system.DocumentsDirectory,
		isFullResolution = false
	});
	capture.fill.effect = nil;

	-- save full-size image (to be used as Stamp in ArtCenter)
	blackRect:removeSelf(); blackRect = nil;
	display.save(maskContainer, { filename=id .. '_full.jpg', baseDir=system.DocumentsDirectory });
	local fullWidth = maskContainer.contentWidth;
	local fullHeight = maskContainer.contentHeight;

	-- save thumbnail
	maskContainer.yScale = UI('THUMBNAIL_HEIGHT') / maskContainer.contentHeight;
	maskContainer.xScale = maskContainer.yScale;
	local thumbWidth = maskContainer.contentWidth;
	local thumbHeight = maskContainer.contentHeight;
	display.save(maskContainer, { filename=id .. '_thumbnail.png', baseDir=system.DocumentsDirectory });
	maskContainer:removeSelf(); maskContainer = nil;

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local saveDataFilename = FRC_DressingRoom_Settings.DATA.DATA_FILENAME;
	local newSave = {
		id = id,
		character = self.view.currentData.character,
		categories = self.view.currentData.categories,
		index = self.view.currentData.index,
		thumbWidth = thumbWidth,
		thumbHeight = thumbHeight,
		thumbSuffix = '_thumbnail.png',
		maskSuffix = '_mask.png',
		fullSuffix = '_full.jpg',
		fullWidth = fullWidth,
		fullHeight = fullHeight
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

function FRC_DressingRoom_Scene:load(e)
	local id = e.id;
	if ((not id) or (id == '')) then id = (generateUniqueIdentifier(20)); end
	self.changeItem('Character', e.data.character, v);
	for k,v in pairs(e.data.categories) do
		self.changeItem(k, e.data.character, v);
	end
	self.id = id;
end

function FRC_DressingRoom_Scene:createScene(event)
	local view = self.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	if ((not self.id) or (self.id == '')) then self.id = generateUniqueIdentifier(20); end

	if (FRC_DressingRoom_Scene.preCreateScene) then
		FRC_DressingRoom_Scene:preCreateScene(event);
	end

	self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory);
	require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom').saveData = self.saveData;

	local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));
	bg.x, bg.y = display.contentCenterX, display.contentCenterY;
	bg.xScale = screenW / display.contentWidth;
	bg.yScale = bg.xScale;

	-- setup a container that will hold character and all layers of clothing
	--local chartainer = display.newContainer(display.contentWidth, display.contentHeight);
	local chartainer = display.newGroup();
	chartainer.anchorChildren = true;
	view:insert(chartainer);
	chartainer.x, chartainer.y = display.contentCenterX, display.contentCenterY - 30;
	chartainer:scale(0.80, 0.80);
	chartainer:scale(bg.xScale, bg.yScale);
	view.saveGroup = chartainer;

	-- Get lua tables from JSON data
	local characterData = DATA('CHARACTER');
	local categoryData = DATA('CATEGORY');
	local furnitureData = DATA('FURNITURE');

	-- Insert 'None' as first item of all character costume categories
	local none = {
		id = 'none',
		imageFile = UI('COSTUME_NONE_IMAGE'),
		width = UI('COSTUME_NONE_WIDTH'),
		height = UI('COSTUME_NONE_HEIGHT'),
		xOffset = 0,
		yOffset = 0
	};
	for i=1,#characterData do
		for k,v in pairs(characterData[i].clothing) do
			table.insert(characterData[i].clothing[k], 1, none);
		end
	end

	local layers = {};
	local selectedCharacter = '';

	-- create a new layer for each category, manually creating the first (character)
	-- at the bottom of the layer stack
	layers['Character'] = display.newGroup();
	chartainer:insert(layers['Character']);
	for i=#categoryData,2,-1 do
		layers[categoryData[i].id] = display.newGroup();
		chartainer:insert(layers[categoryData[i].id]);
	end

	local getDataForCharacter = function(character)
		local charData;
		for i=1,#characterData do
			if (characterData[i].id == character) then
				charData = characterData[i];
				break;
			end
		end
		if (not charData) then
			error('No character data for "' .. character .. '"');
		end
		return charData;
	end

	local function beginEyeAnimation(open, shut)
		if (eyeTimer) then pcall(timer.cancel, eyeTimer); end
		open.isVisible = true;
		shut.isVisible = false;
		eyeTimer = timer.performWithDelay(math.random(1000,3000), function()
			open.isVisible = false;
			shut.isVisible = true;
			eyeTimer = timer.performWithDelay(100, function()
				open.isVisible = true;
				shut.isVisible = false;
				eyeTimer = timer.performWithDelay(200, function()
					open.isVisible = false;
					shut.isVisible = true;
					eyeTimer = timer.performWithDelay(75, function()
						open.isVisible = true;
						shut.isVisible = false;
						eyeTimer = timer.performWithDelay(math.random(1000,3000), function()
							eyeTimer = nil;
							beginEyeAnimation(open, shut);
						end, 1);
					end, 1);
				end, 1);
			end, 1);
		end, 1);
	end

	-- handles swapping out of characters and specific clothing items
	local function changeItem(categoryId, character, index)
		-- clear current layer
		for k,v in pairs(layers) do
			if (categoryId == k) then
				for i=layers[k].numChildren,1,-1 do
					layers[k][i]:removeSelf();
					layers[k][i] = nil;
				end
				break;
			end
		end
		
		local charData = getDataForCharacter(character);

		if (categoryId == 'Character') then
			selectedCharacter = character;
			local charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
			charBody.x, charBody.y = character_x, character_y;

			local charEyesOpen = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesOpenImage, charData.eyesOpenWidth, charData.eyesOpenHeight);
			charEyesOpen.x, charEyesOpen.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;
			charEyesOpen.isVisible = true;

			local charEyesShut = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesShutImage, charData.eyesShutWidth, charData.eyesShutHeight);
			charEyesShut.x, charEyesShut.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;
			charEyesShut.isVisible = false;

			beginEyeAnimation(charEyesOpen, charEyesShut);

			if (index ~= 0) then
				for i=2,#categoryData do
					changeItem(categoryData[i].id, selectedCharacter, layers[categoryData[i].id].selectedIndex or 1);
				end
			end
		else
			local clothingData = charData.clothing[categoryId][index];
			if (not clothingData) then return; end
			if (clothingData.id ~= 'none') then
				local item = display.newImageRect(layers[categoryId], UI('IMAGES_PATH') .. clothingData.imageFile, clothingData.width, clothingData.height);
				item.x, item.y = character_x + clothingData.xOffset, character_y + clothingData.yOffset;
			end
			layers[categoryId].selectedIndex = index;
		end
		view.currentData = {
			character = character,
			categories = {}
		};
		for k,v in pairs(layers) do
			view.currentData.categories[k] = layers[k].selectedIndex;
		end
	end
	self.changeItem = changeItem;

	self.startOver = function()
		changeItem('Character', selectedCharacter, 0);
		for i=1,#categoryData do
			changeItem(categoryData[i].id, selectedCharacter, 1);
		end
	end

	-- by default, place naked first character onto the dressing room floor
	changeItem('Character', characterData[1].id, 0);
	view:insert(chartainer);

	-- create furniture items
	local furnitureMethods = {};
	function furnitureMethods.randomCostume()
		for i=2,#categoryData do
			changeItem(categoryData[i].id, selectedCharacter, math.random(2, #getDataForCharacter(selectedCharacter).clothing[categoryData[i].id]));
		end
	end

	for i=1,#furnitureData do
		local furniture = display.newImageRect(view, UI('IMAGES_PATH') .. furnitureData[i].imageFile, furnitureData[i].width, furnitureData[i].height);
		if (furnitureData[i].left) then
			furniture.x = furnitureData[i].left - ((screenW - display.contentWidth) * 0.5) + (furniture.contentWidth * 0.5);
		elseif (furnitureData[i].right) then
			furniture.x = display.contentWidth - furnitureData[i].right + ((screenW - display.contentWidth) * 0.5) - (furniture.contentWidth * 0.5);
		end
		furniture.y = furnitureData[i].y - ((screenH - display.contentHeight) * 0.5);
		furniture:scale(bg.xScale, bg.yScale);

		if (furnitureData[i].onTouch) then
			furniture.onTouch = furnitureMethods[furnitureData[i].onTouch];
			if (furniture.onTouch) then
				furniture:addEventListener('touch', function(e)
					if (e.phase == "began") then
						e.target.onTouch();
					end
					return true;
				end);
			end
		end
	end

	local category_button_spacing = 48;
	local button_spacing = 24;
	local button_scale = 0.75;
	local categoriesWidth = button_spacing;
	local categoriesHeight = 0;
	local itemScrollers = {};

	-- calculate panel dimensions for category buttons
	for i=1,#categoryData do
		categoriesWidth = categoriesWidth + (categoryData[i].width * button_scale) + category_button_spacing;
		if ((categoryData[i].height * button_scale) > categoriesHeight) then
			categoriesHeight = categoryData[i].height * button_scale;
		end
	end
	categoriesHeight = categoriesHeight + (category_button_spacing * 2);

	-- create button panel for categories (aligned to the bottom of the screen)
	local categoriesContainer = display.newContainer(categoriesWidth, categoriesHeight);
	local categoriesBg = display.newRoundedRect(categoriesContainer, 0, 0, categoriesWidth, categoriesHeight, 11);
	categoriesBg:setFillColor(1.0, 1.0, 1.0, 0.35);
	categoriesBg.x, categoriesBg.y = 0, 0;
	categoriesContainer.x = display.contentCenterX;
	categoriesContainer.y = display.contentHeight - (categoriesHeight * 0.5) + (category_button_spacing * 1.65);

	for i=1,#categoryData do
		local button = ui.button.new({
			id = categoryData[i].id,
			imageUp = UI('IMAGES_PATH') .. categoryData[i].imageUp,
			imageDown = UI('IMAGES_PATH') .. categoryData[i].imageDown,
			focusState = UI('IMAGES_PATH') .. categoryData[i].imageFocused,
			disabled = UI('IMAGES_PATH') .. categoryData[i].imageDisabled,
			width = categoryData[i].width * button_scale,
			height = categoryData[i].height * button_scale,
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
			height = (categoriesHeight * button_scale) - 5,
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

	-- create character scroll container
	local x = -(screenW * 0.5) + button_spacing;
	local buttonHeight = 0;
	for i=1,#characterData do
		local scroller = itemScrollers['Character'];
		buttonHeight = scroller.contentHeight - button_spacing;
		local button = ui.button.new({
			id = characterData[i].id,
			imageUp = UI('IMAGES_PATH') .. characterData[i].bodyThumb,
			imageDown = UI('IMAGES_PATH') .. characterData[i].bodyThumb,
			width = buttonHeight * (characterData[i].bodyWidth / characterData[i].bodyHeight),
			height = buttonHeight,
			parentScrollContainer = scroller,
			pressAlpha = 0.5,
			onRelease = function(e)
				local self = e.target;
				changeItem('Character', self.id);
			end
		});
		button.categoryId = 'Character';
		scroller:insert(button);
		x = x + (button.contentWidth * 0.5);
		button.x, button.y = x, 0;
		x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5);
	end

	-- create the clothing scroll containers using the first character's images
	for k,v in pairs(characterData[1].clothing) do
		local categoryId = k;
		local scroller = itemScrollers[categoryId];
		local x = -(scroller.contentWidth * 0.5) + scroller.leftPadding;
		for j=1,#v do
			local button = ui.button.new({
				id = v[j].id,
				imageUp = UI('IMAGES_PATH') .. v[j].imageFile,
				imageDown = UI('IMAGES_PATH') .. v[j].imageFile,
				width = buttonHeight * (v[j].width / v[j].height),
				height = buttonHeight,
				parentScrollContainer = scroller,
				pressAlpha = 0.5,
				onRelease = function(e)
					local self = e.target;
					changeItem(self.categoryId, selectedCharacter, self.index);
				end
			});
			button.categoryId = categoryId;
			button.index = j;
			button.xOffset = v[j].xOffset;
			button.yOffset = v[j].yOffset;
			scroller:insert(button);
			x = x + (button.contentWidth * 0.5);
			button.x, button.y = x, 0;
			x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5);
		end
	end

	view:insert(categoriesContainer);

	if (FRC_DressingRoom_Scene.postCreateScene) then
		FRC_DressingRoom_Scene:postCreateScene(event);
	end
end

function FRC_DressingRoom_Scene:enterScene(event)
	local view = self.view;

	if (FRC_DressingRoom_Scene.preEnterScene) then
		FRC_DressingRoom_Scene:preEnterScene(event);
	end

	native.setActivityIndicator(false);

	if (FRC_DressingRoom_Scene.postEnterScene) then
		FRC_DressingRoom_Scene:postEnterScene(event);
	end
end

function FRC_DressingRoom_Scene:exitScene(event)
	local view = self.view;

	if (FRC_DressingRoom_Scene.preExitScene) then
		FRC_DressingRoom_Scene:preExitScene(event);
	end

	if (eyeTimer) then
		pcall(timer.cancel, eyeTimer);
		eyeTimer = nil;
	end

	if (FRC_DressingRoom_Scene.postExitScene) then
		FRC_DressingRoom_Scene:postExitScene(event);
	end
end

function FRC_DressingRoom_Scene:didExitScene(event)
	local view = self.view;

	if (FRC_DressingRoom_Scene.preDidExitScene) then
		FRC_DressingRoom_Scene:preDidExitScene(event);
	end

	if (FRC_DressingRoom_Scene.postDidExitScene) then
		FRC_DressingRoom_Scene:postDidExitScene(event);
	end
end

FRC_DressingRoom_Scene:addEventListener('createScene', FRC_DressingRoom_Scene);
FRC_DressingRoom_Scene:addEventListener('enterScene', FRC_DressingRoom_Scene);
FRC_DressingRoom_Scene:addEventListener('exitScene', FRC_DressingRoom_Scene);
FRC_DressingRoom_Scene:addEventListener('didExitScene', FRC_DressingRoom_Scene);

return FRC_DressingRoom_Scene;