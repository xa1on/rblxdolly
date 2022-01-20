local RunService = game:GetService("RunService")
local setRoll = require(script.Parent.setRoll)

local m = {}
local defaultSpeed = 10

m.pathfoldername = "mvmpaths"
m.renderfoldername = "mvmrender"
local widget = require(script.Parent.widgets.initalize)

m.playing = false
local pbtime = 0
local timescale = 1
local currentdir
local returnCFrame
local returnFOV
m.interpMethod = "linear"


function m.CFrameDist(cf1, cf2)
    return math.abs((cf1.Position - cf2.Position).Magnitude)
end

function m.lerp(start, goal, alpha)
    return start + (goal - start) * alpha
end

function m.quadLerp(p1, p2, p0, t)
    local l1 = p1:Lerp(p0, t)
    local l2 = p0:Lerp(p2, t)
    return l1:Lerp(l2, t)
end

function m.cubicLerp(p1, p2, ps1, ps2, t)
    local l1 = p1:Lerp(ps1, t)
    local l2 = ps1:Lerp(ps2, t)
    local l3 = ps2:Lerp(p2, t)
    local r1 = l1:Lerp(l2, t)
    local r2 = l2:Lerp(l3, t)
    return r1:Lerp(r2, t)
end

local function linearInterp(path,t)
    local current_t = t * defaultSpeed
    if #path:GetChildren() > 0 then
        local lastpointind = 0
        local previous
        for i = 1, #path:GetChildren(), 1 do
            if path:FindFirstChild(tostring(i)) then
                if previous then
                    local current = path[tostring(i)]
                    lastpointind = i
                    local dist = m.CFrameDist(current.CFrame, previous.CFrame)
                    local progression = current_t/dist
                    if progression >= 1 then
                        current_t = current_t - dist
                    else
                        return {false,
                        previous.CFrame:Lerp(current.CFrame,progression),
                        m.lerp(previous.FOV.Value, current.FOV.Value, progression),
                        m.lerp(previous.Roll.Value, current.Roll.Value, progression)}
                    end
                end
                previous = path:FindFirstChild(tostring(i))
            end
        end
        if path:FindFirstChild(tostring(lastpointind)) then
            local lastpoint = path[tostring(lastpointind)]
            return {true, lastpoint.CFrame, lastpoint.FOV.Value, lastpoint.Roll.Value}
        end
    end
    return {true,CFrame.new(),60,0}
end

local function bezierLength(path,type,acc)
    local lengths = {}
    for i = 2, #path, 1 do
        local len = 0
        local l = 0
        local previous = 0
        while l ~= 1 do
            local currentCFrame = type()
            l=l+acc
        end
        lengths[i-1] = len
    end
    return lengths
end

local interpFunctions = {
    ["linear"] = linearInterp,
}

function m.reloadDropdown()
    widget.pathDropdown:RemoveAll()
    if workspace:FindFirstChild(m.pathfoldername) then
        for index, inst in pairs(workspace[m.pathfoldername]:GetChildren()) do
            if inst.Name ~= m.renderfoldername then
                widget.pathDropdown:AddSelection({inst.Name, inst, tostring(index)})
            end
        end
    end
end

widget.pathDropdown:GetButton().MouseButton1Click:Connect(function()
    m.reloadDropdown()
end)

local function checkPathDir()
    if not workspace:FindFirstChild(m.pathfoldername) then
        local i = Instance.new("Folder", workspace)
        i.Name = m.pathfoldername
        i.ChildAdded:Connect(function()
            m.reloadDropdown()
        end)
    end
    if not workspace[m.pathfoldername]:FindFirstChild(widget.pathNameInput:GetValue()) then
        local i = Instance.new("Folder", workspace[m.pathfoldername])
        i.Name = widget.pathNameInput:GetValue()
        i.AncestryChanged:Connect(function()
            m.reloadDropdown()
        end)
    end
    m.reloadDropdown()
    widget.pathDropdown:SoftSelection(widget.pathNameInput:GetValue())
    return workspace[m.pathfoldername][widget["pathNameInput"]:GetValue()]
