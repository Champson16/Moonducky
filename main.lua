-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local storyboard = require('modules.stage');

_G.APP_ID = 'com.fatredcouch.moonducky.songstudio.artcenter';
_G.APP_VERSION = '0.0.3';

display.setStatusBar(display.HiddenStatusBar);
display.setDefault("background", 0.75, 0.75, 0.75);
math.randomseed( os.time() )  -- ensures math.random() is actually random

storyboard.gotoScene('scenes.ArtCenter.Scene');