local AudioGroup = {};

local AudioManager = require("FRC_Modules.FRC_AudioManager.FRC_AudioManager");

local function throw(errorMessage)
	error("[" .. AudioManager.name .. " ERROR]: " .. errorMessage);
end

local function warn(warnMessage)
	print("[" .. AudioManager.name .. " WARNING]: " .. warnMessage);
end

local defaults = {
	volume = 1.0,
	maxChannels = 3
};

local public = {};

function public:findFreeChannel(force)
	local channel;
	for i=1,#self.channels do
		if (not audio.isChannelActive(self.channels[i])) then
			channel = self.channels[i];
			break;
		end
	end
	if (not channel) then
		if (#self.channels > 0) then
			-- stop least recently used channel and return it
			pcall(function() audio.stop(self.channels[1]); end);
			channel = self.channels[1];
		else
			channel = self:addChannel(force);
		end
	end
	return channel;
end

function public:addChannel(increaseMax)
	if ((not increaseMax) and (#self.channels >= self.maxChannels)) then
		warn("AudioGroup " .. self.name .. " has reached its maximum number of channels. Use audioGroup:addChannel(true) to force (max channels will be incremented).");
		return nil;
	end
	local channel;
	pcall(function() channel = audio.findFreeChannel(); end);
	if (channel) then
		table.insert(self.channels, channel);
		pcall(function() audio.setVolume(self.volume, { channel = channel }); end);
	else
		warn("Cannot add a channel to AudioGroup " .. self.name .. " because there are no more free channels available.");
		return nil;
	end
	return channel;
end

function public:addHandle(audioHandle)
	for i=#self.handles,1,-1 do
		if (self.handles[i].name == audioHandle.name) then
			table.remove(self.handles, i);
		end
	end
	table.insert(self.handles, audioHandle);
	if (audioHandle.group and audioHandle.group ~= self) then
		audioHandle.group:removeHandle(audioHandle);
	else
		audioHandle.group = self;
	end
	return self;
end

function public:findHandle(handleName)
	local handle;
	for i=#self.handles,1,-1 do
		if (self.handles[i].name == handleName) then
			handle = self.handles[i];
			break;
		end
	end
	return handle;
end

function public:removeHandle(audioHandle) -- audioHandle can be a string (name) or an AudioHandle instance
	for i=#self.handles,1,-1 do
		if (self.handles[i] == audioHandle or self.handles[i].name == audioHandle) then
			self.handles[i].group = nil;
			table.remove(self.handles, i);
		end
	end
end

function public:setVolume(volume)
	for i=1,#self.channels do
		pcall(function() audio.setVolume(volume, { channel = self.channels[i] }); end);
	end
	self.volume = volume;
	return self;
end

-- play audio handle with specified name (if it belongs to the group)
function public:play(handleName, options)
	-- DEBUG:
	print("AudioGroup ", self.name, " is now playing: ", handleName, " with ", #self.handles," handles available:", self.handles);
	options = options or {};
	if (not handleName) then
		warn("You must specify a AudioHandle name or provide a reference to the AudioHandle as first argument to audioGroup:play().");
		return 0;
	end
	local handle;
	if (type(handleName) == "string") then
		for i=1,#self.handles do
			-- DEBUG:
			-- print("searching ", self.name," for a matching handle: ",self.handles[i].name);
			if (self.handles[i].name == handleName) then
				handle = self.handles[i];
				break;
			end
		end
	else
		-- TODO:  if 'handleName' is a string referencing a non-existent handle, the next chunk of code breaks
		handle = handleName;
	end
	if (handle.channel) then
		local channelActive = false;
		pcall(function() channelActive = audio.isChannelActive(handle.channel); end);
		if (channelActive) then
			if (options.force) then
				return handle:play(options);
			else
				warn("AudioHandle " .. handle.name .. " is already playing on channel " .. handle.channel .. ". Use options.force = true to force playback on a different channel.");
				return 0;
			end
		end
		handle.channel = nil;
	end
	return handle:play(options);
end

function public:playRandom(options)
	if (#self.handles < 1) then warn("No AudioHandles belong to AudioGroup " .. self.name); return 0; end
	return self.handles[math.random(1, #self.handles)]:play(options);
end

function public:playAll(options)
	if (#self.handles > self.maxChannels) then
		warn("More Audiohandles belong to AudioGroup " .. self.name .. " than its available maxChannels; not all AudioHandles will be played.");
	end
	for i=1,#self.handles do
		self.handles[i]:play(options);
	end
	return self;
end

-- stop audio for a specific handle (by name) or stop all channels
function public:stop(options, options2)
	if (type(options) == "string") then
		-- stop specified audio handle
		return self:findHandle(options):stop(options2);
	else
		-- stop all channels assigned to this group
		options = options or {};
		local result;
		for i=1,#self.channels do
			if (options.delay) then
				pcall(function() result = audio.stopWithDelay(options.delay, { channel = self.channels[i] }); end);
			else
				pcall(function() result = audio.stop(self.channels[i]); end);
			end
		end
		return result;
	end
end

-- pause audio on all channels that belong to the group
function public:pause(handleName)
	if (handleName and type(handleName) == "string") then
		-- pause specified audio handle
		self:findHandle(handleName):pause();
	else
		-- pause all channels assigned to this group
		for i=1,#self.channels do
			pcall(function() audio.pause(self.channels[i]); end);
		end
	end
	return self;
end

-- resume audio on all channels that belong to the group
function public:resume(handleName)
	if (handleName and type(handleName) == "string") then
		-- resume specified audio handle
		self:findHandle(handleName):resume();
	else
		for i=1,#self.channels do
			pcall(function() audio.resume(self.channels[i]); end);
		end
	end
	return self;
end

function public:dispose()
	-- remove group from the AudioManager (removes reference; does not dispose)
	AudioManager:removeGroup(self);

	-- stop audio on all owned channels
	self:stop();

	-- dispose of all audio handles that belong to this group
	for i=#self.handles,1,-1 do
		self.handles[i]:dispose();
		table.remove(self.handles, i);
	end
	self.name = nil;
	-- remove methods
	for k,v in pairs(public) do
		self[k] = nil;
	end
end

function AudioGroup.new(options)
	options = options or {};
	if (options.name) then
		if (AudioManager:isGroupNameTaken(options.name)) then
			local chosenName = options.name;
			options.name = AudioManager:getUniqueGroupName();
			warn("AudioGroup name " .. chosenName .. " is already in use; using unique name: " .. options.name);
		end
	end
	local audioGroup = {};
	audioGroup.name = options.name or AudioManager:getUniqueGroupName();
	audioGroup.handles = {};
	audioGroup.channels = {};
	audioGroup.volume = options.volume or defaults.volume;
	audioGroup.maxChannels = options.maxChannels or defaults.maxChannels;

	-- add all public instance methods
	for k,v in pairs(public) do
		audioGroup[k] = v;
	end

	-- reserve channels for this group
	for i=1,audioGroup.maxChannels do
		audioGroup:addChannel();
	end

	AudioManager:registerGroup(audioGroup);
	return audioGroup;
end

return AudioGroup;
