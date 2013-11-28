-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
system.activate( "multitouch" )
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");

local FRC_SceneManager = require('FRC_Modules.FRC_SceneManager.FRC_SceneManager');

_G.APP_ID = 'com.fatredcouch.moonducky.musictheatre';
_G.APP_VERSION = '0.9.7';
_G.APP_Settings = {
	soundOn = (system.getInfo("environment") ~= "simulator")
};

_G.tempMusic = audio.loadSound("FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_MechanicalCow.mp3");

display.setStatusBar(display.HiddenStatusBar);
display.setDefault("background", 0.5, 0.5, 0.5);
--display.setDefault("textureWrapX", "repeat");
--display.setDefault("textureWrapY", "repeat");
math.randomseed( os.time() )  -- make math.random() more random

FRC_SceneManager.gotoScene('Scenes.ArtCenter');