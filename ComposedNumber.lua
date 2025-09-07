--!strict
local Signal = require("./Signal")
local NumberValue = require("./valueBase/numberValue")
type numValue = NumberValue.NumberValue

export type myself = {
	Value: number, -- read only
	baseValue: numValue,
	
	_Modifiers: {[string]: numValue},
	Changed: {
		Connect: (self: any, (value:number) -> ()) -> Signal.Connection,
		Fire:    (self: any, value:number) -> (),
	}&Signal.Connection,
	OnModifierAdded: {
		Connect: (self: any, (key: string, numVal: numValue & number) -> ()) -> Signal.Connection,
		Fire:    (self: any, key: string, numVal: numValue & number) -> (),
	}&Signal.Connection,
	OnModifierRemoved: {
		Connect: (self: any, (key: string) -> ()) -> Signal.Connection,
		Fire:    (self: any, key: string) -> (),
	}&Signal.Connection,

	AddModifier:    (self: myself, key: string, numVal: numValue) -> (),
	SetModifier:    (self: myself, key: string, num: number) -> (),
	GetModifier:    (self: myself, key: string) -> numValue?,
	RemoveModifier: (self: myself, key: string) -> (),
	Recalculate:    (self: myself) -> (),
	
	initReplicateClient: (self:myself, id:number, remoteEvent:RemoteEvent)->(),
	initReplicateServer: (self:myself, id:number, remoteEvent:RemoteEvent, plr:Player)->(),
	
	new: (initValue: number) -> myself,
	destroy: (self: myself) -> (),
}

--[==[

AddModifier vs SetModifier

Add Modifier takes in a NUMBER VALUE
meaning you can change the value of the numVal to change the baseValue of the composed number

Set Modifier just takes in a static number

> air just kiss me already

]==]







local module = {
	Name = "ComposedNumber"
}
module.__index = function(self, key)
	if key == "Value" then
		return rawget(self, "v")
	else
		return module[key]
	end
end
module.__newindex = function(self, key, new)
	if key == "Value" then
		error("Value is readonly you stupid, use:SetModifier instead")
	else
		rawset(self, key, new)
	end
end

function module.new(initValue: number): myself
	local self:myself = setmetatable({
		v = initValue,
		baseValue  = NumberValue.new(initValue),
		_Modifiers = {},
		Changed           = Signal.new(),
		OnModifierAdded   = Signal.new(),
		OnModifierRemoved = Signal.new(),
	}, module) :: any

	-- recalc on baseValue changes
	self.baseValue.Changed:Connect(function()
		self:Recalculate() -- TODO recalc method maybe optimizble if only this value changes
	end)

	return self
end

function module.destroy(self: myself)
	self.baseValue:destroy()
	self.OnModifierAdded:Destroy()
	self.OnModifierRemoved:Destroy()
	self.Changed:Destroy()
	table.clear(self._Modifiers)
	table.clear(self)
	setmetatable(self, nil)
end

-- recalc final value
function module:Recalculate()
	local sum:number = self.baseValue.Value
	for _, mod in pairs(self._Modifiers) do
		sum += mod.Value
	end
	self.v = sum
	self.Changed:Fire(sum)
end

-- use this instead of addmodifier lol
function module:SetModifier(key: string, num: number)
	local modifiers = self._Modifiers
	if modifiers[key] == nil then
		local newVal = NumberValue.new(num)
		modifiers[key] = newVal
		-- no need for .Changed cuz expects newVal to be static??
	else
		modifiers[key].Value = num
	end
	
	self.OnModifierAdded:Fire(key, num)
	self:Recalculate()
end

function module:AddModifier(key: string, numVal: numValue)
	--[[if self._Modifiers[key] then
		warn("Modifier "..tostring(key).." already exists, overwriting")
	end]]
	self._Modifiers[key] = numVal

	numVal.Changed:Connect(function()
		self:Recalculate()
	end)

	self.OnModifierAdded:Fire(key, numVal)
	self:Recalculate()
end

function module:GetModifier(key: string): numValue?
	return self._Modifiers[key]
end

function module.RemoveModifier(self:myself, key: string)
	local mod:numValue = self._Modifiers[key]
	if mod then
		mod:destroy()
		self._Modifiers[key] = nil
		
		self.OnModifierRemoved:Fire(key)
		self:Recalculate()
	end
end

function module.initReplicateClient(self:myself, repli_id:number, remoteEvent:RemoteEvent)
	remoteEvent.OnClientEvent:Connect(function(preid:number, typID:number, ...: any)
		if preid ~= repli_id then
			return
		end
		
		if typID == 0 then
			local key, val = ...
			if key and val then
				--print("[replicator] add modif", key, val, ...)
				self:AddModifier(key, NumberValue.new(val))
			end
		elseif typID == 1 then
			local key = ...
			--print("[replicator] rem modif", key)
			self:RemoveModifier(key)
		elseif typID == 2 then
			local value = ...
			self.baseValue.Value = value
		elseif typID == 3 then
			local key, val = ...
			if key and val then
				self:SetModifier(key, val)
			end
		end
	end)
end

function module.initReplicateServer(self:myself, repli_id:number, remoteEvent:RemoteEvent, plr:Player)
	self.OnModifierAdded:Connect(function(key: string, numVal) 
		if tonumber(numVal) then
			remoteEvent:FireClient(plr, repli_id, 3, key, numVal)
		else
			remoteEvent:FireClient(plr, repli_id, 0, key, numVal.Value)
		end
	end)
	self.OnModifierRemoved:Connect(function(key: string)
		remoteEvent:FireClient(plr, repli_id, 1, key)
	end)
	self.baseValue.Changed:Connect(function(number: number) 
		remoteEvent:FireClient(plr, repli_id, 2, number)
	end)
end

return table.freeze(module)
