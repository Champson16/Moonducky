local FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_SceneManager = require('FRC_Modules.FRC_SceneManager.FRC_SceneManager');

local scene = FRC_ArtCenter.newScene({
	SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Background_global_main.jpg',
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768
});

scene.postCreateScene = function(event)
	local self = event.target;
	local view = self.view;

	-- create action bar menu at top left corner of screen
	self.actionBarMenu = FRC_ActionBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_up.png',
		imageDown = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_down.png',
		focusState = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_focus.png',
		disabled = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_disabled.png',
		buttonWidth = 75,
		buttonHeight = 75,
		buttonPadding = 40,
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
				onRelease = self.clearCanvas
			}
		}
	});

	-- create settings bar menu at top left corner of screen
	local musicButtonFocused = false;
	if (_G.APP_Settings.soundOn) then musicButtonFocused = true; end
	self.settingsBarMenu = FRC_SettingsBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_Settings_up.png',
		imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_Settings_down.png',
		focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_Settings_focused.png',
		disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_Settings_disabled.png',
		buttonWidth = 75,
		buttonHeight = 75,
		buttonPadding = 40,
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_BackgroundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_BackgroundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_GlobalMenu_Icon_BackgroundMusic_focused.png',
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
	
	if (not buildText) then
		local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
		local screenW, screenH = FRC_Layout.getScreenDimensions();
		buildText = display.newEmbossedText(_G.APP_VERSION, 0, 0, native.systemFontBold, 14);
		buildText:setFillColor(0, 0, 0);
		buildText.anchorX = 1.0;
		buildText.anchorY = 1.0;
		buildText.x = screenW - 8;
		buildText.y = screenH - 10;
	end
end

scene.preEnterScene = function(event)
	audio.play(_G.tempMusic, { channel=1, loops=-1 });
	if (not _G.APP_Settings.soundOn) then
		audio.pause(1);
	end
end

return scene;