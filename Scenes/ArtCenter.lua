local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local storyboard = require('storyboard');

local scene = FRC_ArtCenter.newScene({
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768,
	MENU_SWOOSH_AUDIO = 'FRC_Assets/FRC_ArtCenter/Audio/PUFF_global_ArtCenter_MenuSwoosh.mp3'
});

scene.backHandler = function()
	if (webView) then
		webView.closeButton:dispatchEvent({
			name = "release",
			target = webView.closeButton
		});
	else
		storyboard.gotoScene('Scenes.Home');
	end
end

local imageBase = 'FRC_Assets/MDMT_Assets/Images/';

scene.preCreateScene = function(self, event)
	local toolData = FRC_DataLib.readJSON(FRC_ArtCenter_Settings.DATA.TOOLS);
	local characterStampsTool = nil;
	for i=1,#toolData.tools do
		if (toolData.tools[i].id == "CharacterStampsPalette") then
			characterStampsTool = toolData.tools[i];
			break;
		end
	end
	if (not characterStampsTool) then return; end
	local subtools = characterStampsTool.subtools;

	local savedCharData = FRC_DataLib.readJSON( FRC_DressingRoom_Settings.DATA.DATA_FILENAME, system.DocumentsDirectory);

	if (savedCharData) then
		savedCharData = savedCharData.savedItems;

		for i=1,#savedCharData do
			local char = savedCharData[i];
			table.insert(characterStampsTool.subtools, {
				id = char.id,
				imageFile = char.id .. char.fullSuffix,
				maskFile = char.id .. char.maskSuffix,
				thumbFile = char.id .. char.thumbSuffix,
				width = char.fullWidth,
				height = char.fullHeight,
				defaultScale = 0.90 * display.contentScaleY,
				baseDir = "DocumentsDirectory"
			});
		end
	end
	FRC_ArtCenter.toolData = toolData;
end

scene.postCreateScene = function(self, event)
	--local self = event.target;
	local view = self.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	-- create action bar menu at top left corner of screen
	self.actionBarMenu = FRC_ActionBar.new({
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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_down.png',
				onRelease = function()
					if (self.canvas.isDirty) then
						native.showAlert('Exit?', 'If you exit, your unsaved progress will be lost.\nIf you want to save first, tap Cancel now and then use the Save feature.', { 'Cancel', 'OK' }, function(event)
							if (event.index == 2) then
								storyboard.gotoScene('Scenes.Home');
							end
						end);
					else
						storyboard.gotoScene('Scenes.Home');
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_DressingRoom_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_DressingRoom_down.png',
				onRelease = function()
					if (self.canvas.isDirty) then
						native.showAlert('Exit?', 'If you exit, your unsaved progress will be lost.\nIf you want to save first, tap Cancel now and then use the Save feature.', { 'Cancel', 'OK' }, function(event)
							if (event.index == 2) then
								storyboard.gotoScene('Scenes.DressingRoom');
							end
						end);
					else
						storyboard.gotoScene('Scenes.DressingRoom');
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
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
					local platformName = import("platform").detected;
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
					local screenRect = display.newRect(view, 0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					webView:request("Help/MDMT_FRC_WebOverlay_Help_Main_ArtCenter.html", system.CachesDirectory);

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
			-- SAVE button
			{
				id = "save",
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_down.png',
				onRelease = function(e)
					local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
					local galleryPopup;
					galleryPopup = FRC_GalleryPopup.new({
						title = FRC_ArtCenter_Settings.DATA.SAVE_PROMPT,
						hideBlank = false,
						width = screenW * 0.68,
						height = screenH * 0.65,
						data = FRC_ArtCenter.savedData.savedItems,
						callback = function(e)
							galleryPopup:dispose();
							galleryPopup = nil;
							self.canvas:save(e.id);
							self.canvas.id = FRC_ArtCenter.generateUniqueIdentifier();
							self.actionBarMenu:getItem("load"):setDisabledState(false);
							self.canvas.isDirty = false;
						end
					});
				end
			},
			-- LOAD button (needs icon)
			{
				id = "load",
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_disabled.png',
				isDisabled = (#FRC_ArtCenter.savedData.savedItems < 1),
				onRelease = function(e)
					local function showLoadPopup()
						local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
						local galleryPopup;
						galleryPopup = FRC_GalleryPopup.new({
							title = FRC_ArtCenter_Settings.DATA.LOAD_PROMPT,
							isLoadPopup = true,
							hideBlank = true,
							width = screenW * 0.68,
							height = screenH * 0.65,
							data = FRC_ArtCenter.savedData.savedItems,
							callback = function(e)
								galleryPopup:dispose();
								galleryPopup = nil;
								self.canvas:load(e.data);
								self.canvas.isDirty = false;
							end
						});
					end

					if (not self.canvas.isDirty) then
						showLoadPopup();
					else
						native.showAlert('You have unsaved changes.', 'If you Load, your unsaved progress will be lost.', { "Cancel", "OK" }, function(event)
							if (event.index == 2) then
								showLoadPopup();
							end
						end);
					end
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
				onRelease = self.clearCanvas
			}
		}
	});

	-- create settings bar menu at top left corner of screen
	local musicButtonFocused = false;
	if (FRC_AppSettings.get("soundOn")) then musicButtonFocused = true; end
	self.settingsBarMenu = FRC_SettingsBar.new({
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
					local self = event.target;
					if (FRC_AppSettings.get("soundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("soundOn", false);
						audio.pause(1);
					else
						self:setFocusState(true);
						FRC_AppSettings.set("soundOn", true);
						audio.resume(1);
					end
				end
			}
		}
	});
end

function scene.postEnterScene(self, event)
	--[[
	timer.performWithDelay(30000, function()
		--self.canvas:save(); print('Canvas saved.');
	end, 1);
	--]]
end

return scene;
