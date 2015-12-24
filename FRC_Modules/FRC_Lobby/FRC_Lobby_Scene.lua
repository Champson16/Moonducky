local storyboard = require 'storyboard';
local ui = require('ui');
local json = require "json";
local socket = require("socket.url")
local FRC_Lobby_Settings = require('FRC_Modules.FRC_Lobby.FRC_Lobby_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Lobby_Scene = storyboard.newScene();
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_Video = require('FRC_Modules.FRC_Video.FRC_Video');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local analytics = import("analytics");
local FRC_Util                = require("FRC_Modules.FRC_Util.FRC_Util")

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/';

local theatreDoorSequences = {};

local imageBase = 'FRC_Assets/FRC_Lobby/Images/';
local videoBase = 'FRC_Assets/MDMT_Assets/Videos/';

local videoPlayer;
local lobbySounds;
local lobbySoundPlayback;

local popcornEmitters = {}
local popcornSounds = {}

--
-- Localize some common screen dimmensions
--
local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM

FRC_AudioManager:newGroup({
      name = "lobbySounds",
      maxChannels = 10
   });

local function UI(key)
	return FRC_Lobby_Settings.UI[key];
end

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_Lobby_Settings.DATA[key], baseDir);
end

function FRC_Lobby_Scene:createScene(event)
	local scene = self;
	local view = self.view;

	-- create sceneLayout items
	local sceneLayoutMethods = {};
	local sceneLayout = {};

	if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20); end

	if (FRC_Lobby_Scene.preCreateScene) then
		FRC_Lobby_Scene:preCreateScene(event);
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
     -- resume background music (if enabled)
     if (FRC_AppSettings.get("soundOn")) then
       local musicGroup = FRC_AudioManager:findGroup("music");
       if musicGroup then
         musicGroup:resume();
       end
     end

     if (view._overlay) then
       view._overlay:removeEventListener('videoComplete', videoPlaybackComplete );
     end

     if (videoPlayer) then
       videoPlayer:removeSelf();
       videoPlayer = nil;
     end
     return true
   end

	sceneLayoutMethods.featureComingSoon = function()
		native.showAlert("Jukebox is being repaired but should be available very soon!","This feature is coming soon.", { "OK" });
	end

	sceneLayoutMethods.popcornMachineActivate = function(event)
		-- start the Audio
		lobbySounds = FRC_AudioManager:findGroup("lobbySounds");
		-- local popcornHandle = lobbySounds:findHandle("popcorn");
		-- if lobbySounds and popcornHandle then
		-- 	print("found lobbySounds"); -- DEBUG
		-- 	local nextChannel = lobbySounds:findFreeChannel();
    --   popcornHandle:play( { channel = nextChannel } );
		-- 	print("popcorn sound playback"); -- DEBUG
		-- end
		local popcornHandle = FRC_AudioManager:newHandle({
		      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_Lobby_Popcorn.mp3",
		      loadMethod = "loadSound" -- ,
					-- group = "lobbySounds"
		   });

		if lobbySounds and popcornHandle then
			-- print("found lobbySounds"); -- DEBUG
			-- local nextChannel = lobbySounds:findFreeChannel();
      -- if nextChannel then
			-- 	popcornHandle:play( { channel = nextChannel } );
			-- 	print("popcorn sound playback"); -- DEBUG
			-- end

			local playbackChannel = lobbySounds:addChannel();
			lobbySounds:addHandle(popcornHandle);
         lobbySounds:play(popcornHandle.name, { channel = playbackChannel });
			print( 'playbackChannel:', playbackChannel );
         popcornSounds[#popcornSounds+1] = popcornHandle
		end

		-- Decode the string
      local pex = require "pex"
      local emitter1 = pex.loadPD2( view._content, centerX + 249, centerY + 36,
						           FRC_Lobby_Settings.DATA.POPCORNMACHINEPARTICLE,
                             { texturePath = "FRC_Assets/FRC_Lobby/Images/" } )
      popcornEmitters[#popcornEmitters+1] = emitter1
      --local emitterParams = DATA('POPCORNMACHINEPARTICLE'); -- json.decode( fileData )
		-- Create the emitter with the decoded parameters
		--local emitter1 = display.newEmitter( emitterParams )
		-- Center the emitter within the content area
		--emitter1.x = display.contentCenterX + 249;
		--emitter1.y = display.contentCenterY + 36;

		local function stopPopcornMachine(soundHandle)
          if( emitter1.removeSelf == nil ) then return end
		    emitter1:stop()
          print('stopping sound handle name: ', soundHandle.name)
			soundHandle:stop();
		end
		-- Stop the emitter after 5 seconds
		timer.performWithDelay( 5000, function()
			stopPopcornMachine(popcornHandle)
		end, 1);

	end


	rehearsalButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_Lobby_RehearsalDoor.png',
		imageDown = imageBase .. 'MDMT_Lobby_RehearsalDoor_down.png',
		width = 133,
		height = 327,
		x = 158, -- TRS EFM --222 - 576,
		y = 376, -- TRS EFM --360 - 368,
		onRelease = function()
			analytics.logEvent("MDMT.Lobby.Rehearsal");
         --storyboard.gotoScene('Scenes.Rehearsal');
         storyboard.gotoScene('Scenes.Rehearsal', { params = { mode = "rehearsal" }  } );
		end
	});
	rehearsalButton.anchorX = 0.5;
	rehearsalButton.anchorY = 0.5;
   view._underlay:insert(rehearsalButton);
   FRC_Layout.placeUI(rehearsalButton)


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

  -- TODO EFM: This entire scene layout processing code block needs to be a separate component used by any scene
	-- set up the scene layout
	-- Get lua tables from JSON data
	local sceneLayoutData = DATA('SCENELAYOUT');

	for i=1,#sceneLayoutData do
		-- DEBUG
		dprint("Setting up scene layout object: ", sceneLayoutData[i].id, sceneLayoutData[i].xCenter, sceneLayoutData[i].yCenter);
		if sceneLayoutData[i].imageFile then
			sceneLayout[i] = display.newImageRect(view._content, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height);
			FRC_Layout.placeImage(sceneLayout[i],  sceneLayoutData[i], true )  --EFM
         --FRC_Layout.scaleToFit(sceneLayout[i]);
		elseif sceneLayoutData[i].animationFiles then
			-- get the list of animation files and create the animation object
			-- preload the animation data (XML and images) early
			sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase);
			view._content:insert(sceneLayout[i]);
         FRC_Layout.placeAnimation(sceneLayout[i], sceneLayoutData[i], true ) --EFM

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

  local theatreDoorAnimationFiles = {
		"MDMT_Lobby_UsherDoorStatic_g.xml",
			"MDMT_Lobby_UsherDoorStatic_f.xml",
			"MDMT_Lobby_UsherDoorStatic_e.xml",
			"MDMT_Lobby_UsherDoorStatic_d.xml",
			"MDMT_Lobby_UsherDoorStatic_c.xml",
			"MDMT_Lobby_UsherDoorStatic_b.xml",
			"MDMT_Lobby_UsherDoorStatic_a.xml"
	}

   dprint("Placing theatreDoorAnimationSequences")
	theatreDoorAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(theatreDoorAnimationFiles, animationXMLBase, animationImageBase);
   view._content:insert(theatreDoorAnimationSequences);  -- TRS EFM
   FRC_Layout.placeAnimation( theatreDoorAnimationSequences, nil, false ) -- TRS EFM


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
		sceneLayoutMethods["playOutboundAnimationSequences"]();
	end);
	sceneLayoutMethods.playOutboundAnimationSequences = function()

	for i=1, theatreDoorSequences.numChildren do
		theatreDoorSequences[i]:play({
			showLastFrame = false,
			playBackward = false,
			autoLoop = false,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1,
			onCompletion = function ()
				if (theatreDoorSequences) then
					if (theatreDoorSequences.numChildren) then
						for i=1, theatreDoorSequences.numChildren do
							local anim = theatreDoorSequences[i];
							if (anim) then
								-- if (anim.isPlaying) then
									anim.dispose();
								-- end
								-- anim.remove();
							end
						end
					end
					theatreDoorSequences = nil;
				end
				--[[ timer.performWithDelay(6000, function()
					storyboard.gotoScene(destinationModule);
				end, 1);
				--]]

			end
		});
	end

	-- this is a hokey way to move to the next module at roughly the time that the animation is completed
	-- ideally this would be triggered by an onComplete function attached to the outboundToTheatreAnimationSequences[i]:play({ call above
	scene.outboundTimer = timer.performWithDelay(1600, function()
		scene.outboundTimer = nil;
		if (theatreDoorSequences) then
			for i=1, theatreDoorSequences.numChildren do
				theatreDoorSequences[i]:stop();
			end
		end
      storyboard.gotoScene('Scenes.Rehearsal', { params = { mode = "showtime" }  } );
		--native.showAlert("Showtime Coming Soon!","This feature is coming soon.", { "OK" });
		end, 1);
	end

	local theatreDoorAnimationFiles = {
	"MDMT_Lobby_UsherDoorAnim_b.xml",
	"MDMT_Lobby_UsherDoorAnim_a.xml"
	 };
   -- preload the animation data (XML and images) early
   dprint("Placing theatreDoor")
	theatreDoorSequences = FRC_AnimationManager.createAnimationClipGroup(theatreDoorAnimationFiles, animationXMLBase, animationImageBase);
	view._content:insert(theatreDoorSequences);
   FRC_Layout.placeAnimation(theatreDoorSequences, nil, true) -- TRS EFM

	-- insert the main function buttons
	-- Art center
	-- Set design
	-- Theatre doors (animation object)
	-- Dressing room
	-- cat?
	-- donkey?
	-- piano awning?

	local learnButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_Lobby_LearnPoster.png',
		imageDown = imageBase .. 'MDMT_Lobby_LearnPoster_down.png',
		width = 141,
		height = 116,
		x = 859,
		y = 171,
		onRelease = function(e)
			analytics.logEvent("MDMT.Lobby.Learn");
			local screenRect = display.newRect(view, 0, 0, screenW, screenH);
			screenRect.x = display.contentCenterX;
			screenRect.y = display.contentCenterY;
			screenRect:setFillColor(0, 0, 0, 0.75);
			screenRect:addEventListener('touch', function() return true; end);
			screenRect:addEventListener('tap', function() return true; end);

			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			webView:request("Help/MDMT_FRC_WebOverlay_Learn_Credits.html", system.CachesDirectory);

			local closeButton = ui.button.new({
				imageUp = imageBase .. 'FRC_Home_global_LandingPage_CloseButton.png',
				imageDown = imageBase .. 'FRC_Home_global_LandingPage_CloseButton.png',
				width = 50,
				height = 50,
				onRelease = function(event)
					local self = event.target;
					webView:removeSelf(); webView = nil;
					self:removeSelf(); closeButton = nil;
					screenRect:removeSelf(); screenRect = nil;
				end
			});
			closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
			closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
			webView.closeButton = closeButton;
		end
	});
	learnButton.anchorX = 0.5;
	learnButton.anchorY = 0.5;
   view._underlay:insert(learnButton); -- TRS EFM
   FRC_Layout.placeUI(learnButton) -- TRS EFM


	discoverButton = ui.button.new({
		imageUp = imageBase .. 'MDMT_Lobby_DiscoverPoster.png',
		imageDown = imageBase .. 'MDMT_Lobby_DiscoverPoster_down.png',
		width = 158,
		height = 102,
		x = 934,
		y = 256,
		onRelease = function(e)
			analytics.logEvent("MDMT.Lobby.Discover");
			local screenRect = display.newRect(view, 0, 0, screenW, screenH);
			screenRect.x = display.contentCenterX;
			screenRect.y = display.contentCenterY;
			screenRect:setFillColor(0, 0, 0, 0.75);
			screenRect:addEventListener('touch', function() return true; end);
			screenRect:addEventListener('tap', function() return true; end);

			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			local platformName = import("platform").detected;
			webView:request("http://fatredcouch.com/page.php?t=products&p=" .. platformName);

			local closeButton = ui.button.new({
				imageUp = imageBase .. 'FRC_Home_global_LandingPage_CloseButton.png',
				imageDown = imageBase .. 'FRC_Home_global_LandingPage_CloseButton.png',
				width = 50,
				height = 50,
				onRelease = function(event)
					local self = event.target;
					webView:removeSelf(); webView = nil;
					self:removeSelf(); closeButton = nil;
					screenRect:removeSelf(); screenRect = nil;
				end
			});
			closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
			closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
			webView.closeButton = closeButton;
		end
	});
	discoverButton.anchorX = 0.5;
	discoverButton.anchorY = 0.5;
	view._underlay:insert(discoverButton);  -- TRS EFM
   FRC_Layout.placeUI(discoverButton)  -- TRS EFM


	if (FRC_Lobby_Scene.postCreateScene) then
		FRC_Lobby_Scene:postCreateScene(event);
	end
