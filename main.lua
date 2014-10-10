-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- this stubs out the print function for performance on device
if ( system.getInfo("environment") == "device" ) then
   print = function() end
end

display.setStatusBar(display.HiddenStatusBar);

--require('dispose');
require("FRC_Modules.FRC_Import.FRC_Import");
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');

-- constants
_G.APP_VERSION = '1.1.10';
-- note: the schema for VERSIONNUM is major version digit, minor version digit . release build two digits 0-padded
-- this allows us to serialize/compare app version settings files
_G.APP_VERSIONNUM = 11.10;

_G.BUNDLE_ID = 'com.fatredcouch.moonducky.musictheatre'; -- this appears to be unused

_G.MUSIC_CHANNEL = 11;
_G.VO_CHANNEL = 12;
_G.SFX_CHANNEL = 13;

--== APP SETTINGS BEGIN ==--
-- TODO:  Move this into a separate module

-- load the save function into the APP_Settings
-- we can use this later to update settings that we save anywhere in the app
local function saveAppSettings()
  FRC_DataLib.saveTable(_G.APP_Settings, "appsettings.json");
end

_G.APP_Settings = FRC_DataLib.loadTable("appsettings.json");
-- DEBUG:
table.dump(_G.APP_Settings);
local outofDateSettings = false;
if (not _G.APP_Settings or not _G.APP_Settings.appVersionNum) then
  outofDateSettings = true;
elseif ( tonumber(_G.APP_Settings.appVersionNum) < tonumber(_G.APP_VERSIONNUM) ) then
  outofDateSettings = true;
end
if (not _G.APP_Settings or outofDateSettings ) then
  -- there were either no settings or the settings file was out of date
  -- setup the defaults
  _G.APP_Settings = {
    -- (system.getInfo("environment") ~= "simulator")
    soundOn = true,
    -- key identifier for the app
    appID = "MDMT",
    -- these aren't used yet.
    -- upgraded = false,
    -- UNUSED?
    purchases = {
      -- NONE AT THIS TIME
    },
    -- disableRateDialog = false,
    launchCount = 0,
    language = "en",
    appVersion = _G.APP_VERSION,
    appVersionNum = _G.APP_VERSIONNUM
  };
  -- save these for later
  saveAppSettings();
end
-- sets up app for fresh launch experience (title animation and title song)
_G.APP_Settings.freshLaunch = true;
-- increment the launchCount
_G.APP_Settings.launchCount = _G.APP_Settings.launchCount + 1;
-- attach the function to the global table
_G.APP_SettingsSave = saveAppSettings;
-- DEBUG:
table.dump(_G.APP_Settings);

--[[]]
if (_G.APP_Settings.soundOn) then
  audio.setVolume(0, { channel=_G.MUSIC_CHANNEL });
  audio.setVolume(0, { channel=_G.VO_CHANNEL });
  audio.setVolume(0, { channel=_G.SFX_CHANNEL });
else
  audio.setVolume(1.0, { channel=_G.MUSIC_CHANNEL });
  audio.setVolume(1.0, { channel=_G.VO_CHANNEL });
  audio.setVolume(1.0, { channel=_G.SFX_CHANNEL });
  -- audio.setVolume(MUSIC_VOLUME, { channel=MUSIC_CHANNEL });
end
--]]

--[[

if (not _G.APP_Settings.receipts) then
  _G.APP_Settings.receipts = {};
end
--]]

--== APP SETTINGS END ==--


_G.ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
_G.NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
_G.KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((_G.NOOK_DEVICE) or (_G.KINDLE_DEVICE)) then
  _G.ANDROID_DEVICE = true;
end

analytics = require('analytics');
analytics:setCurrentProvider('flurry');

--[[
if (_G.ANDROID_DEVICE) then
	analytics.init('');
else
	analytics.init('');
end

analytics.logEvent('App Launched');
--]]

-- Initialize analytics module and log launch event
local analytics = import("analytics");
analytics.init("flurry");
analytics.logEvent("MDMTLaunch");
local storyboard = require('storyboard_legacy');
storyboard.purgeOnSceneChange = true;
storyboard.isDebug = false;

-- initialize ratings module
local FRC_Ratings = import("ratings").init(); -- FRC_Ratings.show() will display "rate" dialog on supported platforms

local function onSystemEvent(event)
  if (event.type == "applicationExit" or event.type == "applicationSuspend") then
    saveAppSettings();
  end
  if (not _G.ANDROID_DEVICE and (not system.getInfo("environment") == "simulator")) then return; end
  if (event.type == "applicationSuspend") then
    local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
    if (currentScene and currentScene.suspendHandler) then
      currentScene.suspendHandler();
    end
  elseif (event.type == "applicationResume") then
      local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
      if (currentScene and currentScene.resumeHandler) then currentScene.resumeHandler(); end
  end
end
Runtime:addEventListener("system", onSystemEvent);

-- android back button
if (_G.ANDROID_DEVICE) then
  local function onKeyEvent(event)
    if ( "back" == event.keyName and event.phase == "up" ) then
      local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
      if (currentScene and currentScene.backHandler) then
        currentScene.backHandler();
      end
      return true;
     end
  end
  Runtime:addEventListener("key", onKeyEvent);
end

--- END APP RATING

---------------------------------------------------------------------------------
-- UNIFY ALL SCENE TRANSITIONS

local cached_gotoScene = storyboard.gotoScene;
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local loader_scene = storyboard.newScene('LoaderScene');
function loader_scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local bg = display.newRect(view, 0, 0, screenW, screenH);
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	bg:setFillColor(0, 0, 0, 1.0);
	view:insert(bg);
end
function loader_scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;

	storyboard.purgeScene(event.params.nextScene);
	cached_gotoScene(event.params.nextScene, { effect=nil, time=0 });
end
loader_scene:addEventListener('createScene');
loader_scene:addEventListener('enterScene');
storyboard.gotoScene = function(sceneName, options)
	if (not options) then options = {}; end
	if (not options.params) then options.params = {}; end
	options.params.nextScene = sceneName;
	options.effect = nil;
	options.time = 0;

	if (options.useLoader) then
		cached_gotoScene('LoaderScene', options);
	else
		cached_gotoScene(sceneName, options);
	end
end

---------------------------------------------------------------------------------

math.randomseed(os.time());
table.shuffle = function(t)
    local n = #t

    while n >= 2 do
        -- n is now the last pertinent index
        local k = math.random(n) -- 1 <= k <= n
        -- Quick swap
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end

    return t
end

FRC_AudioManager:newGroup({
  name = "intro",
  maxChannels = 1
});
FRC_AudioManager:newGroup({
  name = "home",
  maxChannels = 1
});
FRC_AudioManager:newGroup({
  name = "music",
  maxChannels = 1
});

-- this sets up the one time only playback of the application intro
--[[ FRC_AudioManager:newHandle({
  name = "TitleAudio",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_MechanicalCow.mp3",
  group = "intro"
}); --]]
-- load up the background tracks for the title screen
FRC_AudioManager:newHandle({
  name = "MDMTTheme1",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_MechanicalCow.mp3",
  group = "music"
});
FRC_AudioManager:newHandle({
  name = "MDMTTheme2",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_HamstersJustWantToBeFree.mp3",
  group = "music"
});

display.setDefault('background', 0, 0, 0, 1.0);
display.setDefault( "textureWrapX", "clampToEdge" );
display.setDefault( "textureWrapY", "clampToEdge" );
math.randomseed( os.time() )  -- make math.random() more random

storyboard.gotoScene('Scenes.Splash');
