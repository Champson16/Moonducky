local storyboard = require('storyboard');
local FRC_SplashScreen = require('FRC_Modules.FRC_SplashScreen.FRC_SplashScreen');
local scene = storyboard.newScene();

function scene.enterScene(self, event)
	analytics.logEvent("MDMT.Scene.Splash");
	--local self = event.target;
	local view = self.view;

	FRC_SplashScreen.new('Scenes.Home');
end

scene:addEventListener('enterScene');

return scene;
