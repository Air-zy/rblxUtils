--Settings
local InstaOpenConsts = true
local PanelTransparency = 0.4
local ExecuterName = "pornhub" --not needed
local AllowEdit = false
local SlowMode = false

local MaxScroll = 100000 -- 100000
local ScrollSpeed = 8 -- 8

--Globals
local ScriptIsDead = false
local FuncTrack = {nil,{},nil} -- {func,{id track},typ}
local function GServ(n)
	return game:GetService(n)
end

local function tableLength(t)
	local count = #t
	for _ in pairs(t) do 
		count = count + 1
	end
	return count
end

local UIS               = GServ("UserInputService")
local ReplicateFirst    = GServ("ReplicatedFirst")
local RService          = GServ("RunService")
local GuiService        = GServ("GuiService")
local Players           = GServ("Players")
local CoreGui           = GServ("CoreGui")
local Lplr              = Players.LocalPlayer
local Mouse             = Lplr:GetMouse()

local function DeleteItem(v)
    if v and v.Parent then
        v:Destroy()
    end
    --v.Parent = nil
end

local AllFunctions = {} -- Removed when closes
local function CreateFrame(Pos,Size,FrameColor,FrameTransparency)
	local NewFrame = Instance.new("Frame")
	NewFrame.Size = Size
	NewFrame.Position = Pos
	NewFrame.BackgroundColor3 = FrameColor
	NewFrame.BackgroundTransparency = FrameTransparency
	NewFrame.BorderSizePixel = 0
	return NewFrame
end

local function CreateScrollFrame(Pos,Size,FrameColor,FrameTransparency)
	local BackFrame = Instance.new("Frame")
	BackFrame.Size = Size
	BackFrame.Position = Pos
	BackFrame.BackgroundColor3 = FrameColor
	BackFrame.BackgroundTransparency = FrameTransparency
    BackFrame.ClipsDescendants = true
	BackFrame.BorderSizePixel = 0

    local ScrollFrame = Instance.new("Frame")
	ScrollFrame.Size = UDim2.new(1,0,100,0)
	ScrollFrame.Position = UDim2.new(0,0,0,0)
	ScrollFrame.BackgroundColor3 = FrameColor
	ScrollFrame.BackgroundTransparency = 1
	ScrollFrame.BorderSizePixel = 0
    ScrollFrame.Parent = BackFrame
    ScrollFrame.InputChanged:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseWheel then
            for i = 1,10 do
                if obj.Position.Z > 0 then
                    local newPos = math.clamp(ScrollFrame.Position.Y.Offset+ScrollSpeed,-MaxScroll,0)
                    ScrollFrame.Position =  UDim2.new(0,0,0,newPos)
                else
                    local newPos = math.clamp(ScrollFrame.Position.Y.Offset-ScrollSpeed,-MaxScroll,0)
                    ScrollFrame.Position =  UDim2.new(0,0,0,newPos)
                end
                task.wait()
            end
        end
    end)

    local Grid = Instance.new("UIGridLayout")
    Grid.SortOrder = Enum.SortOrder.Name
    Grid.CellSize = UDim2.new(0.9,0,0,15)
    Grid.CellPadding = UDim2.new(0,0,0,2)
    Grid.Parent = ScrollFrame

	return ScrollFrame, Grid
end

local function CreateTextLabel(Pos,Size,BackColor,BackTransparency,TextColor)
	local NewTBox = Instance.new("TextLabel")
	NewTBox.Size = Size
	NewTBox.Position = Pos
	NewTBox.TextColor3 = TextColor
	NewTBox.TextScaled = true
	NewTBox.Active = false
	NewTBox.Selectable = false
	NewTBox.BackgroundColor3 = BackColor
	NewTBox.BackgroundTransparency = BackTransparency
	NewTBox.BorderSizePixel = 0
	return NewTBox
end

local PrimeGui = Instance.new("ScreenGui")
PrimeGui.ResetOnSpawn = false
PrimeGui.DisplayOrder = 100
PrimeGui.Enabled = true
local _Empty ,InvalidCore = pcall(function()
    PrimeGui.Parent = CoreGui
end)
if InvalidCore then
	warn(" Executer does not support coregui Moved Guis into PlayerGui\n", InvalidCore)
	CoreGui = Lplr:WaitForChild("PlayerGui")
	PrimeGui.Parent = CoreGui
end

local function CreatePanel(Transparency,Size,Pos)
    local MainCanvas = CreateFrame(
        Pos,
        Size,
        Color3.new(0,0,0), Transparency) -- Transparency
    MainCanvas.Parent = PrimeGui
    local GridSize = 10
    local TopBar = CreateFrame(
        UDim2.new(0, 0, 0, 0),
        UDim2.new(1, 0, 0, 20),
        Color3.new(0,0,0), 0.8)
    TopBar.ZIndex = 0
    TopBar.Parent = MainCanvas
    TopBar.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            local d = nil
            d = RService.RenderStepped:Connect(function()
                if ScriptIsDead == false then
                    local mPos = UIS:GetMouseLocation()
                    MainCanvas.Position = UDim2.new(0, math.floor(mPos.X/GridSize)*GridSize, 0, math.floor((mPos.Y-GuiService:GetGuiInset().Y)/GridSize)*GridSize)
                    --UDim2.new(0, x2, 0, y2)
                else
                    d:Disconnect()
                    if r then
                        r:Disconnect()
                    end
                end
            end)
            local r = nil
            r = UIS.InputEnded:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    d:Disconnect()
                    r:Disconnect()
                    r = nil
                    d = nil
                end
            end)
        end
    end)

    local ExitButton = CreateTextLabel(
        UDim2.new(1, -20, 0, 0),
        UDim2.new(0, 20, 1, 0),
        Color3.new(0,0,0), 1,
        Color3.new(1,1,1) --TextColor
    )
    ExitButton.Text = "×"
    ExitButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseMovement then
            ExitButton.Text = "•"
        end
    end)
    ExitButton.InputEnded:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseMovement then
            ExitButton.Text = "×"
        end
    end)
    ExitButton.Parent = TopBar

    return MainCanvas, TopBar, ExitButton
