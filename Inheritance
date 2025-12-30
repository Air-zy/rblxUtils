--!strict
local baseClass = require(script.Parent)

export type myself = baseClass.myself & {
	-- my own stuff here
}

local module = {}
module.__tostring = baseClass.__tostring
module.__index = module
setmetatable(module, { __index = baseClass })

function module.new():myself
	local abstract = baseClass.new() :: baseClass.myself
	local self:myself = setmetatable(abstract, module) :: any
	-- my own stuff here
	return self
end

function module.destroy(self:myself)
	-- destroy my own stuff here
	baseClass.destroy(self)
end


--- methods




return table.freeze(module)
