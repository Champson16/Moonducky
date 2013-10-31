local storyboard = require('modules.stage');
local ui = require('modules.ui');

local uitest = storyboard.newScene();

local function onCreateScene(event)
	local self = event.target;
	local view = self.view;

	local s = ui.scrollContainer.new({
		width = 116,
		height = 480,
		xScroll = false
	});
	view:insert(s);

	s.x = 100;
	s.y = 300;


	--local button = display.newImageRect('assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png', 48, 48);
	local button = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png',
		width = 48,
		height = 48
	});

	s:insert(button);
	button.y = -(s.height * 0.5) + button.height * 0.5;

	--local button2 = display.newImageRect('assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png', 48, 48);
	local button2 = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_FreehandDraw_up.png',
		width = 48,
		height = 48
	});
	s:insert(button2);
	button2.y = (s.height * 0.5) + button.width * 0.5;
end

uitest:addEventListener("createScene", onCreateScene);

return uitest;