end

local MainCanvas, TopBar, ExitButton = CreatePanel(
    PanelTransparency,
    UDim2.new(0, 150, 0, 80),
    UDim2.new(0.2, 0, 0, -GuiService:GetGuiInset().Y)
)

ExitButton.InputBegan:Connect(function(obj)
    if obj.UserInputType == Enum.UserInputType.MouseButton1 then
        for _,v in pairs(AllFunctions) do
            pcall(function()
                v:Disconnect()
            end)
        end
        DeleteItem(PrimeGui, 0)
        ScriptIsDead = true
    end
end)

function safeString(Item)
	if typeof(Item) == "userdata" then
		return "_userdata"
    elseif typeof(Item) == "table" then
		return "_table"
	else
		return tostring(Item)
	end
end


function DisplayInstance(ins, Panel, f)
    local InsPanel, FuncTBar, ExitButton = CreatePanel(
        PanelTransparency,
        UDim2.new(0, 200, 0, 300),
        Panel.Position + UDim2.new(0, 200, 0, 0)
    )
    ExitButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            DeleteItem(InsPanel, 0)
        end
    end)

    local topLabel = CreateTextLabel(
        UDim2.new(0, 0, 0, 22),
        UDim2.new(1, 0, 0, 20),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
	topLabel.TextYAlignment = Enum.TextYAlignment.Center
    topLabel.TextScaled = true
    topLabel.Text = "  "..string.sub(safeString(ins),1,20)
    topLabel.Parent = InsPanel

    local extraLabel = CreateTextLabel(
        UDim2.new(0, 0, 0.05, 24),
        UDim2.new(1, 0, 0.9, -25),
        Color3.new(0,0,0), 1,
        Color3.new(1,1,1) --TextColor
    )
    extraLabel.TextXAlignment = Enum.TextXAlignment.Left
	extraLabel.TextYAlignment = Enum.TextYAlignment.Top
    extraLabel.TextScaled = false
    extraLabel.RichText = true
    extraLabel.TextSize = 9
    extraLabel.Text = "\n  type: "..string.sub(safeString(type(ins)),1,20)
    extraLabel.Text = extraLabel.Text.."\n  typeof: "..safeString(typeof(ins))
    extraLabel.Text = extraLabel.Text.."\n  raw: "..string.sub(safeString(ins),1,80)
    if typeof(ins) == "Instance" then
        extraLabel.Text = extraLabel.Text.."\n  class: "..safeString(ins.ClassName)
        extraLabel.Text = extraLabel.Text.."\n  parent: "..string.sub(safeString(ins.Parent),1,20)
    end
    extraLabel.Parent = InsPanel

    local downbutton = CreateTextLabel(
        UDim2.new(0, 0, 1, -18),
        UDim2.new(1, 0, 0, 18),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )
    downbutton.TextXAlignment = Enum.TextXAlignment.Center
	downbutton.TextYAlignment = Enum.TextYAlignment.Center
    downbutton.TextScaled = false
    downbutton.RichText = true
    downbutton.TextSize = 9
    downbutton.Text = "get raw"
    downbutton.Parent = InsPanel

    local metaTb = getrawmetatable(ins)
    downbutton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if metaTb then
                DisplayTable(metaTb, InsPanel)
            else
                downbutton.Text = "empty"
            end
        end
    end)

    return InsPanel
end

function DisplayTable(table, Panel)
    local iL,counts = nil,0
    if AllowEdit == true then
        for i,v in pairs(FuncTrack[2]) do
            if v[2] == table then
                iL = i
                counts = counts + 1
            end
        end
        if iL and counts >= 2 then
            FuncTrack[2][iL] = nil
        end
    end
    local TabPanel, FuncTBar, ExitButton = CreatePanel(
        PanelTransparency,
        UDim2.new(0, 200, 0, 300),
        Panel.Position + UDim2.new(0, 200, 0, 0)
    )
    ExitButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if AllowEdit == true then
                local iL = nil
                for i,v in pairs(FuncTrack[2]) do
                    if v[2] == table then
                        iL = i
                    end
                end
                if iL then
                    FuncTrack[2][iL] = nil
                end
            end
            DeleteItem(TabPanel, 0)
        end
    end)

    local topLabel = CreateTextLabel(
        UDim2.new(0, 0, 0, 22),
        UDim2.new(1, 0, 0, 20),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
	topLabel.TextYAlignment = Enum.TextYAlignment.Center
    topLabel.TextScaled = true
    topLabel.Text = "  "..safeString(table)
    topLabel.Parent = TabPanel

    local downbutton = CreateTextLabel(
        UDim2.new(0, 0, 1, -18),
        UDim2.new(1, 0, 0, 18),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )
    downbutton.TextXAlignment = Enum.TextXAlignment.Center
	downbutton.TextYAlignment = Enum.TextYAlignment.Center
    downbutton.TextScaled = false
    downbutton.RichText = true
    downbutton.TextSize = 9
    downbutton.Text = "get raw"
    downbutton.Parent = TabPanel

    local metaTb = getrawmetatable(ins)
    downbutton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if metaTb then
                DisplayTable(metaTb, TabPanel)
            else
                downbutton.Text = "empty"
            end
        end
    end)

    local Scroller = CreateScrollFrame(
        UDim2.new(0.1, 0, 0, 42),
        UDim2.new(0.9, 0, 0.8, 0),
        Color3.new(0,0,0), 1)
    Scroller.Parent.Parent = TabPanel
    local function ClearScroll()
        for _,v in pairs(Scroller:GetChildren()) do
            if v:IsA("TextLabel") then
                DeleteItem(v, 0)
            end
        end
    end

    setScroller(table, Scroller, TabPanel)
    return TabPanel
