--
-- This file gathers and organizes the creation of Global Variables (as much as possible)
--
-- Note: Some global variables may be initialzed elswhere because they are 'context sensitive'
--

--
-- Build Information
--
_G.BUILD_INFO        = system.getInfo('build')


--
-- Environemnt Information--

_G.ON_DEVICE         = (system.getInfo( "environment" )     == "device");
_G.ON_SIMULATOR      = (system.getInfo( "environment" )     == "simulator");
_G.IOS_DEVICE        = (system.getInfo( "platformName" )    == "iPhone OS");
_G.ANDROID_DEVICE    = (system.getInfo( "platformName" )    == "Android");
_G.NOOK_DEVICE       = (system.getInfo( "targetAppStore" )  == "nook");
_G.KINDLE_DEVICE     = (system.getInfo( "targetAppStore" )  == "amazon");
_G.ANDROID_DEVICE    = ANDROID_DEVICE or NOOK_DEVICE or KINDLE_DEVICE;
_G.WINDOWS_DESKTOP   = (system.getInfo("platformName") == "Win");
_G.OSX_DESKTOP       = (system.getInfo("platformName") == "Mac OS X");


_G.fontMoonDucky     = "MoonDucky"
_G.fontOpenSans      = "OpenSans-Semibold"


--
-- Sound and Music Settings
--
_G.MUSIC_CHANNEL  = 11;
_G.VO_CHANNEL     = 12;
_G.SFX_CHANNEL    = 13;

