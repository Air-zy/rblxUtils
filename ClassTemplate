--!strict
-- by air ofc <3
export type myself = {
	Name: string,
	
	new: ()->myself,
	destroy: (self:myself)->(),
}

local module = {
	Name = "Class Template"
}
module.__index = module
module.__tostring = function(self:myself)
	return tostring(self.Name)
end


function module.new():myself
	local self = setmetatable({}, module) :: any&myself
	return self
end

function module.destroy(self:myself)
	table.clear(self)
	setmetatable(self, nil)
end


--- methods




return table.freeze(module)
