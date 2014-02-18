local storyboard = require('storyboard');
local FRC_SplashScreen_Settings = require('FRC_Modules.FRC_SplashScreen.FRC_SplashScreen_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_SplashScreen = {};

local ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
local NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
local KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((NOOK_DEVICE) or (KINDLE_DEVICE)) then
  ANDROID_DEVICE = true;
end

FRC_SplashScreen.new = function(nextScene)
	display.setDefault("background", 1.0, 1.0, 1.0);
	local splashGroup = display.newGroup();
	
	splashGroup.freeMemory = function(self)
		if (self.splashVideo) then
			self.splashVideo:pause();
			self.splashVideo:removeSelf();
			self.splashVideo = nil;
		end
		self:removeSelf();
		splashGroup = nil;
	end
	
	local function gotoNextScene()
		splashGroup:freeMemory();
		storyboard.gotoScene(nextScene);
	end

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local videoFile = FRC_SplashScreen_Settings.UI.DEFAULT_VIDEO_PATH;

	local bg = display.newRect(splashGroup, 0, 0, screenW, screenH);
	bg:setFillColor(1.0);
	FRC_Layout.alignToLeft(bg);
	FRC_Layout.alignToTop(bg);

	if (not ANDROID_DEVICE) then
		splashGroup.splashVideo = native.newVideo(0, 0, display.contentWidth, display.contentHeight);
		splashGroup.splashVideo:load(videoFile);
		splashGroup.splashVideo.x = display.contentWidth * 0.5;
		splashGroup.splashVideo.y = display.contentHeight * 0.5;
		splashGroup.splashVideo:addEventListener("video", function(event)
			if (event.phase == "ready") then
				splashGroup.splashVideo:play();
				timer.performWithDelay(FRC_SplashScreen_Settings.UI.VIDEO_LENGTH, gotoNextScene, 1);
			end
		end);
	else
		if ((NOOK_DEVICE) or (KINDLE_DEVICE)) then
			videoFile = FRC_SplashScreen_Settings.UI.LOWRES_VIDEO_PATH;
		end
		media.playVideo(videoFile, false, gotoNextScene);
	end

	if system.getInfo("environment") == "simulator" then
		gotoNextScene();
	end

	return splashGroup;
end

return FRC_SplashScreen;