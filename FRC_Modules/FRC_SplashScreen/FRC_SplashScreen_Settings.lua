local FRC_SplashScreen_Settings = {};

FRC_SplashScreen_Settings.DATA = {
	VIDEOS = {
		{
			HD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_Video_Landscape.m4v',
			HD_VIDEO_SIZE = { width = 1024, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/FRC_SplashScreen_Video_LandscapeLowRes.m4v',
			SD_VIDEO_SIZE = { width = 512, height = 384 },
			VIDEO_SCALE = 'LETTERBOX',
			VIDEO_LENGTH = 5005 },
		{
			HD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/MDMT_Intro1152x768.mp4',
			HD_VIDEO_SIZE = { width = 1152, height = 768 },
			SD_VIDEO_PATH = 'FRC_Assets/FRC_SplashScreen/Video/MDMT_Intro576x384.mp4',
			SD_VIDEO_SIZE = { width = 576, height = 384 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 9067 }
	}
};

return FRC_SplashScreen_Settings;
