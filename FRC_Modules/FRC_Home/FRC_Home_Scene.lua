local storyboard = require 'storyboard';
local ui = require('ui');
local json = require "json";
local socket = require("socket.url")
local FRC_Home_Settings = require('FRC_Modules.FRC_Home.FRC_Home_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Home_Scene = storyboard.newScene();
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local analytics = import("analytics");

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/';

local theatreDoorSequences = {};

local imageBase = 'FRC_Assets/FRC_Home/Images/';

function math.round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num));
end

local function UI(key)
	return FRC_Home_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_Home_Settings.DATA[key], baseDir);
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

function FRC_Home_Scene:createScene(event)
	local scene = self;
	local view = self.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local contentW, contentH = display.contentWidth, display.contentHeight;

	if ((not self.id) or (self.id == '')) then self.id = generateUniqueIdentifier(20); end

	if (FRC_Home_Scene.preCreateScene) then
		FRC_Home_Scene:preCreateScene(event);
	end

	local bgGroup = display.newGroup();
	bgGroup.anchorChildren = false;
	FRC_Layout.scaleToFit(bgGroup);

	local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));
	-- FRC_Layout.scaleToFit(bg);
	-- bg.x, bg.y = display.contentCenterX, display.contentCenterY;
	bgGroup:insert(bg);

	local xOffset = (screenW - (contentW * bg.xScale)) * 0.5;

	-- Get lua tables from JSON data
	local sceneLayoutData = DATA('SCENELAYOUT');

	-- query server
	-- establish online/offline check

	function scene.networkListener(event)
		print( "address", event.address );
    print( "isReachable", event.isReachable );
    print( "isConnectionRequired", event.isConnectionRequired );
    print( "isConnectionOnDemand", event.isConnectionOnDemand );
    print( "IsInteractionRequired", event.isInteractionRequired );
    print( "IsReachableViaCellular", event.isReachableViaCellular );
    print( "IsReachableViaWiFi", event.isReachableViaWiFi );
    -- If you want to remove the listener, call network.setStatusListener( "www.apple.com", nil )
	end

	--[[ if ( network.canDetectNetworkStatusChanges ) then
    network.setStatusListener( "www.google.com", networkListener );
	else
		-- DEBUG:
	  print( "Network reachability not supported on this platform." );
	end
	--]]

	-- create sceneLayout items
	local sceneLayoutMethods = {};
	local sceneLayout = {};

