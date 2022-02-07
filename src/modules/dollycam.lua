local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local interp = require(script.Parent.interpolation)
local wdg = require(script.Parent.widgets.initalize)

local HistoryService = game:GetService("ChangeHistoryService")

-- playback variables
local previewTime = 0
m.timescale = 1
m.interpMethod = nil

local returnCFrame
local returnFOV

m.playing = false

-- variables
m.mvmDirName = "mvmpaths"
m.renderDirName = "Render"
m.pathsDirName = "Paths"
m.pointDirName = "Points"

m.mvmDir = nil
m.renderDir = nil
m.pathsDir = nil
m.currentDir = nil
m.pointDir = nil

m.allowReorder = true
m.reordering = false

m.controlPointOffset = CFrame.new(10, 0, 0)

function m.notnill(inst)
    if not inst then
        return false
    end
    if inst.Parent then
        if inst.Parent == workspace then
            return true
        else 
            return m.notnill(inst.Parent)
        end
    else
        return false
    end
end

function m.grabPoints(path)
    if not path then path = m.pointDir end
    local points = {}
    local sort = {}
    for _, i in pairs(path:GetChildren()) do
        if tonumber(i.Name) then sort[#sort+1] = tonumber(i.Name) end
    end
    table.sort(sort)
    for _, i in pairs(sort) do points[#points+1] = path:FindFirstChild(tostring(i)) end
    return points
end

function m.reloadDropdown()
    wdg.pathDropdown:RemoveAll()
    if not m.mvmDir then m.checkDir() return end
    for index, inst in pairs(m.pathsDir:GetChildren()) do
        if inst.Name ~= m.renderDirName then
            wdg.pathDropdown:AddSelection({inst.Name, inst, tostring(index)})
        end
    end
end

function m.createIfNotExist(parent, type, name, connection, func)
    local newInst = parent:FindFirstChild(name)
    if not newInst then
        newInst = Instance.new(type, parent)
        newInst.Name = name
        if connection then
            newInst[connection]:Connect(func)
        end
    end
    return newInst
end

function m.checkDir()
    m.mvmDir = m.createIfNotExist(workspace, "Folder", m.mvmDirName)
    m.renderDir = m.createIfNotExist(m.mvmDir, "Folder", m.renderDirName)
    m.pathsDir = m.createIfNotExist(m.mvmDir, "Folder", m.pathsDirName, "ChildAdded", m.reloadDropdown)
    m.currentDir = m.createIfNotExist(m.pathsDir, "Folder", wdg.pathNameInput:GetValue(), "AncestryChanged", function()
        m.renderPath()
        m.reloadDropdown()
    end)
    m.pointDir = m.createIfNotExist(m.currentDir, "Folder", m.pointDirName, "AncestryChanged", m.renderPath)
    m.reloadDropdown()
    wdg.pathDropdown:SetSelection(wdg.pathDropdown:GetID(wdg.pathNameInput:GetValue()))
end

function m.renamePoints()
    local points = m.grabPoints()
    for index, v in pairs(points) do v.Name = index end
    return points
end

function m.insertPoint(point)
    if m.reordering then return end
    m.reordering = true
    point.Parent = nil
    local shift = false
    local points = m.grabPoints()
    for index = 1, #points do
        local i = points[index]
        if tonumber(i.Name) then
            if shift then i.Name = tonumber(i.Name) + 1
            else
                if i.Name == point.Name then
                    shift = true
                    i.Name = tonumber(i.Name) + 1
                end
            end
        end
    end
    point.Parent = m.pointDir
    m.reordering = false
    if m.allowReorder then m.renamePoints() end
end

local function pointChange(property, point)
    if property == "Name" then m.insertPoint(point) end
    m.renderPath()
end

function m.reconnectPoints()
    m.checkDir()
    for _, i in pairs(m.mvmDir:GetDescendants()) do
        if i:IsA("BasePart") and not i.Locked then i.Changed:Connect(function(property) pointChange(property, i) end) end
        if i:IsA("Folder") and i.Name ~= m.renderDirName then
            i.AncestryChanged:Connect(function()
                m.renderPath()
                m.reloadDropdown()
            end)
        end
    end
end

function m.resetTimescale()
    for _, i in pairs(workspace:GetDescendants()) do
        if i:IsA("ParticleEmitter") and i:FindFirstChild("originalTS") then
            i.TimeScale = i:FindFirstChild("originalTS").Value
            i:FindFirstChild("originalTS"):Destroy()
        end
    end
end

function m.particleTimescale(ts)
    m.resetTimescale()
    for _, i in pairs(workspace:GetDescendants()) do
        if i:IsA("ParticleEmitter") then
            local originalts = Instance.new("NumberValue", i)
            originalts.Name = "originalTS"
            originalts.Value = i.TimeScale
            i.TimeScale = i.TimeScale * ts
        end
    end
end

function m.point(cf, parent, name, locked, transparent)
    local newPoint = Instance.new("Part", parent)
    newPoint.Size = Vector3.new(1,1,1)
    newPoint.Name = name
    newPoint.CFrame = cf
    newPoint.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.FrontSurface = Enum.SurfaceType.Studs
    if not transparent then
        newPoint.Transparency = 1
    else
        newPoint.Transparency = transparent
    end
    if not locked then
        newPoint.Changed:Connect(function(property) pointChange(property, newPoint) end)
    else newPoint.Locked = true end
    return newPoint
end

function m.pointGui(parent, name, type, adornee)
    local guipoint = Instance.new("BillboardGui", parent)
    local guiframe = Instance.new("Frame", guipoint)
    if name then guipoint.Name = name
    else guipoint.Name = "Point" end
    guipoint.AlwaysOnTop = false
    if(type == "point") then
        guipoint.Size = UDim2.new(0.6, 0, 0.6, 0)
        guiframe.BackgroundColor3 = Color3.new(1,0,0)
    elseif type == "ctrl" then
        guipoint.Size = UDim2.new(0.3, 0, 0.3, 0)
        guiframe.BackgroundColor3 = Color3.new(0,0,1)
    elseif type == "ctrlpath" then
        guipoint.Size = UDim2.new(0.2, 0, 0.2, 0)
        guiframe.BackgroundColor3 = Color3.new(0,0.5,1)
    elseif type == "path" then
        guipoint.Size = UDim2.new(0.2, 0, 0.2, 0)
        guiframe.BackgroundColor3 = Color3.new(1,0.5,0)
    else
        guipoint.Size = UDim2.new(0.2, 0, 0.2, 0)
        guiframe.BackgroundColor3 = Color3.new(1,0.5,0)
    end
    guiframe.Size = UDim2.new(1,0,1,0)
    guiframe.BorderSizePixel = 0
    if adornee then guipoint.Adornee = adornee end
    return guipoint
end

function m.createLine(p1, p2, type, num)
    if not num then num = 5 end
    for i = 1, num do
        local newPoint = m.point(CFrame.new(interp.linearInterp({p1.CFrame.Position, p2.CFrame.Position}, i * 1/num)), m.renderDir, p1.Name, true)
        m.pointGui(newPoint, p1.Name, type, newPoint)
    end
end

function m.createControlPoints(point, previous)
    if not previous then return end
    local pointcf = point.CFrame
    local previouscf = previous.CFrame
    local relativeX1 = (pointcf:ToObjectSpace(previouscf).X)
    local offset1
    if relativeX1 >= 0 then offset1 = m.controlPointOffset
    else offset1 = m.controlPointOffset:Inverse() end
    local p1 = point:FindFirstChild("1")
    if not p1 then
        p1 = m.point(pointcf:ToWorldSpace(offset1), point, 1)
        p1.Changed:Connect(function(property) pointChange(property, p1) end)
    end
    local offset2
    if previous:FindFirstChild("1") then
        local relativeX2 = previouscf:ToObjectSpace(previous:FindFirstChild("1").CFrame).X
        if relativeX2 >= 0 then offset2 = m.controlPointOffset:Inverse()
        else offset2 = m.controlPointOffset end
    else
        offset2 = offset1:Inverse()
    end
    local p2 = previous:FindFirstChild("2")
    if not p2 then
        p2 = m.point(previouscf:ToWorldSpace(offset2), previous, 2)
        p2.Changed:Connect(function(property) pointChange(property, p2) end)
    end
end

function m.normalizeCtrl()
    if not m.notnill(m.pointDir) then m.checkDir() end
    local points = m.grabPoints()
    for _, i in pairs(points) do
        
    end
end

function m.renderPath()
    if m.playing then return end
    if not m.mvmDir then m.checkDir() return end
    if m.renderDir then m.renderDir:ClearAllChildren() end
    if not m.notnill(m.pointDir) then return end
    for _, i in pairs(m.pointDir:GetChildren()) do
        local newPoint = i:Clone()
        newPoint:ClearAllChildren()
        newPoint.Name = "Point " .. i.Name
        newPoint.Parent = m.renderDir
        m.pointGui(newPoint, nil, "point", newPoint)
        if m.interpMethod == "bezierInterp" then
            if i:FindFirstChild("1") or i:FindFirstChild("2") then
                for _, v in pairs(i:GetChildren()) do
                    if v:IsA("BasePart") then
                        local newCtrl = v:Clone()
                        newCtrl.Name = i.Name.."_"..v.Name
                        newCtrl.Parent = m.renderDir
                        m.pointGui(newCtrl, nil, "ctrl", newCtrl)
                        m.createLine(newCtrl, newPoint, "ctrlpath")
                    end
                end
            end
        end
    end
    local t = 1
    local betweenCF = interp.pathInterp(m.grabPoints(), t / 5, interp[m.interpMethod])
    while betweenCF[1] ~= true do
        local newPoint = m.point(betweenCF[2], m.renderDir, t, true)
        m.pointGui(newPoint, t, "path", newPoint)
        t = t + 1
        betweenCF = interp.pathInterp(m.grabPoints(), t / 5, interp[m.interpMethod])
    end
end

function m.createPoint()
    local Camera = workspace.CurrentCamera
    m.checkDir()
    local points = m.grabPoints()
    local name = nil
    if #points > 0 then name = points[#points].Name+1 else name = 1 end
    local newPoint = m.point(Camera.CFrame + Camera.CFrame.LookVector, m.pointDir, name, false)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = setRoll.angle
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = Camera.FieldOfView
    m.createControlPoints(newPoint, points[#points])
    HistoryService:SetWaypoint("Created Point")
    m:renderPath()
end

function m.runPath()
    if m.playing then return end
    wdg.autoreorder:SetDisabled(true)
    m.checkDir()
    m.renderDir:ClearAllChildren()
    previewTime = 0
    local Camera = workspace.CurrentCamera
    m.returnCFrame = Camera.CFrame
    m.returnFOV = Camera.FieldOfView
    m.particleTimescale(m.timescale)
    m.playing = true
end

function m.stopPreview()
    wdg.autoreorder:SetDisabled(false)
    m.playing = false
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = m.returnCFrame
    Camera.FieldOfView = m.returnFOV
    m.resetTimescale()
    m.renderPath()
end

function m.preview(step)
    if not m.playing then return end
    if setRoll.roll_active then setRoll.toggleRollGui() end
    local previewLocation = interp.pathInterp(m.grabPoints(), previewTime * m.timescale, interp[m.interpMethod])
    if previewLocation[1] then m.stopPreview() else
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = previewLocation[3]
        Camera:SetRoll(math.rad(previewLocation[4]))
        Camera.CFrame = previewLocation[2]
    end
    previewTime = previewTime + step
end

return m