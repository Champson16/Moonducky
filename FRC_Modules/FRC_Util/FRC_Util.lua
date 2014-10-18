math.randomseed(os.time());
table.shuffle = function(t)
	local n = #t;

	while n >= 2 do
		-- n is now the last pertinent index
		local k = math.random(n); -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n];
		n = n - 1;
	end

	return t;
end

-- utility function for dumping out a table of data
table.dump = function(t, indent)
	local notindent = (indent == nil);
	if (notindent) then print('-----table-----'); indent='{}'; end
	if (t and type(t) == 'table') then
		for k, v in pairs(t) do
			if (type(k) ~= 'number') then
				print(indent .. '.' .. k .. ' = ' .. tostring(v))
				if (indent) then
					table.dump(v, indent..'.'..k);
				end
			end
		end
		for i=1, #t do
			print(indent .. '[' .. i .. '] = ' .. tostring(t[i]));
			table.dump(t[i], indent .. '[' .. i .. ']');
		end
	end
	if (notindent) then print('-----table-----'); end
end

table.serialize = function (name, object, tabs)
	local function serializeKeyForTable(k)
		if type(k)=="number" then
			return "[" .. k .. "]"; -- return /[1337]/ if number
		end
		if string.find(k,"[^A-z_-]") then --special symbols in it?
			return "[\"" .. k .. "\"]";
		end
		return k; -- /leet/ if string
	end

	local function serializeKey(k)
		if type(k)=="number" then
			return "\t[" .. k .."] = ";
		end
		if string.find(k,"[^A-z_-]") then
			return "\t[\"" .. k .. "\"] = ";
		end
		return "\t" .. k .. " = ";
	end

	if not tabs then tabs = ""; end

	local function serialize(name, object, tabs)
		local output = tabs .. name .. " = {" .. "\n";
		for k,v in pairs(object) do
			local valueType = type(v);
			if valueType == "string" then
				output = output .. tabs .. serializeKey(k) .. string.format("%q",v);
			elseif valueType == "table" then
				output = output .. serialize(serializeKeyForTable(k), v, tabs.."\t");
			elseif valueType == "number" then
				output = output .. tabs .. serializeKey(k) .. v;
			elseif valueType == "boolean" then
				output = output .. tabs .. serializeKey(k) .. tostring(v);
			else
				output = output .. tabs .. serializeKey(k) .. "\"" .. tostring(v) .. "\"";
			end
			if next(object,k) then
				output = output .. ",\n";
			end
		end
		return output .. "\n" .. tabs .. "}";
	end

	return serialize(name, object, tabs)  .. "\n" .. "return xmltable;";

end
