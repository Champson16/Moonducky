local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_Rehearsal = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal');
local FRC_CharacterBuilder = require('FRC_Modules.FRC_Rehearsal.FRC_CharacterBuilder') --EFM
local FRC_Rehearsal_Settings = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
-- this is only needed if you want to call table.dump to inspect a table during debugging
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');
local analytics = import("analytics");

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

   if (scene:getSceneMode() == "showtime") then
     analytics.logEvent("MDMT.Scene.Showtime");
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
                     require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                     storyboard.gotoScene('Scenes.Home');
                 end
              },
              {
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_down.png',
                 onRelease = function()
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                    storyboard.gotoScene('Scenes.Lobby');

                 end
              },
              -- LOAD button (needs icon)
              --[[ FOR NOW, this feature is commented out
              {
                 id = "load",
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_down.png',
                 disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_LoadText_disabled.png',
                 isDisabled = ((scene.saveData.savedItems == nil) or (#scene.saveData.savedItems < 1)),
                 onRelease = function(e)
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                   analytics.logEvent("MDMT.Showtime.Load");
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
              }, --]]
              {
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_down.png',
                 onRelease = function()
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                    local screenRect = display.newRect(view, 0, 0, screenW, screenH);
                    screenRect.x = display.contentCenterX;
                    screenRect.y = display.contentCenterY;
                    screenRect:setFillColor(0, 0, 0, 0.75);
                    screenRect:addEventListener('touch', function() return true; end);
                    screenRect:addEventListener('tap', function() return true; end);

                    local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
                    webView.x = display.contentCenterX;
                    webView.y = display.contentCenterY + 20;
                    analytics.logEvent("MDMT.Showtime.Help");
                    webView:request("Help/MDMT_FRC_WebOverlay_Help_Main_Showtime.html", system.CachesDirectory);
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
   else -- must be rehearsal
     analytics.logEvent("MDMT.Scene.Rehearsal");
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
                    FRC_CharacterBuilder.dirtyTest(
                       function()
                          require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                          storyboard.gotoScene('Scenes.Home');
                       end )
                 end
              },
              {
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Lobby_down.png',
                 onRelease = function()
                    FRC_CharacterBuilder.dirtyTest(
                       function()
                          require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                          storyboard.gotoScene('Scenes.Lobby');
                       end )
                 end
              },
              -- SAVE button
              {
                 id = "save",
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_SaveText_down.png',
                 onRelease = function(e)
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
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
                    FRC_CharacterBuilder.dirtyTest(
                       function()
                          require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
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
                        end )


                 end
              },
              -- PUBLISHING
              {
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Publish_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Publish_down.png',
                 onRelease = function()
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
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
                 onRelease = function()  self.startOver() end
                 -- onRelease = function()  FRC_CharacterBuilder.dirtyTest( self.startOver ) end
              },
              {
                 imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_up.png',
                 imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_down.png',
                 onRelease = function()
                    require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene').ensureRehearsalModeStopped()
                    local screenRect = display.newRect(view, 0, 0, screenW, screenH);
                    screenRect.x = display.contentCenterX;
                    screenRect.y = display.contentCenterY;
                    screenRect:setFillColor(0, 0, 0, 0.75);
                    screenRect:addEventListener('touch', function() return true; end);
                    screenRect:addEventListener('tap', function() return true; end);

                    local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
                    webView.x = display.contentCenterX;
                    webView.y = display.contentCenterY + 20;
                    print("scene.sceneMode =", scene:getSceneMode());
                    analytics.logEvent("MDMT.Rehearsal.Help");
                    webView:request("Help/MDMT_FRC_WebOverlay_Help_Main_Rehearsal.html", system.CachesDirectory);
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

   end
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
