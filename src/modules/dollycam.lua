local RunService = game:GetService("RunService")
local setRoll = require(script.Parent.setRoll)
local lerp = require(script.Parent.lerp)

local m = {}
local defaultSpeed = 10

m.pathfoldername = "mvmpaths"
m.renderfoldername = "mvmrender"
m.pointfoldername = "Points"
local widget = require(script.Parent.widgets.initalize)

m.playing = false
local pbtime = 0
local timescale = 1
local currentdir
local returnCFrame
local returnFOV
m.interpMethod = widget.InterpDefault

local function grabPoints(path)
    local points = {}
    local sort = {}
    for _, i in pairs(path:GetChildren()) do
        if tonumber(i.Name) then
            sort[#sort+1] = tonumber(i.Name)
        end
    end
    table.sort(sort)
    for _, i in pairs(sort) do
        points[#points+1] = path:FindFirstChild(tostring(i))
    end
    return points
end

local function linearInterp(path,t)
    local points = grabPoints(path)
    if #points > 0 then
        local current_t = t * defaultSpeed
        for index, current in pairs(points) do
            local previous = points[index-1]
            if previous then
                local dist = lerp.CFrameDist(current.CFrame, previous.CFrame)
                local progression = current_t/dist
                if progression >= 1 then
                    current_t = current_t - dist
                else
                    return {false,
                    previous.CFrame:Lerp(current.CFrame,progression),
                    lerp.lerp(previous.FOV.Value, current.FOV.Value, progression),
                    lerp.lerp(previous.Roll.Value, current.Roll.Value, progression)}
                end
            end
        end
        local lastPoint = points[#points]
        return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
    end
    return {true,CFrame.new(),60,0}
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

local function createIfNotExist(parent, type, name)
    local newinst
    if not parent:FindFirstChild(name) then
        newinst = Instance.new(type, parent)
        newinst.Name = name
    end
    return parent:FindFirstChild(name)
end

local function checkPathDir()
    local pathsFolder
    local pathFolder
    if not workspace:FindFirstChild(m.pathfoldername) then
        pathsFolder = Instance.new("Folder", workspace)
        pathsFolder.Name = m.pathfoldername
        pathsFolder.ChildAdded:Connect(function()
            m.reloadDropdown()
        end)
    end
    pathsFolder = workspace:FindFirstChild(m.pathfoldername)
    if not pathsFolder:FindFirstChild(widget.pathNameInput:GetValue()) then
        pathFolder = Instance.new("Folder", workspace[m.pathfoldername])
        pathFolder.Name = widget.pathNameInput:GetValue()
        pathFolder.AncestryChanged:Connect(function()
            m.reloadDropdown()
        end)
    end
    pathFolder = pathsFolder:FindFirstChild(widget.pathNameInput:GetValue())
    createIfNotExist(pathFolder, "Folder", m.pointfoldername)
    m.reloadDropdown()
    widget.pathDropdown:SetSelection(widget.pathDropdown:GetID(widget.pathNameInput:GetValue()))
    return pathsFolder[widget["pathNameInput"]:GetValue()]
end

function m.reconnectPoints()
    local pathdir = checkPathDir()
    for _, i in pairs(pathdir[m.pointfoldername]:GetChildren()) do
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
    for _, i in pairs(pathdir[m.pointfoldername]:GetChildren()) do
        pointgui(renderFolder, "point", nil, i)
    end
    local t = 1
    local spot = interpFunctions[m.interpMethod](pathdir[m.pointfoldername], t / 3)
    while spot[1] ~= true do
        local newPoint = point(spot[2], t, renderFolder, false, true)
        pointgui(newPoint, nil, t, newPoint)
        t = t + 1
        spot = interpFunctions[m.interpMethod](pathdir[m.pointfoldername], t / 3)
    end
end

function m.createPoint(roll, fov)
    local Camera = workspace.CurrentCamera
    local pathdir = checkPathDir()
    local newPoint = point(Camera.CFrame + Camera.CFrame.LookVector, #(pathdir[m.pointfoldername]):GetChildren()+1, pathdir[m.pointfoldername], true)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = roll
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = fov
    m:RenderPath()
end

function m.runPath(ts)
    if not m.playing then
        currentdir = checkPathDir()
        currentdir.Parent:FindFirstChild(m.renderfoldername):Destroy()
        m.playing = true
        pbtime = 0
        timescale = ts
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
        local location = interpFunctions[m.interpMethod](currentdir[m.pointfoldername], pbtime * timescale)
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