end

function m.reconnectPoints()
    local pathdir = checkPathDir()
    for _, i in pairs(checkPathDir():GetChildren()) do
        if i:IsA("BasePart") and not i.Locked then
            i.Changed:Connect(function()
                m.RenderPath()
            end)
            i.AncestryChanged:Connect(function()
                m.RenderPath()
            end)
        end
    end
end

local function point(cf, name, parent, check, locked)
    local newPoint = Instance.new("Part", parent)
    newPoint.Size = Vector3.new(1,1,1)
    newPoint.Name = name
    newPoint.CFrame = cf
    newPoint.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.FrontSurface = Enum.SurfaceType.Studs
    newPoint.Transparency = 1
    if check then
        newPoint.Changed:Connect(function()
            m.RenderPath()
        end)
        newPoint.AncestryChanged:Connect(function()
            m.RenderPath()
        end)
    end
    if locked then
        newPoint.Locked = true
    end
    return newPoint
end

local function pointgui(parent, type, name, adornee)
    local vispoint = Instance.new("BillboardGui", parent)
    local visframe = Instance.new("Frame", vispoint)
    if name then 
        vispoint.Name = name
    else
        vispoint.Name = "Point"
    end
    vispoint.AlwaysOnTop = true
    if(type == "point") then
        vispoint.Size = UDim2.new(0.6, 0, 0.6, 0)
        visframe.BackgroundColor3 = Color3.new(1,0,0)
    else
        vispoint.Size = UDim2.new(0.2, 0, 0.2, 0)
        visframe.BackgroundColor3 = Color3.new(0,1,0)
    end
    visframe.Size = UDim2.new(1,0,1,0)
    visframe.BorderSizePixel = 0
    if adornee then
        vispoint.Adornee = adornee
    end
    return vispoint
end

function m.RenderPath()
    if m.playing then
        return
    end
    local pathdir = checkPathDir()
    for _, i in pairs(pathdir.Parent:GetChildren()) do
        if i.Name == m.renderfoldername then
            i.Parent = nil
        end
    end
    local renderFolder = Instance.new("Folder",pathdir.Parent)
    renderFolder.Name = m.renderfoldername
    for _, i in pairs(pathdir:GetChildren()) do
        pointgui(renderFolder, "point", nil, i)
    end
    local t = 1
    local spot = interpFunctions[m.interpMethod](pathdir, t / 3)
    while spot[1] ~= true do
        local newPoint = point(spot[2], t, renderFolder, false, true)
        pointgui(newPoint, nil, t, newPoint)
        t = t + 1
        spot = interpFunctions[m.interpMethod](pathdir, t / 3)
    end
end

function m.createPoint(roll, fov)
    local Camera = workspace.CurrentCamera
    local pathdir = checkPathDir()
    local newPoint = point(Camera.CFrame + Camera.CFrame.LookVector, #pathdir:GetChildren()+1, pathdir, true)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = roll
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = fov
    m:RenderPath()
end

function m.runPath(interp,ts)
    if not m.playing then
        currentdir = checkPathDir()
        currentdir.Parent:FindFirstChild(m.renderfoldername):Destroy()
        m.playing = true
        pbtime = 0
        timescale = ts
        m.interpMethod = interp
        returnFOV = workspace.CurrentCamera.FieldOfView
        returnCFrame = workspace.CurrentCamera.CFrame
    end
end


function playback(step)
    if m.playing then
        if setRoll.roll_active then
            setRoll.toggleRollGui()
        end
        local Camera = workspace.CurrentCamera
        local location = interpFunctions[m.interpMethod](currentdir, pbtime * timescale)
        if(location[1]) then
            m.playing = false
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CFrame = returnCFrame
            Camera.FieldOfView = returnFOV
            m.RenderPath()
        else
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.FieldOfView = location[3]
            Camera:SetRoll(math.rad(location[4]))
            Camera.CFrame = location[2]
        end
        pbtime = pbtime + step
    end
end
RunService.Heartbeat:Connect(playback)

return m