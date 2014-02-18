-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
display.setStatusBar(display.HiddenStatusBar);

--require('dispose');
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");

_G.APP_VERSION = '1.0.6';

_G.APP_Settings = {
	soundOn = (system.getInfo("environment") ~= "simulator")
};

_G.MUSIC_CHANNEL = 1;
_G.VO_CHANNEL = 2;
_G.SFX_CHANNEL = 3;

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

local storyboard = require('storyboard');
storyboard.purgeOnSceneChange = true;
storyboard.isDebug = false;

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

local musicTracks = {
	audio.loadSound("FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_MechanicalCow.mp3"),
	audio.loadSound("FRC_Assets/MDMT_Assets/Audio/MDMT_global_BGMUSIC_HamstersJustWantToBeFree.mp3")
};
musicTracks = table.shuffle(musicTracks);
local currentTrack = 0;

_G.playNextMusicTrack = function(pauseAfter)
	currentTrack = currentTrack + 1;
	if (currentTrack > #musicTracks) then currentTrack = 1; end
	timer.performWithDelay(50, function()
		audio.play(musicTracks[currentTrack], { channel=1, loops=0, onComplete=_G.playNextMusicTrack });
		if (pauseAfter == true) then
			audio.pause(1);
		end
	end, 1);
end

display.setDefault('background', 0, 0, 0, 1.0);
display.setDefault( "textureWrapX", "clampToEdge" );
display.setDefault( "textureWrapY", "clampToEdge" );
math.randomseed( os.time() )  -- make math.random() more random

storyboard.gotoScene('Scenes.Splash');