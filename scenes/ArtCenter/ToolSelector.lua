local ui = require('modules.ui');
local data = require('modules.data');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 75;
local BUTTON_HEIGHT = 75;
local BUTTON_PADDING = 8;

local ToolSelector = {};

local function onButtonRelease(event)
	local self = event.target;
	self._scene:dispatchEvent({
		name = "toolSelection",
		target = self._scene,
		tool = self.id,
		toolModule = self.module
	});
end

ToolSelector.new = function(scene, height)
	local group = display.newGroup();
	local toolData = data.readJSON(DATA_PATH);
	local toolButtons = toolData.tools;

	for i=1,#toolButtons do
		local button = ui.button.new({
			id = toolButtons[i].id,
			imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_' .. toolButtons[i].id .. '_up.png',
			imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_' .. toolButtons[i].id .. '_down.png',
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button.index = i;
		button.anchorX = 0;
		button.anchorY = 0;
		button.x = (i-1) * (BUTTON_WIDTH + BUTTON_PADDING);
		button.y = 0;
		button._scene = scene;
		button:addEventListener('release', onButtonRelease);
		group:insert(button);
	end

	if (scene) then scene.view:insert(group); end
	return group;
end

return ToolSelector;