end

function DisplayFunc(func, Panel)
    if AllowEdit == true then
        FuncTrack[1] = func
        FuncTrack[2] = {}
    end

    local FuncPanel, FuncTBar, ExitButton = CreatePanel(
        PanelTransparency,
        UDim2.new(0, 200, 0, 600),
        Panel.Position + UDim2.new(0, 200, 0, 0)
    )
    ExitButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if AllowEdit == true then
                FuncTrack[1] = nil
                FuncTrack[2] = {}
            end
            DeleteItem(FuncPanel, 0)
        end
    end)

    local topLabel = CreateTextLabel(
        UDim2.new(0, 0, 0, 22),
        UDim2.new(1, 0, 0.1, 0),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
	topLabel.TextYAlignment = Enum.TextYAlignment.Top
    topLabel.TextScaled = false
    topLabel.RichText = true
    topLabel.TextSize = 9
    topLabel.Parent = FuncPanel

    local Scroller = CreateScrollFrame(
        UDim2.new(0.1, 0, 0.15, 0),
        UDim2.new(0.9, 0, 0.85, 0),
        Color3.new(0,0,0), 1)
    Scroller.Parent.Parent = FuncPanel
    local function ClearScroll()
        for _,v in pairs(Scroller:GetChildren()) do
            if v:IsA("TextLabel") then
                DeleteItem(v, 0)
            end
        end
    end

    local infoToggle = false
    local dginfo = debug.getinfo(func)
    local fs,fl,fn,fa,ff = debug.info(func,"slnaf")
    local fName = safeString(rawget(dginfo,"name"))
    local nParams = tonumber(safeString(rawget(dginfo,"numparams")))

    local function offInfo()
        if Scroller and Scroller.Parent and topLabel and topLabel.Parent then
            Scroller.Parent.Visible = true
            topLabel.Size = UDim2.new(1, 0, 0.1, 0)
            infoToggle = false
            if fName and #fName >= 1 then
                fName = string.sub(fName, 1, 10)
            else
                fName = "noname"
            end
            topLabel.Text = "\n  "..fName.."("
            for i = 1,nParams do
                if i == nParams then
                    topLabel.Text = topLabel.Text.."x"
                else
                    topLabel.Text = topLabel.Text.."x,"
                end
            end
            topLabel.Text = topLabel.Text..")"
            if not islclosure(func) then
                topLabel.Text = topLabel.Text.."  [C]"
            end
        end
    end

    local function scrollDisplay(items, typ)
        setScroller(items, Scroller, FuncPanel, typ, func)
    end

    local constantButton = CreateTextLabel(
        UDim2.new(0, 0, 1, 0-15),
        UDim2.new(1/3, 0, 0, 15),
        Color3.new(0,0,0), 0.9,
        Color3.new(1,1,1) --TextColor
    )
    constantButton.TextXAlignment = Enum.TextXAlignment.Center
	constantButton.TextYAlignment = Enum.TextYAlignment.Center
    constantButton.TextScaled = false
    constantButton.RichText = true
    constantButton.TextSize = 9
    constantButton.Text = "Const"
    constantButton.Parent = topLabel
    local upvalButton = constantButton:Clone()
    upvalButton.Text = "Upval"
    upvalButton.Position = UDim2.new(1/3, 0, 1, 0-15)
    upvalButton.Parent = topLabel
    local protoButton = constantButton:Clone()
    protoButton.Text = "Proto"
    protoButton.Position = UDim2.new(2/3, 0, 1, 0-15)
    protoButton.Parent = topLabel
    constantButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if infoToggle == false then
            else
                offInfo()
            end
            ClearScroll()
            local _,err = pcall(function()
                local constants = debug.getconstants(func)
                scrollDisplay(constants, 1)
            end)
            if err then topLabel.Text = err end
        end
    end)
    upvalButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if infoToggle == false then
            else
                offInfo()
            end
            ClearScroll()
            local _,err = pcall(function()
                local upvals = debug.getupvalues(func)
                scrollDisplay(upvals, 2)
            end)
            if err then topLabel.Text = err end
        end
    end)
    protoButton.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if infoToggle == false then
            else
                offInfo()
            end
            ClearScroll()
            local _,err = pcall(function()
                if islclosure(func) then
                    local protos = debug.getprotos(func)
                    scrollDisplay(protos, 3)
                end
            end)
            if err then topLabel.Text = err end
        end
    end)

    offInfo()
    local moreinfo = CreateTextLabel(
        UDim2.new(1, -20, 0, 0),
        UDim2.new(0, 20, 0, 20),
        Color3.new(0,0,0), 1,
        Color3.new(1,1,1) --TextColor
    )
    moreinfo.TextScaled = true
    moreinfo.Text = "ⓘ"
    moreinfo.ZIndex = 10
    moreinfo.Parent = topLabel
    moreinfo.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if fName and #fName >= 1 then
                fName = string.sub(fName, 1, 20)
            else
                fName = "noname"
            end
            topLabel.Text = "\n  "..fName.."("
            for i = 1,nParams do
                if i == nParams then
                    topLabel.Text = topLabel.Text.."x"
                else
                    topLabel.Text = topLabel.Text.."x,"
                end
            end
            topLabel.Text = topLabel.Text..")"
            if not islclosure(func) then
                topLabel.Text = topLabel.Text.."  [C]"
            end

            if infoToggle == false then
                if Scroller and Scroller.Parent and topLabel and topLabel.Parent then
                    ClearScroll()
                    Scroller.Parent.Visible = false
                    topLabel.Text =  topLabel.Text.."\n\n  • Source:"
                    local srcSplit = string.split(safeString(fs),".")
                    for i,v in pairs(srcSplit) do
                        topLabel.Text =  topLabel.Text.."\n  ."..string.sub(safeString(v),1,20)..";"
                    end
                    topLabel.Text =  topLabel.Text.."\n\n  line: "..safeString(fl)
                    topLabel.Text =  topLabel.Text.."\n  nups: "..safeString(rawget(dginfo,"nups"))
                    topLabel.Text =  topLabel.Text.."\n  what: "..safeString(rawget(dginfo,"what"))
                    topLabel.Text =  topLabel.Text.."\n  is_vararg: "..safeString(rawget(dginfo,"is_vararg"))
                    topLabel.Text =  topLabel.Text.."\n  numparams: "..safeString(fa)
                    topLabel.Text =  topLabel.Text.."\n  funcname: "..string.sub(safeString(fn),1,20)
                    topLabel.Text =  topLabel.Text.."\n  namewhat: "..safeString(rawget(dginfo,"namewhat"))
                    topLabel.Text =  topLabel.Text.."\n  LClosure: "..safeString(islclosure(func))
                    topLabel.Text =  topLabel.Text.."\n  "..safeString(func)
                    topLabel.Size = UDim2.new(1, 0, 1, -22)
                    infoToggle = true
                else
                    offInfo()
                    if InstaOpenConsts == true then
                        ClearScroll()
                        local _,err = pcall(function()
                            local constants = debug.getconstants(func)
                            scrollDisplay(constants, 1)
                        end)
                    end
                end
            end
        end
    end)

    if InstaOpenConsts == true then
        ClearScroll()
        local _,err = pcall(function()
            if islclosure(func) then
                local constants = debug.getconstants(func)
                scrollDisplay(constants, 1)
            end
        end)
        if err then topLabel.Text = err end
    end

    return FuncPanel
