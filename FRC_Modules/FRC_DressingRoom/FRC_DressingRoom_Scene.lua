local storyboard = require 'storyboard';
local ui = require('ui');
local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_DressingRoom_Scene = storyboard.newScene();
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_Util                = require("FRC_Modules.FRC_Util.FRC_Util")

local character_x = 0;
local character_y = -16;
local eyeTimer;

--
-- Localize some common screen dimmensions
--
local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM


local function UI(key)
	return FRC_DressingRoom_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
end

local animationXMLBase = UI('ANIMATION_XML_BASE');
local animationImageBase = UI('ANIMATION_IMAGE_BASE');

function FRC_DressingRoom_Scene:save(e)
	local id = e.id;
	if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)); end
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
	if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)); end
	self.changeItem('Character', e.data.character, v);
	for k,v in pairs(e.data.categories) do
		self.changeItem(k, e.data.character, v);
	end
	self.id = id;
end

function FRC_DressingRoom_Scene:createScene(event)
	local view = self.view;
	if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20); end

	if (FRC_DressingRoom_Scene.preCreateScene) then
		FRC_DressingRoom_Scene:preCreateScene(event);
	end

	-- DEBUG:
	print("FRC_DressingRoom_Scene - createScene");
	-- FRC_DressingRoom.getSavedData();
	self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory);
	require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom').saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory);


   -- TRS EFM - Please, see changes/notes below.

   -- 1. Create a set of standard rendering layers
   FRC_Layout.createLayers( view )

   -- 2. (Optionally) configure the reference width/height for this scene
   --
   -- Reference dimensions must be speficied before scaling anything.
   -- You can do this once in the 'FRC_Layout' module and never change it, or change it per scene.
   --
   --FRC_Layout.setRefDimensions( UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT') )

   -- 3. Create a background
   local bg = display.newImageRect(view._underlay, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));

   -- 4. Scale first
   FRC_Layout.scaleToFit( bg )

   -- 5. Then position it.
   bg.x = centerX
   bg.y = centerY

	-- setup a container that will hold character and all layers of clothing
	--local chartainer = display.newContainer(display.contentWidth, display.contentHeight);
	local chartainer = display.newGroup();
	chartainer.anchorChildren = true;
	view._content:insert(chartainer);
	chartainer.x, chartainer.y = display.contentCenterX + 10, display.contentCenterY - 10;
	chartainer:scale(0.80, 0.80);
	chartainer:scale(bg.xScale, bg.yScale);
	view.saveGroup = chartainer;

	-- Get lua tables from JSON data
	local characterData = DATA('CHARACTER');
	local categoryData = DATA('CATEGORY');
	local sceneLayoutData = DATA('SCENELAYOUT');

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
	layers['Eyes'] = display.newGroup();
	chartainer:insert(layers['Eyes']);
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

	local function clearLayer(categoryId)
		-- clear specified layer
		for k,v in pairs(layers) do
			if (categoryId == k) then
				for i=layers[k].numChildren,1,-1 do
					layers[k][i]:removeSelf();
					layers[k][i] = nil;
				end
				break;
			end
		end
	end

	-- handles swapping out of characters and specific clothing items
	local function changeItem(categoryId, character, index)
		clearLayer(categoryId);

		local charData = getDataForCharacter(character);

		if (categoryId == 'Character') then
			if (eyeTimer) then pcall(timer.cancel, eyeTimer); end
			selectedCharacter = character;
			local charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
			charBody.x, charBody.y = character_x, character_y;

      -- DEBUG:
			print(charData.eyesOpenImage);
			print(UI('IMAGES_PATH') .. charData.eyesOpenImage);
			print(charData.eyesShutImage);
			print(UI('IMAGES_PATH') .. charData.eyesShutImage);

         clearLayer('Eyes')
			if (charData.eyesOpenImage and charData.eyesShutImage) then
				local charEyesOpen = display.newImageRect(layers['Eyes'], UI('IMAGES_PATH') .. charData.eyesOpenImage, charData.eyesOpenWidth, charData.eyesOpenHeight);
				charEyesOpen.x, charEyesOpen.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;

				print(charEyesOpen.x, charEyesOpen.y); -- DEBUG

				local charEyesShut = display.newImageRect(layers['Eyes'], UI('IMAGES_PATH') .. charData.eyesShutImage, charData.eyesShutWidth, charData.eyesShutHeight);
				charEyesShut.x, charEyesShut.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;
				charEyesShut.isVisible = false;
				print(charEyesShut.x, charEyesShut.y); -- DEBUG

				beginEyeAnimation(charEyesOpen, charEyesShut);
			end

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
				-- ERRORCHECK
				if not item then
					assert(refImage, "ERROR: Missing costume media file: ", UI('IMAGES_PATH') .. clothingData.imageFile);
				end
				item.x, item.y = character_x + clothingData.xOffset, character_y + clothingData.yOffset;
				-- check to see if we need to use the special altBodyImage
				if (categoryId == 'Headwear') then
					if (clothingData.altBodyImage) then
						-- DEBUG:
						-- print("Swapping in altBodyImage: ", UI('IMAGES_PATH') .. charData.altBodyImage);
						clearLayer('Character');
						charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.altBodyImage, charData.bodyWidth, charData.bodyHeight);
						charBody.x, charBody.y = character_x, character_y;
					else
						-- sloppy but we have to switch back to the baseimage
						-- DEBUG:
						-- print("Swapping in bodyImage: ", UI('IMAGES_PATH') .. charData.bodyImage);
						clearLayer('Character');
						charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
						charBody.x, charBody.y = character_x, character_y;
					end
				end
			else
				if (categoryId == 'Headwear') then
					-- we only reset the body if they chose the none option for Headwear
					clearLayer('Character');
					charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
			  	charBody.x, charBody.y = character_x, character_y;
				end
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

	-- create sceneLayout items
	local sceneLayoutMethods = {};
	local sceneLayout = {};
	-- setup the randomly fired mysteryBoxAnimations
	local mysteryBoxAnimationFiles = {};
	local mysteryBoxAnimationSequences = {};

	-- ambient loop sequence
	function sceneLayoutMethods.playMysteryBoxAnimationSequence()
		-- pick a random animation sequence
		local sequence = mysteryBoxAnimationSequences[math.random(1,4)];
		for i=1, sequence.numChildren do
			sequence[i]:play({
				showLastFrame = false,
				playBackward = false,
				autoLoop = false,
				palindromicLoop = false,
				delay = 0,
				intervalTime = 30,
				maxIterations = 1
			});
		end
		-- set a timer and after a delay, change the costume randomly
		timer.performWithDelay(1500,
		function ()
			for i=2,#categoryData do
				changeItem(categoryData[i].id, selectedCharacter, math.random(2, #getDataForCharacter(selectedCharacter).clothing[categoryData[i].id]));
			end
		end, 1);
	end


	function sceneLayoutMethods.randomCostume()
		-- play the mystery box animation
		sceneLayoutMethods.playMysteryBoxAnimationSequence();
	end

	-- setup the armoire animations
	local openArmoireAnimationFiles = {};
	local openArmoireAnimationSequences = {};
	local closeArmoireAnimationFiles = {};
	local closeArmoireAnimationSequences = {};

	openArmoireAnimationFiles = {
		"DressingRoom_Armoire_OpenO.xml",
		"DressingRoom_Armoire_OpenN.xml",
		"DressingRoom_Armoire_OpenM.xml",
		"DressingRoom_Armoire_OpenL.xml",
		"DressingRoom_Armoire_OpenK.xml",
		"DressingRoom_Armoire_OpenJ.xml",
		"DressingRoom_Armoire_OpenI.xml",
		"DressingRoom_Armoire_OpenH.xml",
		"DressingRoom_Armoire_OpenG.xml",
		"DressingRoom_Armoire_OpenF.xml",
		"DressingRoom_Armoire_OpenE.xml",
		"DressingRoom_Armoire_OpenD.xml",
		"DressingRoom_Armoire_OpenC.xml",
		"DressingRoom_Armoire_OpenB.xml",
		"DressingRoom_Armoire_OpenA.xml"
	};

	closeArmoireAnimationFiles = {
		"DressingRoom_Armoire_CloseO.xml",
		"DressingRoom_Armoire_CloseN.xml",
		"DressingRoom_Armoire_CloseM.xml",
		"DressingRoom_Armoire_CloseL.xml",
		"DressingRoom_Armoire_CloseK.xml",
		"DressingRoom_Armoire_CloseJ.xml",
		"DressingRoom_Armoire_CloseI.xml",
		"DressingRoom_Armoire_CloseH.xml",
		"DressingRoom_Armoire_CloseG.xml",
		"DressingRoom_Armoire_CloseF.xml",
		"DressingRoom_Armoire_CloseE.xml",
		"DressingRoom_Armoire_CloseD.xml",
		"DressingRoom_Armoire_CloseC.xml",
		"DressingRoom_Armoire_CloseB.xml",
		"DressingRoom_Armoire_CloseA.xml"
	};


	-- ambient loop sequence
	function sceneLayoutMethods.playOpenArmoireSequences()
		for i=1, openArmoireAnimationSequences.numChildren do
			openArmoireAnimationSequences[i]:play({
				showLastFrame = true,
				playBackward = false,
				autoLoop = false,
				palindromicLoop = false,
				delay = 0,
				intervalTime = 30,
				maxIterations = 1
			});
		end
	end

	-- ambient loop sequence
	function sceneLayoutMethods.playCloseArmoireSequences()
		for i=1, closeArmoireAnimationSequences.numChildren do
			closeArmoireAnimationSequences[i]:play({
				showLastFrame = false,
				playBackward = false,
				autoLoop = false,
				palindromicLoop = false,
				delay = 0,
				intervalTime = 30,
				maxIterations = 1
			});
		end
	end

	function sceneLayoutMethods.openArmoire()
		-- play the mystery box animation
		sceneLayoutMethods.playOpenArmoireSequences();
	end

	local sceneLayoutAnimationSequences;

	for i=1,#sceneLayoutData do
      dprint("Setting up scene layout object: ", sceneLayoutData[i].id, sceneLayoutData[i].xCenter, sceneLayoutData[i].yCenter);
		if sceneLayoutData[i].imageFile then
			sceneLayout[i] = display.newImageRect(view._content, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height);
			FRC_Layout.placeImage(sceneLayout[i],  sceneLayoutData[i], true )  --EFM

		elseif sceneLayoutData[i].animationFiles then
			-- get the list of animation files and create the animation object
			-- preload the animation data (XML and images) early
			sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase);
			view._content:insert(sceneLayout[i]);
         FRC_Layout.placeAnimation(sceneLayout[i], sceneLayoutData[i], true ) --EFM

         for j=1, sceneLayout[i].numChildren do
            sceneLayout[i].alpha = 0.2
				sceneLayout[i][j]:play({
					showLastFrame = false,
					playBackward = false,
					autoLoop = true,
					palindromicLoop = false,
					delay = 0,
					intervalTime = 30,
					maxIterations = 1

				});
			end
		end


		if (sceneLayoutData[i].onTouch) then
			sceneLayout[i].onTouch = sceneLayoutMethods[sceneLayoutData[i].onTouch];
			if (sceneLayout[i].onTouch) then
            local sxs, sys = sceneLayout[i].xScale, sceneLayout[i].yScale -- EFM TRS hiding box during anim
				sceneLayout[i]:addEventListener('touch', function(e)
					if (e.phase == "began") then
                  transition.to( e.target, { alpha = 0, xScale = 0.8, yScale = 0.8, delay = 200, time = 0 } ) -- EFM TRS hiding box during anim
                  transition.to( e.target, { alpha = 1, xScale = sxs, yScale = sys, delay = 1100, time = 0 } ) -- EFM TRS hiding box during anim
						e.target.onTouch();
					end
					return true;
				end);
			end
		end
	end

	for i=1,#openArmoireAnimationFiles do
		-- preload the animation data (XML and images) early
		openArmoireAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(openArmoireAnimationFiles, animationXMLBase, animationImageBase);
		openArmoireAnimationSequences:addEventListener('touch', sceneLayoutMethods.playCloseArmoireSequences);
		view._content:insert(openArmoireAnimationSequences);
		FRC_Layout.placeAnimation( openArmoireAnimationSequences, { x = -45, y = 40 } , false ) -- TRS EFM
	end

	for i=1,#closeArmoireAnimationFiles do
		-- preload the animation data (XML and images) early
		closeArmoireAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(closeArmoireAnimationFiles, animationXMLBase, animationImageBase);
		closeArmoireAnimationSequences:addEventListener('touch', sceneLayoutMethods.playOpenArmoireSequences);
		view._content:insert(closeArmoireAnimationSequences);
		FRC_Layout.placeAnimation( closeArmoireAnimationSequences, { x = -45, y = 40 } , false ) -- TRS EFM
	end




	mysteryBoxAnimationFiles[1] = {
		"SPMTM_DressingRoom_MysteryBox_v01_15.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_14.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_13.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_12.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_11.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_10.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_09.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_08.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_07.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_06.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_05.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_04.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_03.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_02.xml",
		"SPMTM_DressingRoom_MysteryBox_v01_01.xml"
	};

	mysteryBoxAnimationFiles[2] = {
		"SPMTM_DressingRoom_MysteryBox_v02_15.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_14.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_13.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_12.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_11.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_10.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_09.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_08.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_07.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_06.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_05.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_04.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_03.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_02.xml",
		"SPMTM_DressingRoom_MysteryBox_v02_01.xml"
	};

	mysteryBoxAnimationFiles[3] = {
		"SPMTM_DressingRoom_MysteryBox_v03_13.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_12.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_11.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_10.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_09.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_08.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_07.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_06.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_05.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_04.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_03.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_02.xml",
		"SPMTM_DressingRoom_MysteryBox_v03_01.xml"
	};

	mysteryBoxAnimationFiles[4] = {
		"SPMTM_DressingRoom_MysteryBox_v05_15.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_14.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_13.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_12.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_11.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_10.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_09.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_08.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_07.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_06.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_05.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_04.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_03.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_02.xml",
		"SPMTM_DressingRoom_MysteryBox_v05_01.xml"
	};

   --EFM BOX

	for i=1,#mysteryBoxAnimationFiles do
		-- preload the animation data (XML and images) early

		mysteryBoxAnimationSequences[i] = FRC_AnimationManager.createAnimationClipGroup(mysteryBoxAnimationFiles[i], animationXMLBase, animationImageBase);
		view._content:insert(mysteryBoxAnimationSequences[i]);
      FRC_Layout.placeAnimation( mysteryBoxAnimationSequences[i], { x = 0, y = 45 } , false ) -- TRS EFM
      --mysteryBoxAnimationSequences[i].alpha = 0.25
	end

	-- by default, place naked first character onto the dressing room floor
	changeItem('Character', characterData[1].id, 0);
	view._content:insert(chartainer);

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
	categoriesHeight = categoriesHeight + (category_button_spacing * 1.25); -- (category_button_spacing * 2);

	-- create button panel for categories (aligned to the bottom of the screen)
	local categoriesContainer = display.newContainer(categoriesWidth, categoriesHeight);
	local categoriesBg = display.newRoundedRect(categoriesContainer, 0, 0, categoriesWidth, categoriesHeight, 11);
	categoriesBg:setFillColor(1.0, 1.0, 1.0, 0.85); -- 1.0, 1.0, 1.0, 0.35);
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
				-- show the focused state for the selected category icon
				local self = e.target
				if self:getFocusState() then
					 -- hide the itemScroller
					 itemScrollers[self.id].isVisible = false;
					 self:setFocusState(false)
				else
					 self:setFocusState(true)
					 -- present the scroller contain the selected category's content
					 itemScrollers[self.id].isVisible = true
					 for i=2,categoriesContainer.numChildren do
							if (categoriesContainer[i] ~= self) then
								 categoriesContainer[i]:setFocusState(false)
								 itemScrollers[categoriesContainer[i].id].isVisible = false
							end
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
			bgColor = { 1.0, 1.0, 1.0, 0.65 }
		});
		-- scroller.bg.alpha = 0.65;
		view._overlay:insert(scroller);
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
			imageUp = UI('IMAGES_PATH') .. (characterData[i].bodyThumb or characterData[i].bodyImage),
			imageDown = UI('IMAGES_PATH') .. (characterData[i].bodyThumb or characterData[i].bodyImage),
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

	local thumbnailExtension = "";
	if (FRC_DressingRoom_Settings.CONFIG.costumes) then
		if (FRC_DressingRoom_Settings.CONFIG.costumes.customThumbnails) then
			thumbnailExtension = "_thumbnail";
		end
	end
	-- DEBUG:
	print("costume thumbnail extension: ", thumbnailExtension);

	for k,v in pairs(characterData[1].clothing) do
		local categoryId = k;
		local scroller = itemScrollers[categoryId];
		local x = -(scroller.contentWidth * 0.5) + scroller.leftPadding;
		for j=1,#v do
			-- DEBUG:
			-- this is to find issues with bad character data
			-- print("characterData[1].clothing:" .. v[j].id);
			-- width = buttonHeight * (v[j].width / v[j].height),
			-- need to constrain the image to fit a maximum width area
			local scaledWidth = buttonHeight * (v[j].width / v[j].height);
			local constrainedWidth = buttonHeight * 1.5;
			local tempwidth = math.min(scaledWidth, constrainedWidth);
			local tempheight = buttonHeight; -- default
			if (tempwidth == constrainedWidth) then
				-- we had to constrain the width artificially so we need to scale down the height to reflect that
				tempheight = buttonHeight * (constrainedWidth / scaledWidth);
			end;
			-- if there's a custom thumbnail extension (instead of using the first character's costume images)
			-- we need to rewrite the imageFile path
			local imageFilePath = UI('IMAGES_PATH') .. v[j].imageFile;
			-- DEBUG:
			-- print(imageFilePath);
			if ( thumbnailExtension ~= "" ) then
				imageFilePath = string.gsub(imageFilePath, ".png", thumbnailExtension .. ".png", 1);
				-- DEBUG:
				-- print(imageFilePath);
			end
			local button = ui.button.new({
				id = v[j].id,
				imageUp = imageFilePath,
				imageDown = imageFilePath,
				width = tempwidth,
				height = tempheight,
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

	view._overlay:insert(categoriesContainer);

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
