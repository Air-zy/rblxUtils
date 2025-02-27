local function tokenize(code)
	local tokens = {}
	local pos = 1
	local line = 1
	local inSingleLineComment = false
	local len = #code

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
		["coroutine.wrap"] = true, -- and create
		-- TODO
	}

	while pos <= len do
		local c = code:sub(pos, pos)
		
		if c == "\n" then
			line += 1
			inSingleLineComment = false
		end
		if inSingleLineComment then
			pos = pos + 1
			continue
		end
		
		-- ignor whitespace
		if c:match("%s") then
			pos = pos + 1
		elseif c == "-" and code:sub(pos+1, pos+1) == c then -- todo will err if there is - at last position of code
			inSingleLineComment = true
			pos = pos + 2
		elseif c:match("[%a_]") then -- ids/keywords (starts with a letter or _)
			local start = pos
			while pos <= len and code:sub(pos, pos):match("[%w_]") do
				pos = pos + 1
			end
			local word = code:sub(start, pos - 1)
			if keywords[word] then
				table.insert(tokens, { class = "keyword", value = word, line = line })
			else
				table.insert(tokens, { class = "identifier", value = word, line = line })
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

	local warnTabl = {}
	local function popScope()
		local i = #scopeStack
		local scope = table.remove(scopeStack)
		if scope then
		else
			return
		end

		--print(scope, i)
		-- the check
		for var, data in pairs(scope) do
			if not data[1] then -- if not used
				local str = data[3].." '" .. var .. "' declared but not used. line "..tostring(data[4])..". scope depth "..tostring(i)
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
				scopeStack[i][name][1] = true -- is used
				--print("marked stack",i,name)
				break
			end
		end
	end

	local i = 1
	local n = #tokens

	--[[local function getPrevUntillWhiteSpace()
		local str = ""
		local breakNext = false
		for i2 = i-10,i do
			if tokens[i2] and breakNext == false then
				local v = tokens[i2]
				if v.class == "identifier" then
					breakNext = true
				end
				str ..= v.value
			else
				break
			end
		end
		print(str)
		return str
	end]]

	while i <= n do
		local token = tokens[i]

		if token.class == "keyword" then
			if token.value == "local" then
				if i + 1 <= n and tokens[i+1].class == "identifier" then
					declareVariable(tokens[i+1], "local")
					i = i + 1
					while i + 1 <= n and tokens[i+1].class == "comma" do
						i = i + 2
						if tokens[i] and tokens[i].class == "identifier" then
							declareVariable(tokens[i], "local ...,")
						end
					end
				end
			elseif token.value == "function" then
				if i + 1 <= n and tokens[i+1].class == "identifier" then
					declareVariable(tokens[i+1], "function")
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
						if tokens[i].class == "identifier" and tokens[i-1].class ~= "identifier" then -- for inside
							--print("declare", tokens[i].value, tokens[i-1])
							declareVariable(tokens[i], "field var")
						elseif tokens[i].class == "rparen" then
							break
						end
					end
				end
			elseif token.value == "do" or token.value == "if" then
				pushScope()
			elseif token.value == "end" then
				popScope()
			elseif token.value == "for" or token.value == "while" or token.value == "repeat" then
				pushScope()
			elseif token.value == "until" then
				popScope()
			end -- tODO im missing more scope delimiters??

		elseif token.class == "identifier" then
			-- assume any identifier not right after a 'local' is a usage.
			markUsage(token.value)
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
		print("inside:",v:GetFullName())
		for i, w in pairs(warnList) do
			warn(w[1], w[2])
		end
	end
end

if found == 0 then
	warn("no scripts found")
end

--[[
local warnList = analyzeCode(game.ReplicatedFirst.FxHandler.Source)
if #warnList > 0 then
	for i, w in pairs(warnList) do
		warn(w[1])--, w[2])
	end
end
]]