end

function DisplayGScript(tab, GcViewPanel)
    if AllowEdit == true then
        FuncTrack[1] = nil
        FuncTrack[2] = {}  
    end
    local GScriptPanel, GScriptTBar, ExitGScript = CreatePanel(
        PanelTransparency,
        UDim2.new(0, 200, 0, 600),
        GcViewPanel.Position + UDim2.new(0, 200, 0, 0)
    )
    ExitGScript.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            DeleteItem(GScriptPanel, 0)
        end
    end)

    local topLabel = CreateTextLabel(
        UDim2.new(0, 0, 0, 22),
        UDim2.new(1, 0, 0.2, 0),
        Color3.new(0,0,0), 0.8,
        Color3.new(1,1,1) --TextColor
    )

    local scriptRaw = rawget(getfenv(tab[2][1][2]),"script")
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
	topLabel.TextYAlignment = Enum.TextYAlignment.Top
    topLabel.TextScaled = false
    topLabel.RichText = true
    topLabel.TextSize = 9
    topLabel.Text = "\n  Overview\n"
    topLabel.Text = topLabel.Text.."\n  Script: "..string.sub(safeString(tab[1]),1,20)
    topLabel.Text = topLabel.Text.."\n   • raw: "..string.sub(safeString(scriptRaw),1,20)
    if typeof(scriptRaw) == "Instance" then
        topLabel.Text = topLabel.Text.."\n   • class: "..safeString(scriptRaw.ClassName)
        topLabel.Text = topLabel.Text.."\n   • parent: "..string.sub(safeString(scriptRaw.Parent),1,20)
    end
    topLabel.Text = topLabel.Text.."\n   • amt: "..safeString(#tab[2])
    topLabel.Parent = GScriptPanel

    local Scroller = CreateScrollFrame(
        UDim2.new(0.1, 0, 0.25, 0),
        UDim2.new(0.9, 0, 0.75, 0),
        Color3.new(0,0,0), 1)
    Scroller.Parent.Parent = GScriptPanel

    local LastUPanel = nil
    for i,t in pairs(tab[2]) do
        local f = t[2]
        local fInfo = debug.getinfo(f)
        local FItem = CreateTextLabel(
            UDim2.new(0.2, 0, 0.2, 0),
            UDim2.new(0.9, 0, 0.25, 0),
            Color3.new(0,0,0), 0.8,
            Color3.new(1,1,1) --TextColor
        )
        FItem.TextXAlignment = Enum.TextXAlignment.Left
        FItem.TextYAlignment = Enum.TextYAlignment.Top
        FItem.Text = "  "..rawget(fInfo,"name")
        FItem.Name = "zzz"
        if rawget(fInfo,"name") == "" then
            if rawget(fInfo,"numparams") == 0 and rawget(fInfo,"currentline") == 1 and rawget(fInfo,"is_vararg") == 1 then
                FItem.Text = "  while() do"
                FItem.Name = "aaa"
            else
                if tonumber(safeString(t[1])) then
                    FItem.Text = "  "..rawget(fInfo,"nups")..","..rawget(fInfo,"numparams")
                else
                    FItem.Text = "  • "..safeString(t[1])
                end
                FItem.Name = "zzz"..string.rep("b",11 - math.clamp(tonumber(rawget(fInfo,"nups")),1,10)  )
            end
        else
            FItem.Name = "bbb"..string.rep("b",11 - math.clamp(tonumber(rawget(fInfo,"nups")),1,10)  )
        end
        FItem.InputBegan:Connect(function(obj)
            if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                if LastUPanel then DeleteItem(LastUPanel,0) end
                LastUPanel = DisplayFunc(f, GScriptPanel)
            end
        end)
        FItem.Parent = Scroller
        if SlowMode == true then
            task.wait()
        end
    end

    return GScriptPanel
end

function setScroller(items,Scroller,Panel,typ, f, viewonly)
    local LastUPanel = nil
    local stuff = {}
    for i,v in pairs(items) do
        local FItem = CreateTextLabel(
            UDim2.new(0.2, 0, 0.2, 0),
            UDim2.new(0.9, 0, 0.25, 0),
            Color3.new(0,0,0), 0.8,
            Color3.new(1,1,1) --TextColor
        )
        FItem.TextXAlignment = Enum.TextXAlignment.Left
        FItem.TextYAlignment = Enum.TextYAlignment.Top
        local vTypeof = typeof(v)
        if vTypeof == "string" then
            FItem.TextColor3 = Color3.new(0.6,0.9,0.5)
            if typeof(i) ~= "number" then
                FItem.Text = "  ["..safeString(i).."] '"..safeString(v).."'"
            else
                FItem.Text = "  '"..safeString(v).."'"
            end
            FItem.Name = "yzz"..safeString(v)
        elseif vTypeof == "number" then
            FItem.TextColor3 = Color3.new(0.7,0.4,1)
            if typeof(i) ~= "number" then
                FItem.Text = "  ["..safeString(i).."] "..safeString(v)
            else
                FItem.Text = "  "..safeString(v)
            end
            FItem.Name = "zzz"..safeString(v)
        elseif vTypeof == "boolean" then
            FItem.TextColor3 = Color3.new(0.8,0.3,0.3)
            if typeof(i) ~= "number" then
                FItem.Text = "  ["..safeString(i).."] "..safeString(v)
            else
                FItem.Text = "  "..safeString(v)
            end
            FItem.Name = "zzz"..safeString(v)
        elseif vTypeof == "function" then
            FItem.TextColor3 = Color3.new(0.5,0.7,1)
            local funcName = debug.info(v,"n")
            if string.len(safeString(funcName)) <= 0 then
                if typeof(i) == "number" then
                    funcName = "noname - "..safeString(i)
                else
                    funcName = ""
                end
                FItem.Name = "yyz"..safeString(v)
            else
                FItem.Name = "yyy"..safeString(v)
            end
            if typeof(i) ~= "number" or funcName == "" then
                FItem.Text = "  ["..safeString(i).."] "..safeString(funcName)
            else
                FItem.Text = "  "..safeString(funcName)
            end
        elseif vTypeof == "table" then
            FItem.TextColor3 = Color3.new(1,0.8,0)
            if typeof(i) ~= "number" then
                FItem.Text = "  ["..safeString(i).."] table #"..safeString(tableLength(v))
            else
                FItem.Text = "  table #"..safeString(tableLength(v))
            end
            FItem.Name = "xxx"..safeString(v)
        else
            if typeof(i) ~= "number" then
                FItem.Text = "  ["..safeString(i).."] "..safeString(v)
            else
                FItem.Text = "  "..safeString(v)
            end
            FItem.Name = "www"..safeString(v) 
        end

        if viewonly then
            table.insert(stuff, FItem)
        else
            FItem.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if AllowEdit == true and f then
                        FuncTrack[1] = f
                    end
                    if vTypeof == "function" then
                        if AllowEdit == true then
                            if typ then
                                FuncTrack[1] = v
                                FuncTrack[2] = {}
                            end
                        end
                        if LastUPanel then DeleteItem(LastUPanel,0) end
                        LastUPanel = DisplayFunc(v, Panel)
                    elseif vTypeof == "table" then
                        if AllowEdit == true then
                            if typ then
                                FuncTrack[3] = typ
                            end
                            local a = {i,v}
                            setmetatable(a, {
                                __mode = "kv";
                            })
                            if FuncTrack[2][1] and typeof(FuncTrack[2][#FuncTrack[2]][2]) == "table" then
                                table.insert(FuncTrack[2], a)
                            elseif #FuncTrack[2] <= 1 then
                                FuncTrack[2] = {a}
                            else
                                local fTab = false
                                for _,v in pairs(FuncTrack[2]) do
                                    if v[2] == items then
                                        fTab = true
                                        break
                                    end
                                end
                                if fTab == true then
                                    cTrack[2][#FuncTrack[2]] = a
                                else
                                    FuncTrack[2] = {a}
                                end
                            end
                        end
                        if LastUPanel then DeleteItem(LastUPanel,0) end
                        LastUPanel = DisplayTable(v, Panel)
                    else
                        if AllowEdit == true then
                            if typ then
                                FuncTrack[3] = typ
                            end
                            local a = {i,v}
                            setmetatable(a, {
                                __mode = "kv";
                            })
                            if FuncTrack[2][1] and typeof(FuncTrack[2][#FuncTrack[2]][2]) == "table" then
                                table.insert(FuncTrack[2], a)
                            elseif #FuncTrack[2] <= 1 then
                                FuncTrack[2] = {a}
                            else
                                local fTab = false
                                for _,v in pairs(FuncTrack[2]) do
                                    if v[2] == items then
                                        fTab = true
                                        break
                                    end
                                end
                                if fTab == true then
                                    FuncTrack[2][#FuncTrack[2]] = a
                                else
                                    FuncTrack[2] = {a}
                                end
                            end
                        end
                        if LastUPanel then DeleteItem(LastUPanel,0) end
                        LastUPanel = DisplayInstance(v, Panel, f)
                    end
                end
            end)
        end
        FItem.Parent = Scroller
        if SlowMode == true then
            task.wait()
        end
    end
    if viewonly then
        return stuff
    end
end

function DisplayGC(gc,GcViewPanel)
    local Scroller = CreateScrollFrame(
        UDim2.new(0.1, 0, 0.05, 0),
        UDim2.new(0.9, 0, 0.95, 0),
        Color3.new(0,0,0), 1)
    Scroller.Parent.Parent = GcViewPanel

    if AllowEdit == true then
        FuncTrack[1] = nil
        FuncTrack[2] = {}  
    end

    local LastFrame = nil
    local scripts = {} --{identifier, {funcs}}
    for i,v in pairs(gc) do
        if typeof(v) == "function" then
            local vFenv = getfenv(v)
            local vScript = rawget(vFenv,"script")
            if typeof(vScript) ~= "Instance" then
                for s,r in pairs(vFenv) do
                    if typeof(r) == "function" then
                        vScript = rawget(debug.getinfo(r),"source")
                        break
                    end
                end
            end

            local isExecuterFunc = false
            if not islclosure(v) then
                vScript = ExecuterName
                isExecuterFunc = true
            elseif (is_synapse_function or isexecutorclosure)(v) then
                vScript = ExecuterName.."_Script"
                isExecuterFunc = true
            end

            local foundTab = {}
            for _,s in pairs(scripts) do
                if rawequal(s[1], vScript) then
                    foundTab = s
                    break
                end
            end
            
            if #foundTab == 0 then
                local newTab = {vScript, { {i,v} }}
                local FItem = CreateTextLabel(
                    UDim2.new(0.2, 0, 0.2, 0),
                    UDim2.new(0.9, 0, 0.25, 0),
                    Color3.new(0,0,0), 0.8,
                    Color3.new(1,1,1) --TextColor
                )
                if typeof(vScript) == "Instance" then
                    FItem.Text = "  "..string.sub(safeString(vScript),1,20)
                    FItem.Text = FItem.Text.." <"..string.sub(safeString(vScript.Parent),1,4000)..">"
                    FItem.Name = "yyy"
                    FItem.TextColor3 = Color3.new(1,1,1)
                    if typeof(vScript.Parent) ~= "Instance" then
                        FItem.Name = "bbb"
                        FItem.TextColor3 = Color3.new(1,0.2,0.2)
                    elseif vScript:IsDescendantOf(ReplicateFirst) then
                        FItem.Name = "ccc"
                        FItem.TextColor3 = Color3.new(1,0.6,0)
                    elseif vScript.Parent and vScript.Parent:IsA("Tool") then
                        FItem.Name = "eee"
                        FItem.TextColor3 = Color3.new(1,0.9,0)
                     elseif vScript.Parent and safeString(vScript.Parent.Name) == safeString(Lplr.Name) then
                        FItem.Name = "ddd"
                        FItem.TextColor3 = Color3.new(0.2,0.8,0.8)
                    elseif vScript:IsDescendantOf(Lplr) then
                        FItem.Name = "fff"
                        FItem.TextColor3 = Color3.new(0.2,0.8,0.2)
                    end

                    if safeString(vScript.Parent) == "ChatMain"
                    or safeString(vScript.Parent) == "CameraModule"
                    or safeString(vScript.Parent) == "ClientChatModules"
                    or safeString(vScript.Parent) == "CommandModules"
                    or safeString(vScript.Parent) == "MessageCreatorModules"
                    or safeString(vScript.Parent) == "ControlModule"
                    or safeString(vScript.Parent) == "PlayerModule"
                    or safeString(vScript.Parent) == "ZoomController"
                    or safeString(vScript.Parent) == "Freecam"
                    or safeString(vScript) == "AtomicBinding"
                    or safeString(vScript) == "ChatScript"
                    or safeString(vScript) == "ChatMain"
                    or safeString(vScript) == "VehicleCameraCore"
                    or safeString(vScript) == "VehicleCamera"
                    or safeString(vScript) == "RbxCharacterSounds"
                    or safeString(vScript) == "PlayerModule"
                    then
                        FItem.Name = "zzz"
                        FItem.TextColor3 = Color3.new(0.6,0.6,0.6)
                    end
                else
                    FItem.Text = "  "..string.sub(safeString(vScript),1,20)
                    FItem.Name = "aaa"
                    FItem.TextColor3 = Color3.new(1,0.2,1)
                    if isExecuterFunc == true then
                        FItem.Name = "zzzz"
                    end
                end
                FItem.TextXAlignment = Enum.TextXAlignment.Left
			    FItem.TextYAlignment = Enum.TextYAlignment.Top
                FItem.InputBegan:Connect(function(obj)
	                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                        if LastFrame then DeleteItem(LastFrame,0) end
                        LastFrame = DisplayGScript(newTab, GcViewPanel)
                    end
                end)
                FItem.Parent = Scroller
                table.insert(scripts, newTab)
            else
                table.insert(foundTab[2], {i,v} )
            end
        end
        if (i%10 == 0) and SlowMode == true then
            task.wait()
        end
    end
end

local GCViewToggle = CreateTextLabel(
	UDim2.new(0.05, 0, 0.35, 0),
	UDim2.new(0.9, 0, 0.25, 0),
	Color3.new(0,0,0), 0.8,
	Color3.new(1,1,1) --TextColor
)
GCViewToggle.Text = "            GC View ×            "
local PreviusGCPanel = GcViewPanel
local GCVIEWTOGGLE = false
GCViewToggle.InputBegan:Connect(function(obj)
	if obj.UserInputType == Enum.UserInputType.MouseButton1 then
        if GCVIEWTOGGLE == false then GCVIEWTOGGLE = true
            if PreviusGCPanel then DeleteItem(PreviusGCPanel,0) end
            local GcViewPanel, GcViewTBar, ExitGCVIEW = CreatePanel(
                PanelTransparency,
                UDim2.new(0, 200, 0, 600),
                MainCanvas.Position + UDim2.new(0, 0, 0, 90)
            )
            PreviusGCPanel = GcViewPanel
            ExitGCVIEW.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    DeleteItem(GcViewPanel, 0)
                end
            end)
            GCViewToggle.Text = "            GC View ↑            "
            local GotGc = getgc()
            DisplayGC(GotGc,GcViewPanel)
            GCViewToggle.Text = "            GC View ×            "
        else
            if PreviusGCPanel then DeleteItem(PreviusGCPanel,0) end
            GCVIEWTOGGLE = false
        end
	end
end)
GCViewToggle.Parent = MainCanvas

local SelectTXT = CreateTextLabel(
	UDim2.new(0.05, 0, 0.65, 0),
	UDim2.new(0.9, 0, 0.25, 0),
	Color3.new(0,0,0), 0.8,
	Color3.new(1,1,1) --TextColor
)
SelectTXT.Text = ""
SelectTXT.Parent = MainCanvas

function typToFunc(typ)
    if typ == 1 then
        return debug.getconstant
    elseif typ == 2 then
        return debug.getupvalue
    elseif typ == 3 then
        return debug.getproto
    end
end

function typToFunc2(typ)
    if typ == 1 then
        return debug.setconstant
    elseif typ == 2 then
        return debug.setupvalue
    elseif typ == 3 then
        return debug.setproto
    end
end

if AllowEdit == true then
    local function GetSelected()
        local cSelected = {} -- {value}
        setmetatable(cSelected, {
            __mode = "kv";
        })
        if #FuncTrack[2] > 1 then
            local IndexId = FuncTrack[2][1][1]
            local Found = typToFunc(FuncTrack[3])(FuncTrack[1], IndexId)
            for _,v in pairs(FuncTrack[2]) do
                if _ > 1 then
                    Found = Found[v[1]]
                end
            end
            cSelected[1] = Found
        elseif #FuncTrack[2] > 0 then
            local IndexId = FuncTrack[2][1][1]
            local Found = typToFunc(FuncTrack[3])(FuncTrack[1], IndexId)
            cSelected[1] = Found
        else
            cSelected[1] = FuncTrack[1]
        end
        if #cSelected > 0 then
            return cSelected
        else
            return nil
        end
    end

    local function SetSelected(newval)
        if #FuncTrack[2] > 1 then
            local IndexId = FuncTrack[2][1][1]
            local Found = typToFunc(FuncTrack[3])(FuncTrack[1], IndexId)
            for _,v in pairs(FuncTrack[2]) do
                if _ > 1 then
                    Found = Found[v[1]]
                end
            end
           
            local newTable = Found
            
            for _,v in pairs(FuncTrack[2]) do
                if _ > 1 then
                    endingVal = endingVal[v[1]]
                end
            end
            local IndexId = FuncTrack[2][1][1]
            typToFunc2(FuncTrack[3])(FuncTrack[1], IndexId, newTable)
        elseif #FuncTrack[2] > 0 then
            local IndexId = FuncTrack[2][1][1]
            typToFunc2(FuncTrack[3])(FuncTrack[1], IndexId, newval)
        else
            --typToFunc2(FuncTrack[3])(FuncTrack[1], IndexId, newval)
        end
    end

    local function ClearScroll(scrl)
        for _,v in pairs(scrl:GetChildren()) do
            if v:IsA("TextLabel") then
                DeleteItem(v, 0)
            end
        end
    end

    local ArgumentsTable = {}
    local topLabel
    local extraLabel
    local Scroller
    local fireButton
    local PrevSelectPanel = nil
    local rSelected
    SelectTXT.InputBegan:Connect(function(obj)
        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
            if PrevSelectPanel then DeleteItem(PrevSelectPanel,0) end
            local SelectPanel, SelectTBar,  SelectExit = CreatePanel(
                PanelTransparency,
                UDim2.new(0, 200, 0, 400),
                MainCanvas.Position + UDim2.new(0, -210, 0, 0)
            )
            PrevSelectPanel = SelectPanel
            SelectExit.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    DeleteItem(SelectPanel, 0)
                end
            end)

            topLabel = CreateTextLabel(
                UDim2.new(0, 0, 0, 21),
                UDim2.new(1, 0, 0, 21),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            topLabel.TextXAlignment = Enum.TextXAlignment.Left
            topLabel.TextYAlignment = Enum.TextYAlignment.Center
            topLabel.TextScaled = true
            topLabel.Text = "  "
            topLabel.Parent = SelectPanel

            copyButton = CreateTextLabel(
                UDim2.new(0, 1, 0, 43),
                UDim2.new(0.5, -1, 0, 24),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            copyButton.TextXAlignment = Enum.TextXAlignment.Center
            copyButton.TextYAlignment = Enum.TextYAlignment.Center
            copyButton.TextScaled = true
            copyButton.Text = "Copy to\n args"
            copyButton.Parent = SelectPanel
            copyButton.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if rSelected then
                        table.insert(ArgumentsTable, rSelected[1])
                    end
                end
            end)

            setButton = CreateTextLabel(
                UDim2.new(0.5, 1, 0, 43),
                UDim2.new(0.5, -1, 0, 24),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            setButton.TextXAlignment = Enum.TextXAlignment.Center
            setButton.TextYAlignment = Enum.TextYAlignment.Center
            setButton.TextScaled = true
            setButton.Text = "Set as\n args[1]"
            setButton.Parent = SelectPanel
            setButton.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if rSelected then
                        if ArgumentsTable[1] then
                            SetSelected(ArgumentsTable[1])
                        else
                            task.spawn(function()
                                setButton.Text = "put smthn on Args[1]"
                                task.wait(1)
                                setButton.Text = "Set as\n args[1]"
                            end)
                        end
                    end
                end
            end)

            fireButton = CreateTextLabel(
                UDim2.new(0, 1, 0, 175),
                UDim2.new(1, -1, 0, 24),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            fireButton.TextXAlignment = Enum.TextXAlignment.Center
            fireButton.TextYAlignment = Enum.TextYAlignment.Center
            fireButton.TextScaled = false
            fireButton.Visible = false
            fireButton.Text = "fire function(args)"
            fireButton.Parent = SelectPanel
            fireButton.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if rSelected then
                        local returnedValue = nil
                        local _,err = pcall(function()
                            returnedValue = rSelected[1](table.unpack(ArgumentsTable))
                        end)
                    end
                end
            end)

            hookButton = CreateTextLabel(
                UDim2.new(0, 1, 0, 150),
                UDim2.new(1, -1, 0, 24),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            hookButton.TextXAlignment = Enum.TextXAlignment.Center
            hookButton.TextYAlignment = Enum.TextYAlignment.Center
            hookButton.TextScaled = false
            hookButton.Visible = false
            hookButton.Text = "clear function"
            hookButton.Parent = SelectPanel
            hookButton.InputBegan:Connect(function(obj)
                if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if rSelected then
                        local  _,err = pcall(function()
                            hookfunction(rSelected[1], function()
                                return wait(99999)
                            end)
                        end)
                        if err then
                            hookButton.Text = err
                        else
                            task.spawn(function()
                                hookButton.Text = "cleared"
                                task.wait(1)
                                hookButton.Text = "clear function"
                            end)
                        end
                    end
                end
            end)
            fireButton.Changed:Connect(function()
                hookButton.Visible = fireButton.Visible
            end)

            argsLabel = CreateTextLabel(
                UDim2.new(0, 0, 1, -200),
                UDim2.new(1, 0, 0, 16),
                Color3.new(0,0,0), 0.8,
                Color3.new(1,1,1) --TextColor
            )
            argsLabel.TextXAlignment = Enum.TextXAlignment.Center
            argsLabel.TextYAlignment = Enum.TextYAlignment.Center
            argsLabel.TextScaled = true
            argsLabel.Text = "  args  "
            argsLabel.Parent = SelectPanel

            local Grid
            Scroller,Grid = CreateScrollFrame(
                UDim2.new(0, 15, 1, -176),
                UDim2.new(1, -15, 0, 176),
                Color3.new(0,0,0), 1)
            Scroller.Parent.Parent = SelectPanel
            Grid.SortOrder = Enum.SortOrder.LayoutOrder
        end
    end)

    local lastargt = #ArgumentsTable
    local buttonConnections = {}
    while task.wait() do
        if ScriptIsDead == false then
            if FuncTrack[1] then
                local _,err = pcall(function()
                    rSelected = GetSelected()
                    if rSelected then
                        if SelectTXT.Text ~= safeString(rSelected[1]) then
                            SelectTXT.Text = safeString(rSelected[1])
                            if topLabel then
                                local theTypeof = typeof(rSelected[1])
                                if theTypeof == "function" then
                                    fireButton.Visible = true
                                else
                                    fireButton.Visible = false
                                end
                                topLabel.Text = "  "..SelectTXT.Text
                            end
                        end
                    else
                        SelectTXT.Text = "value not found"
                    end
                end)
                if err then
                    if string.find(err, "index has to be greater than") or string.find(err, "index is out of bounds") then
                        SelectTXT.Text = "unfound Value ["..safeString(#FuncTrack[2]).."]"
                    else
                        SelectTXT.Text = err
                    end
                    if topLabel then
                        topLabel.Text = "  "..string.sub(SelectTXT.Text,1,40)
                    end
                end
            else
                SelectTXT.Text = ""
            end

            if #ArgumentsTable ~= lastargt and Scroller then
                ClearScroll(Scroller)
                for _,c in pairs(buttonConnections) do
                    c:Disconnect()
                end
                local items = setScroller(ArgumentsTable, Scroller, nil, nil, nil, true)
                for ii,itm in pairs(items) do
                    local vCon; vCon = itm.InputBegan:Connect(function(obj)
                        if obj.UserInputType == Enum.UserInputType.MouseButton1 then
                            table.remove(ArgumentsTable, ii)
                            for _,c in pairs(buttonConnections) do
                                c:Disconnect()
                            end
                            --return
                        end
                    end)
                    table.insert(buttonConnections, vCon)
                end
            end
            lastargt = #ArgumentsTable
        else
            break
        end
    end
else
    SelectTXT.Text = "Edit Disabled"
    SelectTXT.TextScaled = false
    SelectTXT.TextSize = 10
end