-- set up the scene layout
	for i=1,#sceneLayoutData do
		if sceneLayoutData[i].imageFile then
			sceneLayout[i] = display.newImageRect(view, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height);
			FRC_Layout.scaleToFit(sceneLayout[i]);

			if (sceneLayoutData[i].left) then
				sceneLayoutData[i].left = (sceneLayoutData[i].left * bg.xScale);
				sceneLayout[i].x = sceneLayoutData[i].left - ((screenW - contentW) * 0.5) + (sceneLayout[i].contentWidth * 0.5);

			elseif (sceneLayoutData[i].right) then
				sceneLayoutData[i].right = (sceneLayoutData[i].right * bg.xScale);
				sceneLayout[i].x = contentW - sceneLayoutData[i].right + ((screenW - contentW) * 0.5) - (sceneLayout[i].contentWidth * 0.5);
			elseif (sceneLayoutData[i].xCenter) then
				sceneLayout[i].x = display.contentCenterX + (sceneLayoutData[i].xCenter * bg.xScale);
			else
				sceneLayoutData[i].x = sceneLayoutData[i].x * bg.xScale;
				sceneLayout[i].x = sceneLayoutData[i].x - ((screenW - contentW) * 0.5);
			end
			if (sceneLayoutData[i].top) then
				sceneLayout[i].y = sceneLayoutData[i].top - ((screenH - contentH) * 0.5) + (sceneLayout[i].contentHeight * 0.5);
				sceneLayout[i].y = sceneLayout[i].y + bg.contentBounds.yMin;
			elseif (sceneLayoutData[i].bottom) then
				sceneLayoutData[i].bottom = sceneLayoutData[i].bottom * bg.yScale;
				sceneLayout[i].y = contentH - sceneLayoutData[i].bottom + ((screenH - contentH) * 0.5) - (sceneLayout[i].contentHeight * 0.5);
			elseif (sceneLayoutData[i].yCenter) then
				sceneLayout[i].x = display.contentCenterY + (sceneLayoutData[i].yCenter * bg.yScale);
			else
				sceneLayoutData[i].y = sceneLayoutData[i].y * bg.yScale;
				sceneLayout[i].y = sceneLayoutData[i].y - ((screenH - contentH) * 0.5);
			end


		elseif sceneLayoutData[i].animationFiles then
			-- get the list of animation files and create the animation object
			-- preload the animation data (XML and images) early
			sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase);
			FRC_Layout.scaleToFit(sceneLayout[i]);

			if (sceneLayoutData[i].left) then
				sceneLayoutData[i].left = (sceneLayoutData[i].left * bg.xScale);
				sceneLayout[i].x = sceneLayoutData[i].left - ((screenW - contentW) * 0.5) + (sceneLayout[i].contentWidth * 0.5);

			elseif (sceneLayoutData[i].right) then
				sceneLayoutData[i].right = (sceneLayoutData[i].right * bg.xScale);
				sceneLayout[i].x = contentW - sceneLayoutData[i].right + ((screenW - contentW) * 0.5) - (sceneLayout[i].contentWidth * 0.5);
			elseif (sceneLayoutData[i].x) then
				sceneLayoutData[i].x = sceneLayoutData[i].x * bg.xScale;
				sceneLayout[i].x = sceneLayoutData[i].x - ((screenW - contentW) * 0.5);
			else
				local xOffset = (screenW - (contentW * bg.xScale)) * 0.5;
				sceneLayout[i].x = ((bg.contentWidth - screenW) * 0.5) + bg.contentBounds.xMin + xOffset;
			end

			if (sceneLayoutData[i].top) then
				sceneLayout[i].y = sceneLayoutData[i].top - ((screenH - contentH) * 0.5) + (sceneLayout[i].contentHeight * 0.5);
			elseif (sceneLayoutData[i].bottom) then
				sceneLayout[i].y = contentH - sceneLayoutData[i].bottom + ((screenH - contentH) * 0.5) - (sceneLayout[i].contentHeight * 0.5);
			elseif (sceneLayoutData[i].y) then
				sceneLayoutData[i].y = sceneLayoutData[i].y * bg.yScale;
				sceneLayout[i].y = sceneLayoutData[i].y - ((screenH - contentH) * 0.5);
			end

			sceneLayout[i].y = sceneLayout[i].y + bg.contentBounds.yMin;

			bgGroup:insert(sceneLayout[i]);
			for j=1, sceneLayout[i].numChildren do
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
				sceneLayout[i]:addEventListener('touch', function(e)
					if (e.phase == "began") then
						e.target.onTouch();
					end
					return true;
				end);
			end
		end
	end

	-- insert the main function buttons
	-- Art center
	-- Set design
	-- Theatre doors (animation object)
	-- Dressing room
	-- cat?
	-- donkey?
	-- piano awning?

	local artCenterButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_ArtCenter_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_ArtCenter_down.png',
		width = 163,
		height = 335,
		x = 138 - 576,
		y = 477 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.ArtCenter");
			if (not _G.ANDROID_DEVICE) then
				if (system.getInfo("environment") ~= "simulator") then
					native.setActivityIndicator(true);
				end
			end
			storyboard.gotoScene('Scenes.ArtCenter', { effect="crossFade", time="250" });
		end
	});

	-- FRC_Layout.scaleToFit(artCenterButton)
	-- artCenterButton.x = display.contentCenterX - (artCenterButton.contentWidth) - (50 * bg.xScale);
	-- artCenterButton.y = contentH - (102 * bg.yScale) + ((screenH - contentH) * 0.5) - (artCenterButton.contentHeight * 0.5);

	artCenterButton.anchorX = 0.5;
	artCenterButton.anchorY = 0.5;
	bgGroup:insert(artCenterButton);

	setDesignButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_SetDesign_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_SetDesign_down.png',
		width = 162,
		height = 323,
		x = 249 - 576,
		y = 476 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.SetDesign");
			storyboard.gotoScene('Scenes.SetDesign', { effect="crossFade", time="250" });
		end
	});
	setDesignButton.anchorX = 0.5;
	setDesignButton.anchorY = 0.5;
	bgGroup:insert(setDesignButton);

	dressingRoomButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_DressingRoom_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_DressingRoom_down.png',
		width = 123,
		height = 311,
		x = 1017 - 576,
		y = 477 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.DressingRoom");
			storyboard.gotoScene('Scenes.DressingRoom', { effect="crossFade", time="250" });
		end
	});
	dressingRoomButton.anchorX = 0.5;
	dressingRoomButton.anchorY = 0.5;
	bgGroup:insert(dressingRoomButton);

	-- position background group at correct location
	bgGroup.x = display.contentCenterX;
	bgGroup.y = display.contentCenterY;
	view:insert(bgGroup);

	local theatreDoorFiles = {
"MDMT_LandingPage_UsherDoorStatic_c.xml",
"MDMT_LandingPage_UsherDoorStatic_b.xml",
"MDMT_LandingPage_UsherDoorStatic_a.xml"
 };
	-- preload the animation data (XML and images) early
	theatreDoorSequences = FRC_AnimationManager.createAnimationClipGroup(theatreDoorFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(theatreDoorSequences);
	view:insert(theatreDoorSequences);

	-- play ambient loop sequences
	if theatreDoorSequences then
		for i=1, theatreDoorSequences.numChildren do
			theatreDoorSequences[i]:play({
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

	if (FRC_Home_Scene.postCreateScene) then
		FRC_Home_Scene:postCreateScene(event);
	end
end

function FRC_Home_Scene:enterScene(event)
	local scene = self;
	local view = self.view;

	if (FRC_Home_Scene.preEnterScene) then
		FRC_Home_Scene:preEnterScene(event);
	end

	native.setActivityIndicator(false);

	if (FRC_Home_Scene.postEnterScene) then
		FRC_Home_Scene:postEnterScene(event);
	end
end

function FRC_Home_Scene:disposeAnimations(self)

	-- DEBUG:
	print("FRC_Home_Scene:disposeAnimations called");

	-- kill the animation objects
	if (theatreDoorSequences) then
		-- DEBUG:
		print("disposing theatreDoorSequences");

		for i=1, theatreDoorSequences.numChildren do
			local anim = theatreDoorSequences[i];
			if (anim) then
				if (anim.isPlaying) then
					anim:stop();
				end
				anim:dispose();
			end
		end
		theatreDoorSequences = nil;
	end
end

function FRC_Home_Scene:exitScene(event)
	local scene = self;
	local view = self.view;

	if (FRC_Home_Scene.preExitScene) then
		FRC_Home_Scene:preExitScene(event);
	end

	if (FRC_Home_Scene.postExitScene) then
		FRC_Home_Scene:postExitScene(event);
	end
end

function FRC_Home_Scene:didExitScene(event)
	local view = self.view;

	if (FRC_Home_Scene.preDidExitScene) then
		FRC_Home_Scene:preDidExitScene(event);
	end

	if (FRC_Home_Scene.postDidExitScene) then
		FRC_Home_Scene:postDidExitScene(event);
	end
end

FRC_Home_Scene:addEventListener('createScene', FRC_Home_Scene);
FRC_Home_Scene:addEventListener('enterScene', FRC_Home_Scene);
FRC_Home_Scene:addEventListener('exitScene', FRC_Home_Scene);
FRC_Home_Scene:addEventListener('didExitScene', FRC_Home_Scene);

return FRC_Home_Scene;
