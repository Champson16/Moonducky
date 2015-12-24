local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_Rehearsal = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal');
local FRC_Rehearsal_Settings = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
-- this is only needed if you want to call table.dump to inspect a table during debugging
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');

local scene = FRC_Rehearsal.newScene();
-- DEBUG:
print("FRC_Rehearsal.newScene");

local imageBase = 'FRC_Assets/MDMT_Assets/Images/';

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

function scene.postCreateScene(self, event)

   local scene = self;
   local view = scene.view;
   local screenW, screenH = FRC_Layout.getScreenDimensions();

   if (scene.sceneMode == "showtime") then
     analytics.logEvent("MDMT.Scene.Showtime");
   else
     analytics.logEvent("MDMT.Scene.Rehearsal");
   end

   -- create action bar menu at top left corner of screen
   scene.actionBarMenu = FRC_ActionBar.new({
         parent = view,
         imageUp = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_up.png',
         imageDown = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_down.png',
         focusState = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_focused.png',
         disabled = 'FRC_Assets/FRC_ActionBar/Images/MDMT_ActionBar_Button_ActionBar_disabled.png',
         buttonWidth = 100,
         buttonHeight = 100,
         buttonPadding = -20,
         bgColor = { 1, 1, 1, .95 },
         buttons = {
            {
               imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_up.png',
               imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_down.png',
               onRelease = function()
                  storyboard.gotoScene('Scenes.Home');
               end
            },
            {
               imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_up.png',
               imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_down.png',
               onRelease = function()
                  storyboard.gotoScene('Scenes.Lobby');
               end
            },
            --[[
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Showtime_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Showtime_down.png',
				onRelease = function()
					storyboard.gotoScene('Scenes.Rehearsal', { params = { mode = "showtime" }  } );
				end
			},

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
			--]]
            -- SAVE button
            {
               id = "save",
               imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_up.png',
               imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_down.png',
               onRelease = function(e)
                 analytics.logEvent("MDMT.Rehearsal.Save");
                  local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
                  local galleryPopup;
                  galleryPopup = FRC_GalleryPopup.new({
                        title = FRC_Rehearsal_Settings.DATA.SAVE_PROMPT,
                        hideBlank = false,
                        width = screenW * 0.85,
                        height = screenH * 0.75,
                        data = scene.saveData.savedItems,
                        callback = function(e)
                           galleryPopup:dispose();
                           galleryPopup = nil;
                           scene:save(e);
                           self.actionBarMenu:getItem("load"):setDisabledState(false); -- after save, enable 'Load' button
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
               isDisabled = ((scene.saveData.savedItems == nil) or (#scene.saveData.savedItems < 1)),
               onRelease = function(e)
                 analytics.logEvent("MDMT.Rehearsal.Load");
                  local function showLoadPopup()
                     local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
                     local galleryPopup;
                     galleryPopup = FRC_GalleryPopup.new({
                           title = FRC_Rehearsal_Settings.DATA.LOAD_PROMPT,
                           isLoadPopup = true,
                           hideBlank = true,
                           width = screenW * 0.85,
                           height = screenH * 0.75,
                           data = scene.saveData.savedItems,
                           callback = function(e)
                              table.dump2(e)
                              galleryPopup:dispose();
                              galleryPopup = nil;
                              scene:load(e);
                           end
                        });
                  end
                  showLoadPopup();
               end
            },

            -- PUBLISHING
            {
               imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Publish_up.png',
               imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Publish_down.png',
               onRelease = function()
                 analytics.logEvent("MDMT.Rehearsal.Publish");
                  local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');
                  local galleryPopup;
                  --table.print_r(scene)
                  galleryPopup = FRC_GalleryPopup.new({
                        title = FRC_Rehearsal_Settings.DATA.PUBLISH_PROMPT,
                        hideBlank = false,
                        width = screenW * 0.85,
                        height = screenH * 0.75,
                        data = scene.publishData.savedItems,
                        callback = function(e)
                           galleryPopup:dispose();
                           galleryPopup = nil;
                           scene:publish(e);
                        end
                     });
               end
            },
            {
               imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
               imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
               onRelease = self.startOver
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
                  if (scene.sceneMode == "showtime") then
                    analytics.logEvent("MDMT.Showtime.Help");
                     webView:request("Help/MDMT_FRC_WebOverlay_Help_Main_Showtime.html", system.CachesDirectory);
                  else
                    analytics.logEvent("MDMT.Rehearsal.Help");
                     webView:request("Help/MDMT_FRC_WebOverlay_Help_Main_Rehearsal.html", system.CachesDirectory);
                  end
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
            --[[
			,{
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
					webView:request("https://fatredcouch.com/page.php?t=products&p=" .. platformName.. "&cacheBypass=".. system.getTimer() );

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
			}
			--]]

         }
      });

   --[[
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
					local self = event.target;
					if (FRC_AppSettings.get("soundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("soundOn", false);
						local musicGroup = FRC_AudioManager:findGroup("music");
						if musicGroup then
							musicGroup:pause();
						end
					else
						self:setFocusState(true);
						FRC_AppSettings.set("soundOn", true);
						local musicGroup = FRC_AudioManager:findGroup("music");
						if musicGroup then
							musicGroup:resume();
						end
					end
				end
			}
		}
	});
	--]]
end

function scene.postExitScene(self, event)
   --ui:dispose();
end

function scene.postDidExitScene(self, event)
   local scene = self;
   scene.actionBarMenu:dispose();
   scene.actionBarMenu = nil;
   -- scene.settingsBarMenu:dispose();
   -- scene.settingsBarMenu = nil;
end

return scene;
