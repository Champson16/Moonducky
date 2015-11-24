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
local FRC_Video = require('FRC_Modules.FRC_Video.FRC_Video');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local analytics = import("analytics");

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/';

local enteringLobbyAnimationSequences = {};

local imageBase = 'FRC_Assets/FRC_Home/Images/';
local videoBase = 'FRC_Assets/MDMT_Assets/Videos/';

local videoPlayer;

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

	-- create sceneLayout items
	local sceneLayoutMethods = {};
	local sceneLayout = {};

	if ((not self.id) or (self.id == '')) then self.id = generateUniqueIdentifier(20); end

	if (FRC_Home_Scene.preCreateScene) then
		FRC_Home_Scene:preCreateScene(event);
	end

	local bgGroup = display.newGroup();
	bgGroup.anchorChildren = false;
	FRC_Layout.scaleToFit(bgGroup);

	local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));
	bgGroup:insert(bg);
	bg.x, bg.y = 0,0;

	function videoPlaybackComplete(event)
		if (FRC_AppSettings.get("ambientSoundOn")) then
			FRC_AudioManager:findGroup("ambientMusic"):resume();
		end
		if (videoPlayer) then
			videoPlayer:removeSelf();
			videoPlayer = nil;
		end
		return true
	end

	function sceneLayoutMethods.playHamstersVideo()
		analytics.logEvent("MDMT.Home.HamstersVideo");
		if (FRC_AppSettings.get("ambientSoundOn")) then
			FRC_AudioManager:findGroup("ambientMusic"):pause();
		end
		local videoData = {
		HD_VIDEO_PATH = videoBase .. 'MDMT_MusicVideo_HamsterWantToBeFree_HD.mp4',
		HD_VIDEO_SIZE = { width = 1080, height = 720 },
		SD_VIDEO_PATH = videoBase .. 'MDMT_MusicVideo_HamsterWantToBeFree_SD.mp4',
		SD_VIDEO_SIZE = { width = 576, height = 384 },
		VIDEO_SCALE = 'FULLSCREEN',
		VIDEO_LENGTH = 146000 };

		videoPlayer = FRC_Video.new(view, videoData);
		if videoPlayer then
			videoPlayer:addEventListener('videoComplete', videoPlaybackComplete );
		else
			-- this will fire because we are running in the Simulator and the video playback ends before it begins!
			videoPlaybackComplete();
		end
	end

	function sceneLayoutMethods.playCowVideo()
		analytics.logEvent("MDMT.Home.CowVideo");
		if (FRC_AppSettings.get("ambientSoundOn")) then
			FRC_AudioManager:findGroup("ambientMusic"):pause();
		end
		local videoData = {
		HD_VIDEO_PATH = videoBase .. 'MDMT_MusicVideo_MechanicalCow_HD.mp4',
		HD_VIDEO_SIZE = { width = 1080, height = 720 },
		SD_VIDEO_PATH = videoBase .. 'MDMT_MusicVideo_MechanicalCow_SD.mp4',
		SD_VIDEO_SIZE = { width = 576, height = 384 },
		VIDEO_SCALE = 'FULLSCREEN',
		VIDEO_LENGTH = 204000 };

		videoPlayer = FRC_Video.new(view, videoData);
		if videoPlayer then
			videoPlayer:addEventListener('videoComplete', videoPlaybackComplete );
		else
			-- this will fire because we are running in the Simulator and the video playback ends before it begins!
			videoPlaybackComplete();
		end
	end

	local enteringLobbyAnimationFiles = {
	"MDMT_LandingPage_UsherDoorAnim_c.xml",
	"MDMT_LandingPage_UsherDoorAnim_b.xml",
	"MDMT_LandingPage_UsherDoorAnim_a.xml"
	 };
		-- preload the animation data (XML and images) early
	enteringLobbyAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(enteringLobbyAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(enteringLobbyAnimationSequences);
	bgGroup:insert(enteringLobbyAnimationSequences);

	-- exit to module sequence
	sceneLayoutMethods.playEnteringLobbyAnimationSequences = function()

    -- DEBUG:
		print("sceneLayoutMethods.playEnteringLobbyAnimationSequences called");
		-- if (scene.trainWhistle) then
		-- 	audio.play(scene.trainWhistle, { channel= 22 }); -- { channel=_G.SFX_CHANNEL });
		-- end

		for i=1, enteringLobbyAnimationSequences.numChildren do
			enteringLobbyAnimationSequences[i]:play({
				showLastFrame = true,
				playBackward = false,
				autoLoop = false,
				palindromicLoop = false,
				delay = 0,
				intervalTime = 30,
				maxIterations = 1,
				onCompletion = function ()
					if (enteringLobbyAnimationSequences) then
						if (enteringLobbyAnimationSequences.numChildren) then
							for i=1, enteringLobbyAnimationSequences.numChildren do
								local anim = enteringLobbyAnimationSequences[i];
								if (anim) then
									-- if (anim.isPlaying) then
										anim.dispose();
									-- end
									-- anim.remove();
								end
							end
						end
						enteringLobbyAnimationSequences = nil;
					end
					--[[ timer.performWithDelay(6000, function()
						storyboard.gotoScene(destinationModule);
					end, 1);
					--]]

				end
			});
		end
		--]]

		-- this is a hokey way to move to the next module at roughly the time that the animation is completed
		-- ideally this would be triggered by an onComplete function attached to the outboundToTheatreAnimationSequences[i]:play({ call above
		scene.outboundTimer = timer.performWithDelay(1400, function()
			scene.outboundTimer = nil;
			if (enteringLobbyAnimationSequences) then
				for i=1, enteringLobbyAnimationSequences.numChildren do
					enteringLobbyAnimationSequences[i]:stop();
				end
			end
			if (not _G.ANDROID_DEVICE) then
				if (system.getInfo("environment") ~= "simulator") then
					native.setActivityIndicator(true);
				end
			end
			storyboard.gotoScene('Scenes.Lobby', { effect="crossFade", time="250" });
		end, 1);
	end

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

	-- set up the scene layout
	-- Get lua tables from JSON data
	local sceneLayoutData = DATA('SCENELAYOUT');

	for i=1,#sceneLayoutData do
		-- DEBUG
		print("setting up scene layout object: ", sceneLayoutData[i].id);
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
			-- DEBUG
			-- print("sceneLayout onTouch", sceneLayoutData[i].onTouch);
			sceneLayout[i].onTouch = sceneLayoutMethods[sceneLayoutData[i].onTouch];
			if (sceneLayout[i].onTouch) then
				sceneLayout[i]:addEventListener('touch', function(e)
					if (e.phase == "began") then
						-- print("sceneLayout onTouch EVENT", e.target.onTouch); -- DEBUG
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
		width = 117,
		height = 307,
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
	artCenterButton.anchorX = 0.5;
	artCenterButton.anchorY = 0.5;
	bgGroup:insert(artCenterButton);

	setDesignButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_SetDesign_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_SetDesign_down.png',
		width = 117,
		height = 307,
		x = 251 - 576,
		y = 477 - 368,
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
		width = 117,
		height = 307,
		x = 1016 - 576,
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
	if (enteringLobbyAnimationSequences) then
		-- DEBUG:
		print("disposing enteringLobbyAnimationSequences");

		for i=1, enteringLobbyAnimationSequences.numChildren do
			local anim = enteringLobbyAnimationSequences[i];
			if (anim) then
				if (anim.isPlaying) then
					anim:stop();
				end
				anim:dispose();
			end
		end
		enteringLobbyAnimationSequences = nil;
	end
end

function FRC_Home_Scene:exitScene(event)
	local scene = self;
	local view = self.view;

	if (scene.outboundTimer) then
		timer.cancel(scene.outboundTimer);
		scene.outboundTimer = nil;
	end

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
