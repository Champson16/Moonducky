local ui = require('modules.ui');
local data = require('modules.data');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 75;
local BUTTON_HEIGHT = 75;
local BUTTON_PADDING = 8;

local ToolSelector = {};

-- New tool from top toolbar is selected
local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	if ((scene.mode == scene.modes["BACKGROUND_SELECTION"]) and (self.mode == "BACKGROUND_SELECTION")) then return; end

	scene.mode = scene.modes[self.mode];
	scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.module);
	scene.eraserGroup.button:setFocusState(false);
	if ((self.mode == "STAMP_PLACEMENT") or (self.mode == "SHAPE_PLACEMENT") or (self.mode == "BACKGROUND_SELECTION")) then
		scene.eraserGroup.button:setDisabledState(true);
	else
		scene.eraserGroup.button:setDisabledState(false);
	end

	-- set focus state for this button and other tool button siblings
	for i=1,self.parent.numChildren do
		if (self.parent[i] == self) then
			self.parent[i]:setFocusState(true);
		else
			self.parent[i]:setFocusState(false);
		end
	end

	-- show/hide sub-tool selection indicator
	local selection = require('scenes.ArtCenter.SubToolSelector').selection;
	if (selection.isActive) then
		selection.isVisible = self.subToolSelection;
	end

	-- show/hide 'No Color' option in the color palette
	scene.colorSelector:noColorVisible(self.noColorVisible);

	-- de-select any selected shape or stamp
	if (scene.objectSelection) then
		scene.objectSelection:removeSelf();
		scene.objectSelection = nil;
	end

	-- restore selected tool's properties
	if (scene.mode == scene.modes["FREEHAND_DRAW"]) then
		scene.selectedTool.graphic.image = scene.freehandImage;
		scene.selectedTool.graphic.width = scene.freehandWidth;
		scene.selectedTool.graphic.height = scene.freehandHeight;
		scene.selectedTool.a = scene.freehandAlpha;
		scene.selectedTool.arbRotate = scene.freehandArbRotate;

		-- set color for tool to match currently selected color (in case eraser was previously selected)
		scene.colorSelector:changeColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b);
	end

	scene:dispatchEvent({
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
			focusState = 'assets/images/UX/FRC_UX_ArtCenter_Icon_' .. toolButtons[i].id .. '_focused.png',
			disabled = 'assets/images/UX/FRC_UX_ArtCenter_Icon_' .. toolButtons[i].id .. '_disabled.png',
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button.index = i;
		button.module = toolButtons[i].module;
		button.mode = toolButtons[i].mode;
		button.subToolSelection = toolButtons[i].subToolSelection;
		button.noColorVisible = toolButtons[i].noColorVisible;

		button.anchorX = 0;
		button.anchorY = 0;
		button.x = (i-1) * (BUTTON_WIDTH + BUTTON_PADDING);
		button.y = 0;
		button._scene = scene;
		button:addEventListener('release', onButtonRelease);
		group:insert(button);

		-- disable text button
		if (i == #toolButtons) then
			button:setDisabledState(true);
		end
	end

	if (scene) then scene.view:insert(group); end
	return group;
end

return ToolSelector;