-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
system.activate( "multitouch" )
require("modules.multitouch")
require("modules.pinchlib")

local storyboard = require('modules.stage');

_G.APP_ID = 'com.fatredcouch.moonducky.songstudio.artcenter';
_G.APP_VERSION = '0.0.10';

-- TODO: once display.captureBounds() works properly on device, compatibility drawing mode will no longer be needed
if (system.getInfo("environment") == "simulator") then
	_G.COMPAT_DRAWING_MODE = false;
else
	_G.COMPAT_DRAWING_MODE = true;
end

--_G.COMPAT_DRAWING_MODE = true; -- force compatibility mode

display.setStatusBar(display.HiddenStatusBar);
display.setDefault("background", 0.5, 0.5, 0.5);
math.randomseed( os.time() )  -- make math.random() more random

storyboard.gotoScene('scenes.ArtCenter.Scene');
--storyboard.gotoScene('scenes.uitest');