local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 44;
local BUTTON_HEIGHT = 44;
local BUTTON_PADDING = 44;

local SubToolSelector = {};

local function onButtonPress(event)
	local self = event.target;

	self._scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	local tool = self._scene.selectedTool;
	tool.graphic.image = 'assets/images/UX/FRC_UX_ArtCenter_' .. self.parentId .. '_Brush_' .. self.id .. '.png';
	tool.graphic.width = self.brushSizes[1];
	tool.graphic.height = self.brushSizes[1];
	tool.a = self.brushAlpha;
	tool.arbRotate = self.arbRotate;
end

SubToolSelector.new = function(scene, id, width, height)
	local group = display.newGroup();
	local toolData = data.readJSON(DATA_PATH);
	local toolButtons = toolData.tools;
	local toolData, subToolButtons;

	for i=1,#toolButtons do
		if (toolButtons[i].id == id) then
			toolData = toolButtons[i];
			subToolButtons = toolButtons[i].subtools;
			break;
		end
	end
	if (not subToolButtons) then return; end

	local bg = display.newRoundedRect(0, 0, width, height, 4);
	bg.anchorX = 0;
	bg.anchorY = 0;
	bg:setFillColor(1.0, 1.0, 1.0);
	bg:setStrokeColor(0, 0, 0, 0.5);
	bg.strokeWidth = 6;
	group:insert(bg);

	for i=1,#subToolButtons do
		local button = ui.button.new({
			id = subToolButtons[i].id,
			imageUp = 'assets/images/UX/FRC_UX_ArtCenter_' .. id .. '_Brush_' .. subToolButtons[i].id .. '.png',
			imageDown = 'assets/images/UX/FRC_UX_ArtCenter_' .. id .. '_Brush_' .. subToolButtons[i].id .. '.png',
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button.up:setFillColor(0, 0, 0);
		button.down:setFillColor(0, 0, 0);
		button._scene = scene;
		button.anchorY = 0;
		button.x = width * 0.5;
		button.y = BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		-- brush attributes
		button.parentId = id;
		button.toolModule = toolData.module;
		button.arbRotate = subToolButtons[i].arbRotate or false;
		button.brushAlpha = subToolButtons[i].alpha;
		button.brushSizes = subToolButtons[i].brushSizes;
		button:addEventListener('press', onButtonPress);
		group:insert(button);
	end

	group.parentId = id;

	if (scene) then scene.view:insert(group); end
	return group;
end

return SubToolSelector;