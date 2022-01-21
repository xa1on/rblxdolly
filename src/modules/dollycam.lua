local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local lerp = require(script.Parent.lerp)
local widget = require(script.Parent.widgets.initalize)

local HistoryService = game:GetService("ChangeHistoryService")

local defaultSpeed = 15
local pbtime = 0
local timescale = 1
local currentdir
local returnCFrame
local returnFOV

m.pathfoldername = "mvmpaths"
m.renderfoldername = "Render"
m.pointfoldername = "Points"

m.interpMethod = widget.InterpDefault
m.playing = false


function m.grabPoints(path)
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

function m.linearInterp(path,t)
    local points = m.grabPoints(path)
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


m.interpFunctions = {
    ["linear"] = m.linearInterp,
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

function m.createIfNotExist(parent, type, name)
    local newinst
    if not parent:FindFirstChild(name) then
        newinst = Instance.new(type, parent)
        newinst.Name = name
    end
    return parent:FindFirstChild(name)
end

function m.checkPathDir()
    local pathsFolder
    local pathFolder
    if not workspace:FindFirstChild(m.pathfoldername) then
        pathsFolder = Instance.new("Folder", workspace)
        pathsFolder.Name = m.pathfoldername
        pathsFolder.ChildAdded:Connect(m.reloadDropdown)
        pathsFolder.ChildRemoved:Connect(m.RenderPath)
    end
    pathsFolder = workspace:FindFirstChild(m.pathfoldername)
    if not pathsFolder:FindFirstChild(widget.pathNameInput:GetValue()) then
        pathFolder = Instance.new("Folder", workspace[m.pathfoldername])
        pathFolder.Name = widget.pathNameInput:GetValue()
        pathFolder.AncestryChanged:Connect(m.reloadDropdown)
    end
    pathFolder = pathsFolder:FindFirstChild(widget.pathNameInput:GetValue())
    m.createIfNotExist(pathFolder, "Folder", m.pointfoldername)
    m.reloadDropdown()
    widget.pathDropdown:SetSelection(widget.pathDropdown:GetID(widget.pathNameInput:GetValue()))
    return pathsFolder[widget["pathNameInput"]:GetValue()]
end

function m.reconnectPoints()
    local pathdir = m.checkPathDir()
    for _, i in pairs(pathdir[m.pointfoldername]:GetChildren()) do
        if i:IsA("BasePart") and not i.Locked then
            i.Changed:Connect(m.RenderPath)
        end
    end
end

function m.resetTimescale()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v:FindFirstChild("originalts") then
            v.TimeScale = v:FindFirstChild("originalts").Value
            v:FindFirstChild("originalts"):Destroy()
        end
    end
end

function m.particleTimescale(ts)
    m.resetTimescale()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            local originalts = Instance.new("NumberValue", v)
            originalts.Name = "originalts"
            originalts.Value = v.TimeScale
            v.TimeScale = v.TimeScale * ts
        end
    end
end

function m.point(cf, name, parent, check, locked)
    local newPoint = Instance.new("Part", parent)
    newPoint.Size = Vector3.new(1,1,1)
    newPoint.Name = name
    newPoint.CFrame = cf
    newPoint.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.FrontSurface = Enum.SurfaceType.Studs
    newPoint.Transparency = 1
    if check then
        newPoint.Changed:Connect(m.RenderPath)
    end
    if locked then
        newPoint.Locked = true
    end
    return newPoint
end

function m.pointgui(parent, type, name, adornee)
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
    local pathdir = m.checkPathDir()
    for _, i in pairs(pathdir.Parent:GetChildren()) do
        if i.Name == m.renderfoldername then
            i.Parent = nil
        end
    end
    local renderFolder = Instance.new("Folder",pathdir.Parent)
    renderFolder.Name = m.renderfoldername
    for _, i in pairs(pathdir[m.pointfoldername]:GetChildren()) do
        m.pointgui(renderFolder, "point", nil, i)
    end
    local t = 1
    local spot = m.interpFunctions[m.interpMethod](pathdir[m.pointfoldername], t / 3)
    while spot[1] ~= true do
        local newPoint = m.point(spot[2], t, renderFolder, false, true)
        m.pointgui(newPoint, nil, t, newPoint)
        t = t + 1
        spot = m.interpFunctions[m.interpMethod](pathdir[m.pointfoldername], t / 3)
    end
end

function m.createPoint(roll, fov)
    local Camera = workspace.CurrentCamera
    local pathdir = m.checkPathDir()
    local newPoint = m.point(Camera.CFrame + Camera.CFrame.LookVector, #(pathdir[m.pointfoldername]):GetChildren()+1, pathdir[m.pointfoldername], true)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = roll
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = fov
    HistoryService:SetWaypoint("Created Point")
    m:RenderPath()
end

function m.runPath(ts)
    if not m.playing then
        currentdir = m.checkPathDir()
        currentdir.Parent:FindFirstChild(m.renderfoldername):Destroy()
        m.playing = true
        pbtime = 0
        timescale = ts
        returnFOV = workspace.CurrentCamera.FieldOfView
        returnCFrame = workspace.CurrentCamera.CFrame
        m.particleTimescale(timescale)
    end
end

function m.stop()
    local Camera = workspace.CurrentCamera
    m.playing = false
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = returnCFrame
    Camera.FieldOfView = returnFOV
    m.resetTimescale()
    m.RenderPath()
end

function m.playback(step)
    if m.playing then
        if setRoll.roll_active then
            setRoll.toggleRollGui()
        end
        local Camera = workspace.CurrentCamera
        local location = m.interpFunctions[m.interpMethod](currentdir[m.pointfoldername], pbtime * timescale)
        if(location[1]) then
            m.stop()
        else
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.FieldOfView = location[3]
            Camera:SetRoll(math.rad(location[4]))
            Camera.CFrame = location[2]
        end
        pbtime = pbtime + step
    end
end

return m