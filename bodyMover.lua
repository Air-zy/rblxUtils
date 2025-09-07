-- by air<3

--[[
when using isRootRelative = true
you sually want the forceVector to be relative to the rootpart:

 > rootpart.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)*100
 > this example is towards camera and force is relative to rootpart
]]

local function absVector3(v: Vector3): Vector3
	return Vector3.new(
		math.abs(v.X),
		math.abs(v.Y),
		math.abs(v.Z)
	)
end

local RunService = game:GetService("RunService")
local stepper = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat

return function(forceVector:Vector3, eRoot:BasePart, t:number?, isRootRelative:boolean?, decayT:number?, decayBias:number?): LinearVelocity
	for _, child in pairs(eRoot:GetChildren()) do
		if child:IsA("LinearVelocity") and child.Name == "KnckBck" then
			child:Destroy()
		elseif child:IsA("Attachment") and child.Name == "KnckBckAtt" then
			child:Destroy()
		end
	end
	
	local attachment = eRoot:FindFirstChild("RootAttachment") or eRoot:FindFirstChild("KnckBckAtt")
	if attachment == nil then
		attachment = Instance.new("Attachment")
		attachment.Name = "KnckBckAtt"
		attachment.Parent = eRoot
	end
	
	local dir = forceVector.Unit
	local maxforce = absVector3(dir) * eRoot.AssemblyMass * 10000
	
	local lv = Instance.new("LinearVelocity")
	lv.Name = "KnckBck"
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Attachment0 = attachment
	lv.VectorVelocity = forceVector
	lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	lv.MaxAxesForce = maxforce
	lv.Parent = eRoot
	
	if t == nil then t = 0.1 end
	if decayBias == nil then decayBias = 0.8 end -- ^decayBias
	
	local endt = tick() + t
	task.spawn(function()
		local decayTime = (decayT or 1)
		local decayEndT = tick() + decayTime
		while tick() < endt do
			local t = (decayEndT - tick()) / decayTime
			if isRootRelative then			
				local relativeFV = eRoot.CFrame:VectorToWorldSpace(forceVector)
				local dir = relativeFV.Unit
				local maxforce = absVector3(dir) * eRoot.AssemblyMass * 10000
				
				if decayT then
					lv.VectorVelocity = relativeFV*(t^decayBias)
				else
					lv.VectorVelocity = relativeFV
				end
				lv.MaxAxesForce = maxforce
			elseif decayT ~= nil then
				lv.VectorVelocity = forceVector*(t^decayBias)
			end
			stepper:Wait() 
		end
		if lv and lv.Parent then
			lv:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)
	
	return lv
end
