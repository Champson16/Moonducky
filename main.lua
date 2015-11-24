_G.edmode = false --EFM
if( _G.edmode ) then
   _G.dprint  = print --EFM
   _G.print = function() end --EFM
else
   _G.dprint = function() end --EFM
end
--require("mobdebug").start() -- ZeroBrane Users
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
local zip = require( "plugin.zip" );
require("FRC_Modules.FRC_Import.FRC_Import");
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

-- push notification support

-- This function gets called when the user opens a notification or one is received when the app is open and active.
-- Change the code below to fit your app's needs.
local function DidReceiveRemoteNotification(message, additionalData, isActive)
    if (additionalData) then
        if (additionalData.discount) then
            -- native.showAlert( "Discount!", message, { "OK" } )
            trace( "Discount!", message); -- DEBUG
            -- Take user to your app store
        elseif (additionalData.actionSelected) then -- Interactive notification button pressed
            -- native.showAlert("Button Pressed!", "ButtonID:" .. additionalData.actionSelected, { "OK"} )
            trace("Button Pressed!", "ButtonID:" .. additionalData.actionSelected); -- DEBUG
        end
    else
        -- native.showAlert("OneSignal Message", message, { "OK" } )
        trace("OneSignal Message", message); -- DEBUG
    end
end

local OneSignal = require("plugin.OneSignal");
-- Uncomment SetLogLevel to debug issues.
-- OneSignal.SetLogLevel(4, 4)
OneSignal.Init("7474c044-8712-11e5-abed-a0369f2d9328", "709462375959", DidReceiveRemoteNotification)

-- constants
-- _G.APP_VERSION = '1.2.04';
-- note: the schema for VERSIONNUM is major version digit, minor version digit . release build two digits 0-padded
-- this allows us to serialize/compare app version settings files
-- _G.APP_VERSIONNUM = 12.04;

-- _G.BUNDLE_ID = 'com.fatredcouch.moonducky.musictheatre'; -- this appears to be unused

_G.MUSIC_CHANNEL = 11;
_G.VO_CHANNEL = 12;
_G.SFX_CHANNEL = 13;

--== APP SETTINGS BEGIN ==--

FRC_AppSettings.init();

-- sets up app for fresh launch experience (title animation and title song)
-- if (not FRC_AppSettings.hasKey("freshLaunch")) then
  FRC_AppSettings.set("freshLaunch", true);
-- end

-- set volume based on previous setting
if (FRC_AppSettings.get("soundOn")) then
  audio.setVolume(1.0, { channel=_G.MUSIC_CHANNEL });
  audio.setVolume(1.0, { channel=_G.VO_CHANNEL });
  audio.setVolume(1.0, { channel=_G.SFX_CHANNEL });
else
  audio.setVolume(0, { channel=_G.MUSIC_CHANNEL });
  audio.setVolume(0, { channel=_G.VO_CHANNEL });
  audio.setVolume(0, { channel=_G.SFX_CHANNEL });
end

local function copyFile( srcName, srcPath, dstName, dstPath, overwrite )
  local results = true;               -- assume no errors

  -- Copy the source file to the destination file
  local rfilePath = system.pathForFile( srcName, srcPath );
  local wfilePath = system.pathForFile( dstName, dstPath );

  local rfh = io.open( rfilePath, "rb" );
  local wfh = io.open( wfilePath, "wb" );

  if  not wfh then
    print( "writeFileName open error!" );
    results = false;                 -- error
  else
    -- Read the file from the Resource directory and write it to the destination directory
    local data = rfh:read( "*a" );

    if not data then
      print( "read error!" );
      results = false;     -- error
    else
      if not wfh:write( data ) then
        print( "write error!" );
        results = false; -- error
      end
    end
  end

  -- Clean up our file handles
  rfh:close();
  wfh:close();

  return results;
end

local function helpInstallListener( event )
  local results, reason;
  if ( event.isError ) then
    print( "Error!" );
  else
    print( "event.name: " .. event.name );
    print( "event.type: " .. event.type );
    if ( event.response and type(event.response) == "table" ) then
      for i = 1, #event.response do
        print( event.response[i] )
      end
    end
    --example response
    --event.response = {
    --[1] = "space.jpg",
    --[2] = "space1.jpg",
    --}
    -- remove the Help file now that it has been uncompressed
    results, reason = os.remove( system.pathForFile( "Help.zip", system.CachesDirectory ) );

    if results then
       print( "Help file removed." );
    else
       print( "Help file does not exist. Uh oh.", reason );
    end

    -- now explicitly for iOS, we need to disable the iCloud backup of the Help files
    -- to prevent the application submission from getting rejected
    -- we are targeting the entire Help subfolder that we unpacked from the .zip earlier
    --[[ results, reason = native.setSync( "Help/", { iCloudBackup = false } );
    if results then
      print( "Help files marked DO NOT BACKUP by iCloud Backup." );
    else
      print( "Help files were NOT marked DO NOT BACKUP by iCloud Backup. Uh oh.", reason );
    end
    --]]
  end
end

-- install Help files if needed
-- check to see if help files exists in the system.CachesDirectory (in case they were cleared by the OS)
-- use the preferences by default
local helpInstalled = FRC_AppSettings.get("helpInstalled");
if helpInstalled then
  -- we need to double check that the files are still there - we use "tabcontent.css" because it's in all of the Help system implementations
  local helpTestData = FRC_DataLib.readFile("tabcontent.css", system.CachesDirectory);
  -- if the file is not found/read, then .readFile will return false
  if (not helpTestData) then
    helpInstalled = false;
  end
end

if (not helpInstalled) then
  -- copy the .zip file from the system.ResourceDirectory to system.DocumentsDirectory
  if copyFile( "Help.zip", system.ResourceDirectory, "Help.zip", system.CachesDirectory ) then
    -- unpack the .zip
    local zipOptions =
    {
        zipFile = "Help.zip",
        zipBaseDir = system.CachesDirectory,
        dstBaseDir = system.CachesDirectory,
        listener = helpInstallListener
    };
    zip.uncompress( zipOptions );
    -- update the AppSettings
    FRC_AppSettings.set("helpInstalled", true);
  end
end


--== APP SETTINGS END ==--


_G.ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
_G.NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
_G.KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((_G.NOOK_DEVICE) or (_G.KINDLE_DEVICE)) then
  _G.ANDROID_DEVICE = true;
end

-- perform Google Play licensing check
if system.getInfo("environment") ~= "simulator" then
  if (_G.ANDROID_DEVICE) then
    local licensing = require( "licensing" );
    licensing.init( "google" );

    local function licensingListener( event )

       local verified = event.isVerified;
       if not event.isVerified then
          --failed verify app from the play store, we print a message
          -- print( "Pirates: Walk the Plank!!!" )
          native.showAlert( "Licensing Check Failed!", "There was a problem verifying the application license with Google Play, please try again.", { "OK" } );
          native.requestExit();  --assuming this is how we handle pirates
       end
    end

    -- DISABLED UNTIL RELEASE BUILD TIME
    -- licensing.verify( licensingListener );
  end
end

-- Initialize analytics module and log launch event
local analytics = import("analytics");
analytics.init("flurry");
analytics.logEvent("MDMTLaunch");
local storyboard = require("storyboard");
storyboard.purgeOnSceneChange = true;
storyboard.isDebug = false;

-- initialize ratings module
local FRC_Ratings = import("ratings").init(); -- FRC_Ratings.show() will display "rate" dialog on supported platforms

local function onSystemEvent(event)
  if (event.type == "applicationExit" or event.type == "applicationSuspend") then
    -- FRC_AppSettings.save();
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
