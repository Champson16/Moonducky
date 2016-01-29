-- Extensions to the storyboard.* library
local json = require( "json" )

--
-- Localizations (for speedup)
--
local mRand = math.random

--
local storyboard        = require "storyboard"
local FRC_Layout        = require('FRC_Modules.FRC_Layout.FRC_Layout');

local cached_gotoScene  = storyboard.gotoScene;
local loader_scene      = storyboard.newScene('LoaderScene');
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