local version = "1.0.0";
local AudioManager = {};

local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib");

math.randomseed(os.time());
AudioManager.name = "FRC_AudioManager";
AudioManager.groups = {};

local function throw(errorMessage)
	error("[" .. AudioManager.name .. " ERROR]: " .. errorMessage);
end

local function warn(warnMessage)
	print("[" .. AudioManager.name .. " WARNING]: " .. warnMessage);
end

function AudioManager:isGroupNameTaken(name)
	local taken = false;
	for i=1,#self.groups do
		if (self.groups[i].name == name) then
			taken = true;
			break;
		end
	end
	return taken;
end

function AudioManager:getUniqueGroupName(digits)
	digits = digits or 5;
	local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };
	local s = '';
	for i=1,digits do
		if (i == 1) then
			s = s .. alphabet[math.random(1, #alphabet)];
		elseif (math.random(0,1) == 1) then
			s = s .. math.random(0, 9);
		else
			s = s .. alphabet[math.random(1, #alphabet)];
		end
	end

	local name = tostring(s);
	if (self:isGroupNameTaken(name)) then
		name = self:getUniqueGroupName();
	end
	return name;
end

function AudioManager:isHandleNameTaken(name)
	local taken = false;
	for i=1,#self.groups do
		for j=1,#self.groups[i].handles do
			if (self.groups[i].handles[j].name == name) then
				taken = true;
				break;
			end
			if (taken) then
				break;
			end
		end
	end
	return taken;
end

function AudioManager:getUniqueHandleName(digits)
	digits = digits or 5;
	local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };
	local s = '';
	for i=1,digits do
		if (i == 1) then
			s = s .. alphabet[math.random(1, #alphabet)];
		elseif (math.random(0,1) == 1) then
			s = s .. math.random(0, 9);
		else
			s = s .. alphabet[math.random(1, #alphabet)];
		end
	end

	local name = tostring(s);
	if (self:isHandleNameTaken(name)) then
		name = self:getUniqueHandleName();
	end
	return name;
end

function AudioManager:registerGroup(audioGroup)
	local name = audioGroup.name;
	if (not name) then throw("Cannot register an AudioGroup that does not have a name (audioGroup.name == nil)."); end
	local overwrite = false;
	for i=#self.groups,1,-1 do
		if (self.groups[i].name == name) then
			table.remove(self.groups, i);
			overwrite = true;
			break;
		end
	end
	table.insert(self.groups, audioGroup);

	if (overwrite) then
		warn("AudioGroup was overwritten when registering: " .. name);
	end
	return audioGroup;
end

function AudioManager:newGroup(...)
	local FRC_AudioGroup = require("FRC_Modules.FRC_AudioManager.FRC_AudioGroup");
	return FRC_AudioGroup.new(...);
end

function AudioManager:findGroup(name)
	local group;
	for i=#self.groups,1,-1 do
		if (self.groups[i].name == name) then
			group = self.groups[i];
			break;
		end
	end
	return group;
end

function AudioManager:findGroupForHandle(name)
	local handle;
	for i=1,#self.groups do
		for j=1,#self.groups.handles do
			if (self.groups[i].handles[j] == name or self.groups[i].handles[j].name == name) then
				handle = self.groups[i].handles[j];
				break;
			end
		end
		if (handle) then break; end
	end
	return handle;
end

function AudioManager:findHandle(name)
	local handle = self:findGroupForHandle(name);
	return handle;
end

function AudioManager:disposeAllGroups()
	for i=#self.groups,1,-1 do
		self.groups[i]:dispose();
	end
	self.groups = {};
end

function AudioManager:removeGroup(name)
	local result = false;
	for i=#self.groups,1,-1 do
		if ((self.groups[i] == name) or (self.groups[i].name == name)) then
			table.remove(self.groups, i);
			result = true;
		end
	end
	return result;
end

function AudioManager:newHandle(...)
	local FRC_AudioHandle = require("FRC_Modules.FRC_AudioManager.FRC_AudioHandle");
	return FRC_AudioHandle.new(...);
end

return AudioManager;
