local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_ArtCenter_SubToolSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_SubToolSelector');

local DATA_PATH = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Tools.json';
local BUTTON_WIDTH = 75;
local BUTTON_HEIGHT = 75;
local BUTTON_PADDING = 12;

local FRC_ArtCenter_ToolSelector = {};

-- New tool from top toolbar is selected
local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	if ((scene.mode == scene.modes["BACKGROUND_SELECTION"]) and (self.mode == "BACKGROUND_SELECTION")) then return; end

	scene.mode = scene.modes[self.mode];
	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.module);
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
	local selection = FRC_ArtCenter_SubToolSelector.selection;
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

FRC_ArtCenter_ToolSelector.new = function(scene, height)
	local group = display.newGroup();
	local toolData = FRC_DataLib.readJSON(DATA_PATH);
	local toolButtons = toolData.tools;

	local bg = display.newRoundedRect(0, 0, (BUTTON_WIDTH * #toolButtons) + ((BUTTON_PADDING + 3) * (#toolButtons)), BUTTON_HEIGHT + BUTTON_PADDING * 2, 11);
	bg:setFillColor(0.14, 0.14, 0.14, 1.0);
	bg:setStrokeColor(0, 0, 0, 1.0);
	bg.strokeWidth = 3;
	bg.x = -((BUTTON_PADDING + 3) * 0.5);
	bg.y = bg.height * 0.5 - (BUTTON_PADDING * 0.5) - (BUTTON_PADDING) + 1;
	group:insert(bg);

	group.buttons = display.newGroup();
	group:insert(group.buttons);

	for i=1,#toolButtons do
		local button = ui.button.new({
			id = toolButtons[i].id,
			imageUp = 'FRC_Assets/FRC_ArtCenter/Images/' .. toolButtons[i].images.up,
			imageDown = 'FRC_Assets/FRC_ArtCenter/Images/' .. toolButtons[i].images.down,
			focusState = 'FRC_Assets/FRC_ArtCenter/Images/' .. toolButtons[i].images.focused,
			disabled = 'FRC_Assets/FRC_ArtCenter/Images/' .. toolButtons[i].images.disabled,
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
		button.x = -(((BUTTON_WIDTH + BUTTON_PADDING) * #toolButtons) * 0.5) + (i-1) * (BUTTON_WIDTH + BUTTON_PADDING);
		button.y = 0;
		button._scene = scene;
		button:addEventListener('release', onButtonRelease);
		group.buttons:insert(button);

		-- disable text button
		if (i == #toolButtons) then
			button:setDisabledState(true);
		end
	end

	if (scene) then scene.view:insert(group); end
	return group;
end

return FRC_ArtCenter_ToolSelector;