local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local math_random = math.random;

local scene = storyboard.newScene();

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/MDMT_Assets/Images/';

	local bg = display.newGroup();
	bg.anchorChildren = true;
	bg.anchorX = 0.5;
	bg.anchorY = 0.5;

	local bgImage = display.newImageRect(imageBase .. 'MoonduckyLandingPage.jpg', 1152, 768);
	bg:insert(bgImage);
	--bg.xScale = screenW / display.contentWidth;
	--bg.yScale = bg.xScale;
	bgImage.x = display.contentCenterX;
	bgImage.y = display.contentCenterY;
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	view:insert(bg);

	local artCenterButton = display.newRect(bg, 0, 0, 114, 317);
	artCenterButton.isVisible = false;
	artCenterButton.isHitTestable = true;
	artCenterButton.x, artCenterButton.y = 38, 476;
	artCenterButton:addEventListener('touch', function(e)
		if (e.phase == "began") then
			if (not _G.ANDROID_DEVICE) then
				native.setActivityIndicator(true);
			end
			storyboard.gotoScene('Scenes.ArtCenter');
		end
		return true;
	end);

	local setDesignButton = display.newRect(bg, 0, 0, 114, 317);
	setDesignButton.isVisible = false;
	setDesignButton.isHitTestable = true;
	setDesignButton.x, setDesignButton.y = 160, 476;
	setDesignButton:addEventListener('touch', function(e)
		if (e.phase == "began") then
			if (not _G.ANDROID_DEVICE) then
				native.setActivityIndicator(true);
			end
			storyboard.gotoScene('Scenes.SetDesign');
		end
		return true;
	end);

	local learnButton = display.newRect(bg, 0, 0, 114, 317);
	learnButton.isVisible = false;
	learnButton.isHitTestable = true;
	learnButton.x, learnButton.y = 312, 508;
	learnButton:addEventListener('touch', function(e)
		if (e.phase == "began") then
			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			webView:request("MDMT_FRC_WebOverlay_Learn_Credits.html", system.ResourceDirectory);

			local closeButton = ui.button.new({
				imageUp = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
				imageDown = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
				width = 50,
				height = 50,
				onRelease = function(event)
					local self = event.target;
					webView:removeSelf(); webView = nil;
					self:removeSelf();
				end
			});
			view:insert(closeButton);
			closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
			closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
		end
		return true;
	end);

	local discoverButton = display.newRect(bg, 0, 0, 114, 317);
	discoverButton.isVisible = false;
	discoverButton.isHitTestable = true;
	discoverButton.x, discoverButton.y = 706, 508;
	discoverButton:addEventListener('touch', function(e)
		if (e.phase == "began") then
			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			webView:request("http://fatredcouch.com/page.php?t=products");

			local closeButton = ui.button.new({
				imageUp = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
				imageDown = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
				width = 50,
				height = 50,
				onRelease = function(event)
					local self = event.target;
					webView:removeSelf(); webView = nil;
					self:removeSelf();
				end
			});
			view:insert(closeButton);
			closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
			closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
		end
		return true;
	end);

	local dressingRoomButton = display.newRect(bg, 0, 0, 114, 317);
	dressingRoomButton.isVisible = false;
	dressingRoomButton.isHitTestable = true;
	dressingRoomButton.x, dressingRoomButton.y = 981, 476;
	dressingRoomButton:addEventListener('touch', function(e)
		if (e.phase == "began") then
			if (not _G.ANDROID_DEVICE) then
				native.setActivityIndicator(true);
			end
			storyboard.gotoScene('Scenes.DressingRoom');
		end
		return true;
	end);

	if (not buildText) then
		buildText = display.newEmbossedText(_G.APP_VERSION .. ' (' .. system.getInfo('build') .. ')', 0, 0, native.systemFontBold, 13);
		buildText:setFillColor(1, 1, 1);
		buildText.anchorX = 1.0;
		buildText.anchorY = 1.0;
		buildText.x = screenW - 8;
		buildText.y = screenH - 10;
	end

	-- create action bar menu at top left corner of screen
	scene.actionBarMenu = FRC_ActionBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_up.png',
		imageDown = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_down.png',
		focusState = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_focused.png',
		disabled = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_disabled.png',
		buttonWidth = 75,
		buttonHeight = 75,
		buttonPadding = 40,
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				onRelease = function(e)
					local screenRect = display.newRect(view, 0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);
					
					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					webView:request("http://fatredcouch.com/page.php?t=products");
		
					local closeButton = ui.button.new({
						imageUp = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'MDMT_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf(); closeButton = nil;
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					view:insert(closeButton);
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
				end
			}
		}
	});

	-- create settings bar menu at top left corner of screen
	local musicButtonFocused = false;
	if (_G.APP_Settings.soundOn) then musicButtonFocused = true; end
	scene.settingsBarMenu = FRC_SettingsBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_up.png',
		imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_down.png',
		focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_focused.png',
		disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_disabled.png',
		buttonWidth = 75,
		buttonHeight = 75,
		buttonPadding = 40,
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_focused.png',
				isFocused = musicButtonFocused,
				onPress = function(event)
					local self = event.target;
					if (_G.APP_Settings.soundOn) then
						self:setFocusState(false);
						_G.APP_Settings.soundOn = false;
						audio.pause(1);
					else
						self:setFocusState(true);
						_G.APP_Settings.soundOn = true;
						audio.resume(1);
					end
				end
			}
		}
	});
end

function scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;
	
	if (not audio.isChannelActive(1)) then
		if (not _G.APP_Settings.soundOn) then
			_G.playNextMusicTrack(true);
		else
			_G.playNextMusicTrack();
		end
	end
end

function scene.exitScene(self, event)
	ui:dispose();
end

function scene.didExitScene(self, event)
	local scene = self;	
	scene.actionBarMenu:dispose();
	scene.actionBarMenu = nil;
	scene.settingsBarMenu:dispose();
	scene.settingsBarMenu = nil;
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;