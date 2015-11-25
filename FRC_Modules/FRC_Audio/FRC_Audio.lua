local version = "1.0.0";
local configPath = "FRC_Assets/FRC_Audio/Data/FRC_Audio_Config.json";

local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib");
local module = {};
module.muted = false;

local defaults = {
	volume = 1.0,
	groups = {
		music = {
			tags = {},
			channels = {},
			max_channels = 3,
			volume = 1.0
		},
		sfx = {
			tags = {},
			channels = {},
			max_channels = 5,
			volume = 1.0
		}
	}
};

local audios = {};
local loaded = {};

function module.init()
	module.config = FRC_DataLib.readJSON(configPath, system.ResourceDirectory);
	if (not module.config) then module.config = {}; end
	if (not module.config.volume) then
		module.config.volume = defaults.volume;
	end
	if (not module.config.groups) then
		module.config.groups = defaults.groups;
	end
	if (not module.config.audio) then module.config.audio = {}; end
	
	for i=1,#module.config.audio do
		if (module.config.audio[i].tag and module.config.audio[i].path) then
			module.addAudioPath(module.config.audio[i].tag, module.config.audio[i].path);
		end
	end
	
	if (module.config.volume) then
		audio.setVolume(module.config.volume);
	end
	
	-- ensure a table to hold tags exists for each group
	for k,v in pairs(module.config.groups) do
		if (not module.config.groups[k].tags) then
			module.config.groups[k].tags = {};
		end
		if (not module.config.groups[k].channels) then
			module.config.groups[k].channels = {};
		end
	end
	return module;
end

function module.play(tag, options)
	local options = options or {};
	local handle;
	if (type(tag) ~= "string") then handle = tag; end
	if (not handle) then
		for i=1,#loaded do
			if (loaded[i].tag == tag) then
				handle = loaded[i].handle;
				break;
			end
		end
		if (not handle) then
			handle = module.loadTrack(tag, options.useLoadSound);
		end
		if (not handle) then
			handle = module.loadTrack(randAudio.tag, options.useLoadSound);
		end
	end
	local channel;
	if (options.channel) then
		if (type(options.channel) == "string") then
			if (module.config.channels[options.channel]) then
				channel = module.config.channels[options.channel].channel;
			else
				channel = audio.findFreeChannel();
			end
		elseif (type(options.channel) == "number") then
			channel = options.channel;
		end
	else
		channel = audio.findFreeChannel();
	end
	options.channel = channel;
	pcall(function() module.stop(options.channel); end);
	audio.play(handle, options);
end

function module.stop(channel)
	local chan;
	if (type(channel) == "string") then
		if (module.config.channels[channel]) then
			chan = module.config.channels[options.channel];
		else
			chan = tonumber(channel);
		end
	else
		chan = channel;
	end
	pcall(function() audio.stop(chan); end );
end

function module.pause(channel)
	local chan;
	if (type(channel) == "string") then
		if (module.config.channels[channel]) then
			chan = module.config.channels[options.channel];
		else
			chan = tonumber(channel);
		end
	else
		chan = channel;
	end
	pcall(function() audio.pause(chan); end);
end

function module.resume(channel)
	local chan;
	if (type(channel) == "string") then
		if (module.config.channels[channel]) then
			chan = module.config.channels[options.channel];
		else
			chan = tonumber(channel);
		end
	else
		chan = channel;
	end
	pcall(function() audio.resume(chan); end);
end

function module.getHandle(tag)
	local handle;
	for i=1,#loaded do
		if (loaded[i].tag == tag) then
			handle = loaded[i].handle;
			break;
		end
	end
	return handle;
end

function module.playRandom(tags, options)
	local tags = tags or audios;
	local options = options or {};
	local randAudio = tags[math.random(1,#tags)];
	module.play(randAudio.tag, options);
end

function module.removeAudioFromGroup(tag)
	local result = false;
	for k,v in pairs(module.config.groups) do
		for i=#module.config.groups[k].tags,1,-1 do
			if (module.config.groups[k].tags[i] == tag) then
				table.remove(module.config.groups[k].tags, i);
				result = true;
				break;
			end
		end
	end
	return result;
end

function module.getGroupForAudio(tag)
	local group;
	for k,v in pairs(module.config.groups) do
		for i=1,#module.config.groups[k].tags do
			if (module.config.groups[k].tags[i] == tag) then
				group = k;
				break;
			end
		end
	end
	return group;
end

function module.addToGroup(tag, group)
	if (not module.config.groups[group]) then return false; end
	module.removeAudioFromGroup(tag);
	table.insert(module.config.groups[group].tags, tag);
	return true;
end

function module.loadAudio(tag, useLoadSound)
	local isLoaded = false;
	local handle;
	for i=1,#loaded do
		if (loaded[i].tag == tag) then
			handle = loaded[i].handle;
			isLoaded = true;
			break;
		end
	end
	if (isLoaded) then return handle; end
	for i=1,#audios do
		if (audios[i].tag == tag) then
			if (not useLoadSound) then
				handle = audio.loadStream(audios[i].path);
			else
				handle = audio.loadSound(audios[i].path);
			end
			table.insert(loaded, { tag = tag, path = path, handle = handle });
			break;
		end
	end
	return handle;
end

function module.disposeAudio(tags)
	local pending = {};
	if (type(tags) == "string") then
		table.insert(pending, tags);
	else
		pending = tags;
	end
	local unloadCount = 0;
	for i=1,#pending do
		for j=#loaded,1,-1 do
			if (loaded[j].tag == pending[i]) then
				pcall(function() audio.dispose(loaded[j].handle); end);
				unloadCount = unloadCount + 1;
				table.remove(loaded, j);
				break;
			end
		end
	end
	return unloadCount;
end

function module.addAudioPath(tag, path)
	for i=#audios,1,-1 do
		if (audios[i].tag == tag) then
			table.remove(audios, i);
		end
	end
	table.insert(audios, { tag = tag, path = path });
end

return module;