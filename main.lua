-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local storyboard = require('modules.stage');

_G.APP_ID = 'com.fatredcouch.moonducky.songstudio.artcenter';
_G.APP_VERSION = '0.0.5';

display.setStatusBar(display.HiddenStatusBar);
display.setDefault("background", 0.5, 0.5, 0.5);
math.randomseed( os.time() )  -- make math.random() more random

storyboard.gotoScene('scenes.ArtCenter.Scene');
--storyboard.gotoScene('scenes.uitest');