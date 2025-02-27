local function tokenize(code)
	local tokens = {}
	local pos = 1
	local line = 1
	local inSingleLineComment = false
	local inMultiLineComment = false
	local len = #code

	local stringStarters = {[["]], [[']], "[[", "[=["}
	local stringEnders   = {[["]], [[']], "]]", "]=]"}
	local isString = false
	local stringI = 0
	local stringStart = 0

	local keywords = {
		["local"]    = true,
		["function"] = true,
		["end"]      = true,
		["do"]       = true,
		["if"]       = true,
		["then"]     = true,
		["else"]     = true,
		["elseif"]   = true,
		["for"]      = true,
		["while"]    = true,
		["repeat"]   = true,
		["until"]    = true,
		["return"]   = true, --
		["print"]    = true,
		["warn"]     = true,
		["break"]    = true,
		["continue"] = true,
		-- TODO
	}

	while pos <= len do
		local c = code:sub(pos, pos)

		if c == "\n" then
			line += 1
			inSingleLineComment = false
		end
		if inMultiLineComment and c == "]" and code:sub(pos+1, pos+1) == c then
			--print("ending multiline")
			inMultiLineComment = false
		end
		if inSingleLineComment or inMultiLineComment then
			pos = pos + 1
			continue
		end
		
		if isString == false then
			-- current pos starts a string literal
			for i, starter in ipairs(stringStarters) do
				if code:sub(pos, pos + #starter - 1) == starter then
					isString = true
					--print(starter, "STRING START")
					stringStart = pos
					pos = pos + #starter
					stringI = i
					break
				end
			end
		else
			-- current pos ends a string literal

			local ender = stringEnders[stringI]
			if code:sub(pos, pos + #ender - 1) == ender then
				isString = false
				pos = pos + #ender - 1
				--print("string End", code:sub(stringStart, pos), "line: "..tostring(line))
				--break
				table.insert(tokens, { class = "string", value = code:sub(stringStart, pos), line = line })
			end
			
			pos = pos + 1
			continue
		end
		
		-- ignor whitespace
		if c:match("%s") then
			pos = pos + 1
		elseif c == "-" and code:sub(pos+1, pos+1) == c then -- todo will err if there is - at last position of code
			if code:sub(pos+2, pos+3) == "[[" then
				--print("entering multiline", line)
				inMultiLineComment = true
			else
				inSingleLineComment = true
			end
			pos = pos + 1
		elseif c:match("[%a_]") then -- ids/keywords (starts with a letter or _)
			local last = if pos > 1 then code:sub(pos-1, pos-1) else nil
			local start = pos
			while pos <= len and code:sub(pos, pos):match("[%w_]") do
				pos = pos + 1
			end
			local word = code:sub(start, pos - 1)
			if keywords[word] then
				table.insert(tokens, { class = "keyword", value = word, line = line })
			else
				if last == "." or last == ":" then
					table.insert(tokens, { class = "method", value = word, line = line })
				else
					table.insert(tokens, { class = "identifier", value = word, line = line })
				end
			end
		elseif c == "=" then -- match operatrs and punctuation
			table.insert(tokens, { class = "operator", value = "=", line = line })
			pos = pos + 1
		elseif c == "(" then
			table.insert(tokens, { class = "lparen", value = "(", line = line })
			pos = pos + 1
		elseif c == ")" then
			table.insert(tokens, { class = "rparen", value = ")", line = line })
			pos = pos + 1
		elseif c == "," then
			table.insert(tokens, { class = "comma", value = ",", line = line })
			pos = pos + 1
		elseif c == ";" then
			table.insert(tokens, { class = "semicolon", value = ";", line = line })
			pos = pos + 1
		else
			-- skip any other chars (like puncs not needed for this)
			pos = pos + 1
		end
	end

	return tokens
end

local function analyzeTokens(tokens)
	local scopeStack = {{}}
	--[[
	{
		{
			bool : is used
			num : scope depth
			str : scope name
		},
	}
	]]

	-- get current (innermost) scope
	local function currentScope()
		if #scopeStack == 0 then
			table.insert(scopeStack, {})
		end
		--print(scopeStack, #scopeStack)
		return scopeStack[#scopeStack]
	end

	local function pushScope()
		table.insert(scopeStack, {})
	end

	local i = 1
	local warnTabl = {}
	local function popScope()
		local stackDepth = #scopeStack
		local scope = table.remove(scopeStack)
		--print("popped", scope, i)
		if scope then
		else
			--error(debug.traceback())
			return
		end

		--print(scope, i)
		-- the check
		for var, data in pairs(scope) do
			if not data[1] then -- if not used
				local str = data[3].." '" .. var .. "' declared but not used. line "..tostring(data[4])..". scope depth "..tostring(stackDepth)
				table.insert(warnTabl, {str, scope})
				task.wait() -- main lazy worker
			end
		end
	end

	local function declareVariable(v, scopeName)
		local cs = currentScope()
		local name = v.value
		if cs[name] then return end -- TODO NO NEED?
		--print("decalared", name, #scopeStack)
		cs[name] = {false, #scopeStack, scopeName, v.line}
	end

	-- mark var used by lookin the scope stack (innermost to outermost)
	local function markUsage(name)
		for i = #scopeStack, 1, -1 do
			if scopeStack[i][name] ~= nil then
				--print("marked", name, i, scopeStack[i])
				scopeStack[i][name][1] = true -- is used
				break
			end
		end
	end

	local n = #tokens

	while i <= n do
		local token = tokens[i]

		if token.class == "keyword" then
			if token.value == "local" then
				if i + 1 <= n and (tokens[i+1].class == "identifier" or tokens[i+1] == "method") then
					declareVariable(tokens[i+1], "local")
					i = i + 1
					while i + 1 <= n and tokens[i+1].class == "comma" do
						i = i + 2
						if tokens[i] and (tokens[i].class == "identifier" or tokens[i+1] == "method") then
							declareVariable(tokens[i], "local ...,")
						end
					end
				end
			elseif token.value == "function" then
				if i + 1 <= n and tokens[i+1].class == "identifier" then
					if tokens[i+2] and tokens[i+2].class == "method" then
					else
						declareVariable(tokens[i+1], "function")
					end
					i = i + 1
				end
				pushScope() 
				while i + 1 <= n and tokens[i+1].class ~= "lparen" do
					i = i + 1
				end
				if i + 1 <= n and tokens[i+1].class == "lparen" then
					i = i + 1  -- skip '('
					while i + 1 <= n do
						i = i + 1
						--print(tokens[i])
						if tokens[i].class == "identifier" and tokens[i-1].class ~= "identifier" and tokens[i-1].value ~= "=" then -- for inside
							if tokens[i+1] and tokens[i+1].value == "=" then -- already declared
							else
								declareVariable(tokens[i], "field var")
							end
						elseif tokens[i].class == "rparen" then
							break
						end
					end
				end
			elseif token.value == "do" or token.value == "then" then
				pushScope()
			elseif token.value == "end" or token.value == "elseif" then
				popScope()
			elseif token.value == "repeat" then
				pushScope()
			elseif token.value == "until" then
				popScope()
				pushScope()
			end

		elseif token.class == "identifier" or (tokens[i+1] and tokens[i+1].class == "method") or (tokens[i-1] and tokens[i-1].class == "keyword") then
			markUsage(token.value)
			--print(token.value)
		end

		i = i + 1
	end

	-- for global scope
	while #scopeStack > 0 do
		popScope()
	end

	return warnTabl
end

local function analyzeCode(code)
	local tokens = tokenize(code)
	return analyzeTokens(tokens)
end

local scripts = {}
for _, v in pairs(game:GetDescendants()) do
	if v:IsA("BaseScript") or v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
		if v.Parent == game.CoreGui or v.Source == "" then
			continue
		end
		--[[if v.Name ~= "AttackModule" then
			continue
		end]]

		table.insert(scripts, v)
	end
end

table.sort(scripts, function(a, b)
	local aInSafeLocation = a.Parent == game.Workspace or a.Parent == game.ServerStorage
	local bInSafeLocation = b.Parent == game.Workspace or b.Parent == game.ServerStorage

	if aInSafeLocation ~= bInSafeLocation then
		return not aInSafeLocation
	else
		return a:GetFullName() < b:GetFullName()
	end
end)

-- sigma main
local found = 0
for _, v in pairs(scripts) do
	local warnList = analyzeCode(v.Source)
	if #warnList > 0 then
		found += #warnList
		print("")
		print("inside:",v:GetFullName(),#warnList)
		for i, w in pairs(warnList) do
			warn(w[1], w[2])
		end
		
		--break
	end
end

if found == 0 then
	warn("no scripts found")
end
