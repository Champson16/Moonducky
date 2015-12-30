--[[
local meter = require "meter"
meter.create_fps()
meter.create_mem()
--]]
-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

_G.edmode = false --EFM
if( edmode ) then
   _G.dprint  = _G.print --EFM
   require ("FRC_Modules.FRC_Extensions.FRC_Extensions") 
   _G.print = function() end

   local function onKey( event )
      local storyboard = require("storyboard");
      if( event.phase ~= "up" ) then return false end
      if( event.keyName == "d" ) then
         storyboard.gotoScene('Scenes.DressingRoom', { effect="crossFade", time=0 });  -- EFM            
      elseif( event.keyName == "r" ) then
         storyboard.gotoScene('Scenes.Rehearsal', { effect="crossFade", time=0 }); -- EFM
      elseif( event.keyName == "l" ) then
         storyboard.gotoScene('Scenes.Lobby', { effect="crossFade", time=0 }); -- EFM
      end
   end
   Runtime:addEventListener( "key", onKey )   
else
   _G.dprint = function() end --EFM
end

--timer.performWithDelay( 100, function() local storyboard = require("storyboard"); storyboard.gotoScene('Scenes.SetDesign', { effect="crossFade", time=0 }); end )
--timer.performWithDelay( 100, function() local storyboard = require("storyboard"); storyboard.gotoScene('Scenes.DressingRoom', { effect="crossFade", time=0 }); end )
--timer.performWithDelay( 100, function() local storyboard = require("storyboard"); storyboard.gotoScene('Scenes.Rehearsal', { time = 100, params = { mode = "rehearsal", skipCreateLoad = true } }); end )
--timer.performWithDelay( 100, function() local storyboard = require("storyboard"); storyboard.gotoScene('Scenes.Rehearsal', { params = { mode = "showtime" } }); end )
--timer.performWithDelay( 100, function() local storyboard = require("storyboard"); storyboard.gotoScene('Scenes.Lobby', { effect="crossFade", time=0 }); end )
--require("mobdebug").start() -- ZeroBrane Users
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- ==============================================================
-- TRS / EFM - temporary home of swipe threshold till we tune it.
-- ==============================================================
_G.swipeThresh = 25
-- ==============================================================
-- ==============================================================

-- ==============================================================
-- native.showAlert() (bug?) Fix
-- ==============================================================
local native_showAlert = native.showAlert
local lastAlert
native.showAlert = function( ... )
   --dprint( "Calling showAlert()")
   if( lastAlert ) then 
      native.cancelAlert( lastAlert )
      lastAlert = nil
   end
   lastAlert = native_showAlert(unpack(arg))
end
-- ==============================================================
-- ==============================================================


display.setStatusBar(display.HiddenStatusBar);

local FRC_Globals = require('FRC_Modules.FRC_Globals.FRC_Globals');

-- Stub out print when on device for quiet logs
_G.print = ( ON_SIMULATOR ) and _G.print or function() end

-- LOAD BEFORE ALL FRC MODULES
require ("FRC_Modules.FRC_Extensions.FRC_Extensions") 
-- LOAD BEFORE ALL FRC MODULES

--require('dispose');
require("FRC_Modules.FRC_Import.FRC_Import");
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");
local zip                  = require( "plugin.zip" );
local FRC_AudioManager     = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_DataLib          = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Util             = require('FRC_Modules.FRC_Util.FRC_Util');
local FRC_AppSettings      = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');


--
-- Push Notifications
--
local FRC_Notifications = require "FRC_Modules.FRC_Notifications.FRC_Notifications"
FRC_Notifications.init( { enableLogger = false, autoShow = false, oneSignalID = "7474c044-8712-11e5-abed-a0369f2d9328", projectNumber = "709462375959" } )

--== APP SETTINGS BEGIN ==--
FRC_AppSettings.init();
-- sets up app for fresh launch experience (title animation and title song)
FRC_AppSettings.set("freshLaunch", true);

-- EFM this might be best moved elsewhere for compartmentalization
--
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
  if FRC_Util.copyFile( "Help.zip", system.ResourceDirectory, "Help.zip", system.CachesDirectory ) then
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

-- perform Google Play licensing check
if( ON_DEVICE )then
  if ( ANDROID_DEVICE ) then
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
  if ( ANDROID_DEVICE or ON_SIMULATOR ) then 
     if( event.type == "applicationSuspend") then
       local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
       if (currentScene and currentScene.suspendHandler) then
         currentScene.suspendHandler();
       end
     elseif( event.type == "applicationResume" ) then
         local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
         if (currentScene and currentScene.resumeHandler) then currentScene.resumeHandler(); end
     end
   end
end
Runtime:addEventListener("system", onSystemEvent);

-- android back button
if ( ANDROID_DEVICE or ON_SIMULATOR ) then
  local function onKeyEvent(event)
     local key    = event.keyName
     local phase  = event.phase
    if ( phase == "up" and (key == "back" or key == "up" or key == "left" ) ) then
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
---------------------------------------------------------------------------------


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
storyboard.gotoScene('Scenes.Splash');



--
-- Handle case where user clicks local notification while app is not running
--
local launchArgs = ...
if ( launchArgs and launchArgs.notification ) then
    FRC_Notifications.localListener( launchArgs.localListener )
end
timer.performWithDelay( 500, function() system.cancelNotification() end )
