local storyboard = require('modules.stage');
local layout = require('modules.layout');
local ArtCenter = storyboard.newScene();
local ui = require('modules.ui');
local ToolSelector = require('scenes.ArtCenter.ToolSelector');
local BackgroundArtSelector = require('scenes.ArtCenter.BackgroundArtSelector');
local SubToolSelector = require('scenes.ArtCenter.SubToolSelector');
local ColorSelector = require('scenes.ArtCenter.ColorSelector');

local const = {};
const.CANVAS_BORDER = 5;
const.SELECTOR_SIZE = 130;		-- width for vertical selectors; height for horizontal selectors
const.ELEMENT_PADDING = 14;		-- spacing between elements (such as drawing canvas, selectors, etc.)

const.TOOLS = {};
const.TOOLS.PAINTBRUSH1 = 'scenes.ArtCenter.Tools.FreehandDraw';

local canvas;

local function onCreateScene(event)
	print('ArtCenter:createScene');
	local self = event.target;
	local view = self.view;
	local screenW, screenH = layout.getScreenDimensions();
	local canvas_width = screenW - ((const.SELECTOR_SIZE * 2) + (const.ELEMENT_PADDING * 2));
	local canvas_height = screenH - ((const.SELECTOR_SIZE * 2) + (const.ELEMENT_PADDING * 2));
	local map = {};
	for y=0,canvas_height do
		map[y] = {};
		for x=0,canvas_width do
			map[y][x] = 0;
		end
	end
	
	ArtCenter.canvasWidth = canvas_width;
	ArtCenter.canvasHeight = canvas_height;

	local background = display.newImageRect('assets/images/UX/FRC_UX_ArtCenter_Background_global_main.jpg', display.contentWidth, display.contentHeight);
	background.anchorX = 0;
	background.anchorY = 0;
	background.alpha = 0.2;
	view:insert(background);

	local actionButton = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_ActionBar_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_ActionBar_down.png',
		width = 95,
		height = 95
	});
	view:insert(actionButton);
	layout.alignToLeft(actionButton, const.ELEMENT_PADDING);
	layout.alignToTop(actionButton, const.ELEMENT_PADDING);

	local settingsButton = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_SettingsBar_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_SettingsBar_down.png',
		width = 95,
		height = 95
	});
	view:insert(settingsButton);
	layout.alignToRight(settingsButton, const.ELEMENT_PADDING);
	layout.alignToTop(settingsButton, const.ELEMENT_PADDING);

	self.toolSelector = ToolSelector.new(self);
	self.toolSelector.x = (display.contentWidth * 0.5) - (self.toolSelector.contentWidth * 0.5);
	self.toolSelector.y = const.ELEMENT_PADDING;

	self.bgArtSelector = BackgroundArtSelector.new(self, const.SELECTOR_SIZE, self.canvasHeight);
	self.bgArtSelector.x = -((screenW - display.contentWidth) * 0.5);
	self.bgArtSelector.y = (display.contentHeight * 0.5) - (self.bgArtSelector.contentHeight * 0.5);

	self.subToolSelectors = {};
	for i=1,self.toolSelector.numChildren do
		self.subToolSelectors[i] = SubToolSelector.new(self, self.toolSelector[i].id, const.SELECTOR_SIZE, self.canvasHeight);
		self.subToolSelectors[i].x = screenW - ((screenW - display.contentWidth) * 0.5) - (self.subToolSelectors[i].contentWidth);
		self.subToolSelectors[i].y = (display.contentHeight * 0.5) - (self.subToolSelectors[i].contentHeight * 0.5);

		if (i ~= 2) then
			self.subToolSelectors[i].isVisible = false;
		end
	end

	self.colorSelector = ColorSelector.new(self, screenW - (const.ELEMENT_PADDING * 2), const.SELECTOR_SIZE);
	self.colorSelector.x = (display.contentWidth * 0.5) - (self.colorSelector.contentWidth * 0.5);
	self.colorSelector.y = display.contentHeight - (self.colorSelector.contentHeight);

	local canvas_border = display.newRoundedRect(0, 0, canvas_width + (const.CANVAS_BORDER * 2), canvas_height + (const.CANVAS_BORDER * 2), 4);
	canvas_border:setFillColor(0, 0, 0, 0.5);
	canvas_border.x = display.contentWidth * 0.5;
	canvas_border.y = display.contentHeight * 0.5;
	view:insert(canvas_border);

	canvas = require('scenes.ArtCenter.Canvas').new(canvas_width, canvas_height);
	view:insert(canvas);

	self.selectedTool = require(const.TOOLS.PAINTBRUSH1);

	local buildText = display.newText(view, _G.APP_VERSION, 0, 0, native.systemFontBold, 14);
	buildText:setTextColor(0, 0, 0);
	buildText.anchorX = 1.0;
	buildText.anchorY = 1.0;
	buildText.x = screenW - 20;
	buildText.y = screenH - 5;
end

local function onShake(event)
	if event.isShake then
		-- Device was shaken, clear the canvas
		if (system.getInfo("environment") == "simulator") then
			for i=canvas.drawingBuffer.group.numChildren,1,-1 do
				canvas.drawingBuffer.group[i]:removeSelf();
				canvas.drawingBuffer.group[i] = nil;
			end
			canvas.drawingBuffer:invalidate();
			collectgarbage("collect");
		else
			-- TODO: once display.captureBounds() works on device; remove this else condition
			local lastItem = canvas.snapshots[#canvas.snapshots];
			for i=#canvas.snapshots-1,1,-1 do
				canvas.snapshots[i]:removeSelf();
				canvas.snapshots[i] = nil;			
			end
			canvas.snapshots[1] = lastItem;
			collectgarbage("collect");
		end
	end
end

local function onEnterScene(event)
	print('ArtCenter:enterScene');
	local self = event.target;

	-- Create a runtime listener for the shake event
	Runtime:addEventListener("accelerometer", onShake)
end

local function onDidExitScene(event)
	print('ArtCenter:didExitScene');
	local self = event.target;
end

-- scene events
ArtCenter:addEventListener('createScene', onCreateScene);
ArtCenter:addEventListener('enterScene', onEnterScene);
ArtCenter:addEventListener('didExitScene', onDidExitScene);

-- ArtCenter-specific events
local function onToolSelection(event)
	local self = event.target;

	for i=1,#self.subToolSelectors do
		if (self.subToolSelectors[i].parentId == event.tool) then
			self.subToolSelectors[i].isVisible = true;
		else
			self.subToolSelectors[i].isVisible = false;
		end
	end
end
ArtCenter:addEventListener('toolSelection', onToolSelection);

return ArtCenter;