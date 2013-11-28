local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_MemoryGame_Settings = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Settings');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_MemoryGame_Chooser = {};

local function dispose(self)
	for i=self.numChildren,1,-1 do
		self[i]:dispose();
	end
	self:removeSelf();
end

FRC_MemoryGame_Chooser.new = function(scene)
	local group = display.newGroup();

	local buttonData = FRC_DataLib.readJSON(FRC_MemoryGame_Settings.DATA.CHOOSER_BUTTONS).buttons;
	local x = 0;

	for i=1,#buttonData do
		local button = ui.button.new({
			imageUp = buttonData[i].imageUp,
			imageDown = buttonData[i].imageDown,
			disabled = buttonData[i].imageDisabled,
			width = buttonData[i].buttonWidth,
			height = buttonData[i].buttonHeight,
			onRelease = function(event)
				local self = event.target;
				scene:dispatchEvent({
					name = 'memoryGameStart',
					target = scene,
					columns = self.columns,
					rows = self.rows
				});
				group:dispose();
			end
		});
		button.columns = buttonData[i].columns;
		button.rows = buttonData[i].rows;

		group:insert(button);
		button.x = x;
		x = button.x + button.contentWidth + FRC_MemoryGame_Settings.UI.CHOOSER_BUTTON_PADDING;
	end

	group.dispose = dispose;

	return group;
end

return FRC_MemoryGame_Chooser;