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
local FRC_Util                = require("FRC_Modules.FRC_Util.FRC_Util")

local analytics = import("analytics");

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/';

local enteringLobbyAnimationSequences = {};
local theatreDoorAnimationSequences = {};

local imageBase = 'FRC_Assets/FRC_Home/Images/';
local videoBase = 'FRC_Assets/MDMT_Assets/Videos/';

local videoPlayer;

--
-- Localize some common screen dimmensions
--
local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM


local function UI(key)
	return FRC_Home_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_Home_Settings.DATA[key], baseDir);
end

function FRC_Home_Scene:createScene(event)
	local scene = self;
	local view = self.view;

	-- create sceneLayout items
	local sceneLayoutMethods = {};
	local sceneLayout = {};

	if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20); end

	if (FRC_Home_Scene.preCreateScene) then
		FRC_Home_Scene:preCreateScene(event);
	end
   
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

		videoPlayer = FRC_Video.new(view._overlay, videoData);
		if videoPlayer then
			videoPlayer:addEventListener('videoComplete', videoPlaybackComplete );
		else
			-- this will fire because we are running in the Simulator and the video playback ends before it begins!
			videoPlaybackComplete();
		end
      --FRC_Layout.placeUI(videoPlayer) --EFM need to build to test this? or use temporary rect to show this position
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

		videoPlayer = FRC_Video.new(view._overlay, videoData);
		if videoPlayer then
			videoPlayer:addEventListener('videoComplete', videoPlaybackComplete );
		else
			-- this will fire because we are running in the Simulator and the video playback ends before it begins!
			videoPlaybackComplete();
		end
      --FRC_Layout.placeUI(videoPlayer)  --EFM need to build to test this? or use temporary rect to show this position
	end

	-- exit to module sequence
	sceneLayoutMethods.playEnteringLobbyAnimationSequences = function()

    -- DEBUG:
		print("sceneLayoutMethods.playEnteringLobbyAnimationSequences called");

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
				if ( ON_SIMULATOR ) then
					native.setActivityIndicator(true);
				end
			end
			storyboard.gotoScene('Scenes.Lobby', { effect="crossFade", time=250 });
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
		
		if sceneLayoutData[i].imageFile then
         dprint("Pre - setting up scene layout object: ", sceneLayoutData[i].id, sceneLayoutData[i].xCenter, sceneLayoutData[i].yCenter);
			sceneLayout[i] = display.newImageRect(view._content, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height);
         FRC_Layout.placeImage( sceneLayout[i],  sceneLayoutData[i], true )  --TRS EFM

		elseif sceneLayoutData[i].animationFiles then
			-- get the list of animation files and create the animation object
			-- preload the animation data (XML and images) early
			sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase);
         view._content:insert( sceneLayout[i] ) -- TRS EFM
         FRC_Layout.placeAnimation( sceneLayout[i],  sceneLayoutData[i], false  )  --TRS EFM
      
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
--[[      
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
--]]      
	end

	local theatreDoorAnimationFiles = {
		"MDMT_LandingPage_UsherDoorStatic_c.xml",
		"MDMT_LandingPage_UsherDoorStatic_b.xml",
		"MDMT_LandingPage_UsherDoorStatic_a.xml",
	}

	theatreDoorAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(theatreDoorAnimationFiles, animationXMLBase, animationImageBase);
   view._content:insert( theatreDoorAnimationSequences ) --TRS EFM
   FRC_Layout.placeAnimation( theatreDoorAnimationSequences, nil, false ) --TRS EFM

	for i=1, theatreDoorAnimationSequences.numChildren do
		theatreDoorAnimationSequences[i]:play({
			showLastFrame = false,
			playBackward = false,
			autoLoop = true,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1
		});
	end

	theatreDoorAnimationSequences:addEventListener('touch', function(e)
		if (theatreDoorAnimationSequences) then
			if (theatreDoorAnimationSequences.numChildren) then
				for i=1, theatreDoorAnimationSequences.numChildren do
					local anim = theatreDoorAnimationSequences[i];
					if (anim) then
						-- if (anim.isPlaying) then
							anim.dispose();
						-- end
						-- anim.remove();
					end
				end
			end
			theatreDoorAnimationSequences = nil;
		end
		sceneLayoutMethods["playEnteringLobbyAnimationSequences"]();
	end);

	local enteringLobbyAnimationFiles = {
	"MDMT_LandingPage_UsherDoorAnim_c.xml",
	"MDMT_LandingPage_UsherDoorAnim_b.xml",
	"MDMT_LandingPage_UsherDoorAnim_a.xml"
	 };
		-- preload the animation data (XML and images) early
	enteringLobbyAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(enteringLobbyAnimationFiles, animationXMLBase, animationImageBase);
   view._content:insert( enteringLobbyAnimationSequences ) --TRS EFM 
   FRC_Layout.placeAnimation( enteringLobbyAnimationSequences, nil, false ) --TRS EFM

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
		x = 74, --TRS EFM --138 - 576,
		y = 493, --TRS EFM -- --477 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.ArtCenter");
			if (not _G.ANDROID_DEVICE) then
				if ( not ON_SIMULATOR ) then
					native.setActivityIndicator(true);
				end
			end
			storyboard.gotoScene('Scenes.ArtCenter', { effect="crossFade", time=250 });
		end
	});
	artCenterButton.anchorX = 0.5;
	artCenterButton.anchorY = 0.5;   
	view._underlay:insert(artCenterButton);
   FRC_Layout.placeUI(artCenterButton,bg)  --TRS EFM
   

	setDesignButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_SetDesign_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_SetDesign_down.png',
		width = 117,
		height = 307,
		x = 187, --TRS EFM --251 - 576,
		y = 493, --TRS EFM --477 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.SetDesign");
			storyboard.gotoScene('Scenes.SetDesign', { effect="crossFade", time=250 });
		end
	});
	setDesignButton.anchorX = 0.5;
	setDesignButton.anchorY = 0.5;   
	view._underlay:insert(setDesignButton);  --TRS EFM
   FRC_Layout.placeUI(setDesignButton,bg)  --TRS EFM

	dressingRoomButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_LandingPage_Door_DressingRoom_up.png',
		imageDown = imageBase .. 'MDMT_LandingPage_Door_DressingRoom_down.png',
		width = 117,
		height = 307,
		x = 952, --TRS EFM --1016 - 576,
		y = 493, --TRS EFM --477 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Home.DressingRoom");
         storyboard.gotoScene('Scenes.DressingRoom', { effect="crossFade", time=250 }); 
		end
	});
	dressingRoomButton.anchorX = 0.5;
	dressingRoomButton.anchorY = 0.5;   
	view._underlay:insert(dressingRoomButton);  --TRS EFM
   FRC_Layout.placeUI(dressingRoomButton,bg)  --TRS EFM

	-- position background group at correct location
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
