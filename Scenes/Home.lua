local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_Home = require('FRC_Modules.FRC_Home.FRC_Home');
local FRC_Home_Settings = require('FRC_Modules.FRC_Home.FRC_Home_Settings');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

local analytics = import("analytics");

local math_random = math.random;
local scene = FRC_Home.newScene();
local activeBGMusic = "";
local musicGroup; -- forward declaration
local imageBase = 'FRC_Assets/MDMT_Assets/Images/';
local webView;

scene.backHandler = function()
	if (webView) then
		webView.closeButton:dispatchEvent({
			name = "release",
			target = webView.closeButton
		});
	else
		native.showAlert('Exit?', 'Are you sure you want to exit MoonDucky Music Theatre?', { "Cancel", "OK" }, function(event)
			if (event.index == 2) then
				native.requestExit();
			end
		end);
	end
end

	if (not buildText) then
		buildText = display.newEmbossedText(FRC_AppSettings.get("version") .. ' (' .. BUILD_INFO .. ')', 0, 0, native.systemFontBold, 11);
		buildText:setFillColor(1, 1, 1);
		buildText.anchorX = 1.0;
		buildText.anchorY = 1.0;
		FRC_Layout.scaleToFit(buildText);
		buildText.x = FRC_Layout.right(8);
		buildText.y = display.contentHeight - 4;
	end

	function playBackgroundMusic()
		-- DEBUG:
		print("playing backgroundMusic");
		activeBGMusic = "backgroundMusic";
		musicGroup = FRC_AudioManager:findGroup("music");
		-- repeatedly play all background music
		musicGroup:playRandom({ onComplete = function() playBackgroundMusic(); end } );
		if (not FRC_AppSettings.get("soundOn")) then
			musicGroup:pause();
		end
	end

	function scene.enterScene(self, event)
		local scene = self;
		local view = scene.view;

		if (FRC_AppSettings.get("freshLaunch")) then
			--[[ scene.skipIntroButton.isHitTestable = true;
			for i=1, intro1AnimationSequences.numChildren do
				intro1AnimationSequences[i]:play({
					showLastFrame = true,
					playBackward = false,
					autoLoop = false,
					palindromicLoop = false,
					delay = 0,
					intervalTime = 30,
					maxIterations = 1,
					onCompletion = function ()
						playIntro2AnimationSequences();
					end
				});
			end
			--]]
		else
			-- after the title animation, we will play the introduction sequences only
			-- playIntro2AltAnimationSequences();
		end

		if (musicGroup) then
			-- resume the background theme song that was playing when we left the Home scene
			if (not FRC_AppSettings.get("soundOn")) then
				musicGroup:pause();
			else
				-- DEBUG:
				print("HOME scene RESUME background audio");
				musicGroup:resume();
			end
		else
			-- fallback to restarting one of the background theme songs
			playBackgroundMusic();
		end

	end

----
----
----
----

function scene.postCreateScene(self, event)
	local scene = self;
	local view = scene.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	-- create action bar menu at top left corner of screen
	scene.actionBarMenu = FRC_ActionBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_up.png',
		imageDown = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_down.png',
		focusState = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_focused.png',
		disabled = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 0,
		bgColor = { 1, 1, 1, .95 },
		alwaysVisible = true,
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_ArtCenter_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_ArtCenter_down.png',
				onRelease = function()
					storyboard.gotoScene('Scenes.ArtCenter');
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SetDesign_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SetDesign_down.png',
				onRelease = function()
					storyboard.gotoScene('Scenes.SetDesign');
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_DressingRoom_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_DressingRoom_down.png',
				onRelease = function()
							 storyboard.gotoScene('Scenes.DressingRoom');
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Showtime_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Showtime_down.png',
				onRelease = function()
							 storyboard.gotoScene('Scenes.Rehearsal');
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
				onRelease = function(e)
					analytics.logEvent("MDMTActionBarHomeFRC");
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
					-- DEBUG:
					print('platform: ', platformName);
					webView:request("https://fatredcouch.com/page.php?t=products&p=" .. platformName );

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
					--view:insert(closeButton);
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_down.png',
				onRelease = function()
					analytics.logEvent("MDMTActionBarHomeHelp");
					local screenRect = display.newRect(view, 0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					webView:request("Help/MDMT_FRC_WebOverlay_Help_Main.html", system.CachesDirectory);

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
					--view:insert(closeButton);
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			}
		}
	});

	-- create settings bar menu at top left corner of screen
	local musicButtonFocused = false;
	if (FRC_AppSettings.get("soundOn")) then musicButtonFocused = true; end
	scene.settingsBarMenu = FRC_SettingsBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_up.png',
		imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_down.png',
		focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_focused.png',
		disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 0,
		bgColor = { 1, 1, 1, .95 },
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_focused.png',
				isFocused = musicButtonFocused,
				onPress = function(event)
					analytics.logEvent("MDMTSettingsBarHomeToggleMusic");
					local self = event.target;
					if (FRC_AppSettings.get("soundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("soundOn", false);
						musicGroup = FRC_AudioManager:findGroup("music");
						if musicGroup then
							musicGroup:pause();
						end
					else
						self:setFocusState(true);
						FRC_AppSettings.set("soundOn", true);
						musicGroup = FRC_AudioManager:findGroup("music");
						if musicGroup then
							musicGroup:resume();
						end
					end
				end
			}
		}
	});
end

function scene.postExitScene(self, event)
	ui:dispose();
end

function scene.postDidExitScene(self, event)
	local scene = self;
	scene.actionBarMenu:dispose();
	scene.actionBarMenu = nil;
	scene.settingsBarMenu:dispose();
	scene.settingsBarMenu = nil;
end

return scene;
