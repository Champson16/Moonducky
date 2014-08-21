math.randomseed(os.time());
table.shuffle = function(t)
	local n = #t

	while n >= 2 do
		-- n is now the last pertinent index
		local k = math.random(n) -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end

	return t
end

-- utility function for dumping out a table of data
table.dump = function(t, indent)
	local notindent = (indent == nil)
	if (notindent) then print('-----table-----'); indent='{}'; end
	if (t and type(t) == 'table') then
					for k, v in pairs(t) do
									if (type(k) ~= 'number') then
													print(indent .. '.' .. k .. ' = ' .. tostring(v))
													if (indent) then
																	table.dump(v, indent..'.'..k)
													end
									end
					end
					for i=1, #t do
									print(indent .. '[' .. i .. '] = ' .. tostring(t[i]))
									table.dump(t[i], indent .. '[' .. i .. ']')
					end
	end
	if (notindent) then print('-----table-----'); end
end
