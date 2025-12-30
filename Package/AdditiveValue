--!strict
-- by air ofc <3
-- (V(b,f) = b + sum_{i in I} f(i)
-- O(1) reads

-- WARNING!! prone to floating point drifting & replication misses drifting
-- so preferably use safe ints... i should rename this to AdditiveInteger

local Signal = require("./Signal")
export type myself = {
	Value: number,
	_mods: {[string]: number},
	
	SetMod: (self:myself, key:string, mod:number)->(),
	GetMod: (self:myself, key:string)->number?,
	RemoveMod: (self:myself, key:string)->(),
		
	onSet: {
		Connect: (self: any, (key: string, num: number) -> ()) -> Signal.Connection,
		Fire:    (self: any, key: string, num: number) -> (),
	}&Signal.Connection,
	
	onRemove: {
		Connect: (self: any, (key: string) -> ()) -> Signal.Connection,
		Fire:    (self: any, key: string) -> (),
	}&Signal.Connection,
	
	initReplicateClient: (self:myself, id:number, remoteEvent:RemoteEvent)->(),
	initReplicateServer: (self:myself, id:number, remoteEvent:RemoteEvent, plr:Player)->(),
	
	new: ()->myself,
	destroy: (self:myself)->(),
}

local module = {
	Name = "additiveValue"
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
		error("Value is readonly you stupid, use:setMod instead")
	else
		rawset(self, key, new)
	end
end

function module.new(initValue:number):myself
	local self = setmetatable({
		v = initValue,
		onSet = Signal.new(),
		onRemove = Signal.new(),
		_mods = {}
	}, module) :: any&myself
	return self
end
function module.destroy(self:myself)
	if self._mods then
		table.clear(self._mods)
	end
	table.clear(self)
	setmetatable(self, nil)
end

---

type privateSelf = myself&{v:number}
function module.SetMod(self:privateSelf, key:string, mod:number)
	local mods = self._mods
	local existingMod = mods[key]
	if existingMod ~= nil then -- override existing
		self.v -= existingMod
	end
	self.v += mod
	mods[key] = mod
	
	self.onSet:Fire(key, mod)
end

function module.GetMod(self:myself, key:string): number?
	return self._mods[key]
end

function module.RemoveMod(self:privateSelf, key:string)
	local mods = self._mods
	local existingMod = mods[key]
	if existingMod ~= nil then
		self.v -= existingMod
		mods[key] = nil
	end
	
	self.onRemove:Fire(key)
end


--- if u wanna replicate stuff between client and server

function module.initReplicateClient(self:privateSelf, repli_id:number, remote:RemoteEvent)
	remote.OnClientEvent:Connect(function(preid:number, typID:number, ...: any)
		if preid ~= repli_id then return end
		if typID == 2 then -- setMod
			local key, num = ...
			self:SetMod(key, num)
		elseif typID == 1 then -- removeMod
			local key = ...
			self:RemoveMod(key)
		end
	end)
end
function module.initReplicateServer(self:privateSelf, repli_id:number, remote:RemoteEvent, plr:Player)
	self.onSet:Connect(function(key: string, num: number) 
		remote:FireClient(plr, repli_id, 2, key, num)
	end)
	self.onRemove:Connect(function(key: string)
		remote:FireClient(plr, repli_id, 1, key)
	end)
end


return table.freeze(module)
