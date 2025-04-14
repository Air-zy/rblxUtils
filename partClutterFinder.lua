local uniques = {}

local function UIDPART(part)
	local cf = part.CFrame
	local size = part.Size
	local pos = cf.Position
	local look = cf.LookVector
	local up = cf.UpVector
	local transparency = part.Transparency

	local uid =
		math.floor(pos.X * 1000) .. "," ..
		math.floor(pos.Y * 1000) .. "," ..
		math.floor(pos.Z * 1000) .. "_" ..
		math.floor(size.X * 1000) .. "," ..
		math.floor(size.Y * 1000) .. "," ..
		math.floor(size.Z * 1000) .. "_" ..
		math.floor(look.X * 1000) .. "," ..
		math.floor(look.Y * 1000) .. "," ..
		math.floor(look.Z * 1000) .. "_" ..
		math.floor(up.X * 1000) .. "," ..
		math.floor(up.Y * 1000) .. "," ..
		math.floor(up.Z * 1000) .. "_" ..
		math.floor(transparency * 1000)

	return uid
end
local countFound = 0
for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("BasePart") then
		local uid = UIDPART(v)
		if uniques[uid] then
			countFound += 1
			print(v,"DUPLICATE FOUND", uniques[uid])
		else
			uniques[uid] = v
		end
	end
end

if countFound > 0  then
	warn(tostring(countFound).." found, CLICK ON THE PART NAME TO SELECT")
else
	warn("NO CLUTTER FOUND")
end