end

function FRC_Lobby_Scene:enterScene(event)
	local scene = self;
	local view = self.view;

	if (FRC_Lobby_Scene.preEnterScene) then
		FRC_Lobby_Scene:preEnterScene(event);
	end

	native.setActivityIndicator(false);

	if (FRC_Lobby_Scene.postEnterScene) then
		FRC_Lobby_Scene:postEnterScene(event);
	end

   --view:scale(0.5,0.5)
   --view.x = 200
   --view.y = 200
end

function FRC_Lobby_Scene:disposeAnimations(self)

	-- DEBUG:
	print("FRC_Lobby_Scene:disposeAnimations called");

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
		-- theatreDoorSequences = nil; -- commented out until we actually have code to go to Showtime
	end
end

function FRC_Lobby_Scene:exitScene(event)
	local scene = self;
	local view = self.view;

   for k,v in pairs( popcornEmitters ) do
     display.remove( v )
   end
   popcornEmitters = {}
   for k,v in pairs( popcornSounds ) do
     if( v.stop ) then v:stop() end
   end
   popcornSounds = {}


	if (scene.outboundTimer) then
		timer.cancel(scene.outboundTimer);
		scene.outboundTimer = nil;
	end

	if (FRC_Lobby_Scene.preExitScene) then
		FRC_Lobby_Scene:preExitScene(event);
	end

	if (FRC_Lobby_Scene.postExitScene) then
		FRC_Lobby_Scene:postExitScene(event);
	end
end

function FRC_Lobby_Scene:didExitScene(event)
	local view = self.view;

	if (FRC_Lobby_Scene.preDidExitScene) then
		FRC_Lobby_Scene:preDidExitScene(event);
	end

	if (FRC_Lobby_Scene.postDidExitScene) then
		FRC_Lobby_Scene:postDidExitScene(event);
	end
end

FRC_Lobby_Scene:addEventListener('createScene', FRC_Lobby_Scene);
FRC_Lobby_Scene:addEventListener('enterScene', FRC_Lobby_Scene);
FRC_Lobby_Scene:addEventListener('exitScene', FRC_Lobby_Scene);
FRC_Lobby_Scene:addEventListener('didExitScene', FRC_Lobby_Scene);

return FRC_Lobby_Scene;
