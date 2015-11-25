local FRC_Audio = require("FRC_Modules.FRC_Audio.FRC_Audio");
local audioQueue = {};

local method = {};

local function getUniqueString(digits)
	digits = digits or 20;
   local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');
   return FRC_Util.generateUniqueIdentifier(digits);
end

function method.play(self, options)
	if (#self.list < 1) then return; end
	local options = options or {};
	if (self.list[self.index]) then
		if (self.activeTrack and self.activeTrack == self.list[self.index]) then
			if (not options.replay) then return; end
		end
		local opt = options;
		if (not opt.channel) then opt.channel = self.channel; end
		opt.onComplete = function()
			self.activeTrack = nil;
			self:pause();
			self:playNext(options);
		end
		self.channel = opt.channel;
		self.activeTrack = self.list[self.index];
		FRC_Audio.loadTrack(self.list[self.index]);
		timer.performWithDelay(50, function()
			FRC_Audio.play(self.list[self.index], opt);
		end, 1);
	end
end

function method.playNext(self, options)
	if (#self.list < 1) then return; end
	self.index = self.index + 1;
	if (self.index > #self.list) then
		self.index = 1;
		if (not self.loop) then return; end
	end
	self:play(options);
end

function method.playRandom(self, options)
	if (#self.list < 1) then return; end
	local current = self.index;
	self.index = math.random(1, #self.list);
	if (self.index == current) then self:playRandom(options); end
	self:play(options);
end

function method.stop(self)
	FRC_Audio.stop(self.channel);
	self.activeTrack = nil;
end

function method.pause(self)
	audio.pause(self.channel);
end

function method.resume(self)
	audio.resume(self.channel);
end

function method.remove(self, tag)
	if (self.activeTrack and self.activeTrack == tag) then self:stop(); end
	for i=#self.list,1,-1 do
		if (self.list[i] == tag) then
			table.remove(self.list, i);
			break;
		end
	end
end

function method.preload(self, useLoadSound)
	if (#self.list < 1) then return; end
	for i=1,#self.list do FRC_Audio.loadTrack(self.list[i], useLoadSound); end
end

function method.removeSelf(self)
	if (#self.list > 0) then
		for i=#self.list,1,-1 do self:pop(); end
	end
	if (FRC_Audio.queues[self.name]) then FRC_Audio.queues[self.name] = nil; end
end

-- Remove first element from track queue
function method.shift(self, unload)
	if (#self.list < 1) then return; end
	if (self.activeTrack and self.activeTrack == self.list[1]) then self:stop(); end
	if (unload) then FRC_Audio.unloadTrack(self.list[1]); end
	table.remove(self.list, 1);
	if (self.index > 1) then self.index = self.index - 1; end
	return #self.list;
end

-- Prepend track (by tag) queue
function method.unshift(self, tag)
	self:remove(tag);
	table.insert(self.list, 1, tag);
	self.index = self.index + 1;
	return #self.list;
end

-- Append track (by tag) to queue
function method.push(self, tag)
	self:remove(tag);
	table.insert(self.list, tag);
	return #self.list;
end

-- Remove last element from track queue
function method.pop(self, unload)
	if (#self.list < 1) then return; end
	if (self.activeTrack and self.activeTrack == self.list[#self.list]) then self:stop(); end
	if (unload) then
		FRC_Audio.unloadTrack(self.list[#self.list]);
	end
	if (self.index == #self.list) then self.index = self.index - 1; end
	table.remove(self.list, #self.list);
	return #self.list;
end

function audioQueue.new(name, tags, channel)
	if (not name or name == "") then name = getUniqueString(); end
	local queue = {};
	queue.name = name;
	queue.list = {};
	queue.index = 1;
	queue.loop = false;
	queue.channel = channel;
	if (type(tags) == "string") then
		table.insert(queue.list, tags);
	elseif (type(tags) == "table") then
		queue.list = tags;
	end
	for k,v in pairs(method) do queue[k] = v; end
	if (FRC_Audio.queues[name]) then FRC_Audio.queues[name]:removeSelf(); end
	FRC_Audio.queues[name] = queue;
	return queue;
end

return audioQueue;