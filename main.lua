-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
system.activate( "multitouch" )
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");

local FRC_SceneManager = require('FRC_Modules.FRC_SceneManager.FRC_SceneManager');

_G.APP_ID = 'com.fatredcouch.moonducky.songstudio.artcenter';
_G.APP_VERSION = '0.9.3';

display.setStatusBar(display.HiddenStatusBar);
display.setDefault("background", 0.5, 0.5, 0.5);
--display.setDefault("textureWrapX", "repeat");
--display.setDefault("textureWrapY", "repeat");
math.randomseed( os.time() )  -- make math.random() more random

FRC_SceneManager.gotoScene('Scenes.ArtCenter');