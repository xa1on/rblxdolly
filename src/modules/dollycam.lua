local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local interp = require(script.Parent.interpolation)
local wdg = require(script.Parent.widgets.initalize)
local util = require(script.Parent.util)
local repStorage = game:GetService("ReplicatedStorage")

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

m.unloadedMvmDir = nil
m.unloadedPathsDir = nil

m.connections = {}

m.allowReorder = true

m.ignorechange = false

m.pointProperties = {
    ["point"] = {
        size = UDim2.new(0.6, 0, 0.6, 0),
        color = Color3.new(1,0,0),
        dirsize = Vector3.new(0.04, 0.04, 0.5),
        dircolor = Color3.new(0.66, 0, 0)
    },
    ["ctrl"] = {
        size = UDim2.new(0.3, 0, 0.3, 0),
        color = Color3.new(0,0,1),
        dircolor = Color3.new(0, 0, 0.66),
        dirsize = Vector3.new(0.03, 0.03, 0.5)
    },
    ["ctrlpath"] = {
        size = UDim2.new(0.2, 0, 0.2, 0),
        color = Color3.new(0,0.5,1)
    },
    ["path"] = {
        size = UDim2.new(0.2, 0, 0.2, 0),
        color = Color3.new(1,0.5,0),
        dircolor = Color3.new(1, 0.32, 0),
        dirsize = Vector3.new(0.02, 0.02, 0.5)
    }
}

function m.clearConnections()
    for _, v in pairs(m.connections) do
        v:Disconnect()
    end
    print("CONNECTIONS CLEARED - rblxmvm")
end

function m.notnill(inst)
    if not inst then
        return false
    end
    if inst.Parent then
        if inst.Parent == workspace or inst.Parent == repStorage then
            return true
        else 
            return m.notnill(inst.Parent)
        end
    else
        return false
    end
end

function m.unloadPaths()
    m.ignorechange = true
    if not (m.notnill(m.pathsDir) and m.notnill(m.unloadedPathsDir)) then m.checkDir() end
    for _, i in pairs(m.pathsDir:GetChildren()) do
        i.Parent = m.unloadedPathsDir
    end
    m.ignorechange = false
end

function m.loadPath(path)
    m.ignorechange = true
    if not m.notnill(m.pathsDir) then m.checkDir() end
    path.Parent = m.pathsDir
    m.ignorechange = false
end

function m.grabPoints(path)
    if not path then m.checkDir() path = m.pointDir end
    if not path or not m.notnill(path) then return {} end
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
    for index, inst in pairs(m.unloadedPathsDir:GetChildren()) do
        if inst.Name ~= m.renderDirName then
            wdg.pathDropdown:AddSelection({inst.Name, inst, tostring(index + #m.pathsDir:GetChildren())})
        end
    end
end

function m.createIfNotExist(parent, type, name, connection, func)
    local newInst = parent:FindFirstChild(name)
    if not newInst then
        newInst = Instance.new(type, parent)
        newInst.Name = name
        if connection then
            m.connections[#m.connections+1] = newInst[connection]:Connect(func)
        end
    end
    return newInst
end

local function tablechange()
    if m.playing or m.ignorechange then return end
    m.renderPath()
    m.reloadDropdown()
end

function m.checkDir(createpath)
    m.unloadedMvmDir = m.createIfNotExist(repStorage, "Folder", m.mvmDirName)
    m.unloadedPathsDir = m.createIfNotExist(m.unloadedMvmDir, "Folder", m.pathsDirName)
    m.mvmDir = m.createIfNotExist(workspace, "Folder", m.mvmDirName)
    m.renderDir = m.createIfNotExist(m.mvmDir, "Folder", m.renderDirName)
    m.pathsDir = m.createIfNotExist(m.mvmDir, "Folder", m.pathsDirName, "ChildAdded", m.reloadDropdown)
    if #wdg.pathNameInput:GetValue() > 0 and createpath then
        if not m.pathsDir:FindFirstChild(wdg.pathNameInput:GetValue()) then
            m.unloadPaths()
            m.currentDir = m.createIfNotExist(m.pathsDir, "Folder", wdg.pathNameInput:GetValue(), "AncestryChanged", tablechange)
        else
            m.currentDir = m.pathsDir:FindFirstChild(wdg.pathNameInput:GetValue())
        end
        m.pointDir = m.createIfNotExist(m.currentDir, "Folder", m.pointDirName, "AncestryChanged", m.renderPath)
        m.reloadDropdown()
        wdg.pathDropdown:SetSelection(wdg.pathDropdown:GetID(wdg.pathNameInput:GetValue()))
    elseif #m.pathsDir:GetChildren() > 0 then
        m.reloadDropdown()
        m.currentDir = m.pathsDir:GetChildren()[1]
        wdg.pathDropdown:SetSelection(wdg.pathDropdown:GetID(m.currentDir.Name))
        wdg.pathNameInput:SetValue(m.currentDir.Name)
        m.pointDir = m.createIfNotExist(m.currentDir, "Folder", m.pointDirName, "AncestryChanged", m.renderPath)
        m.reloadDropdown()
        wdg.pathDropdown:SetSelection(wdg.pathDropdown:GetID(wdg.pathNameInput:GetValue()))
    end
end

function m.renamePoints()
    local points = m.grabPoints()
    for index, v in pairs(points) do v.Name = index end
    return points
end

-- depreciated
function m.insertPoint(point)
    if m.ignorechange then return end
    print("asdf")
    m.ignorechange = true
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
    m.ignorechange = false
    if m.allowReorder then m.renamePoints() end
end

local function pointChange(property, point)
    if m.playing or m.ignorechange then return end
    m.ignorechange = true
    if point.Name == "1" then
        print(property)
    end
    if property == "Position" or property == "Orientation" or property == "Rotation" or property == "Parent" then
        if point.Parent and point.Parent.Name == m.pointDirName then
            m.renderPoint(point)
        elseif point.Parent and point.Parent.Parent and point.Parent.Parent.Name == m.pointDirName then
            if wdg.lockctrlbezier:GetValue() then
                m.alignCtrl(point)
            end
            m.ignorechange = false
            m.renderPoint(point.Parent)
            return
        else
            m.ignorechange = false
            m.renderPath()
            return
        end
    end
    m.ignorechange = false
    if property == "Name" then m.renderPath() end
end

function m.alignCtrl(ctrl)
    local point = ctrl.Parent
    local mainctrl = ctrl
    local secondaryctrl
    if ctrl.Name == interp.startctrlName then
        secondaryctrl = ctrl.Parent:FindFirstChild(interp.endctrlName)
    else
        secondaryctrl = ctrl.Parent:FindFirstChild(interp.startctrlName)
    end
    if not secondaryctrl then m.ignorechange = false return end
    local offset = mainctrl.Position - point.Position
    secondaryctrl.Position = point.Position - offset
    local EApoint = Vector3.new(point.CFrame:toEulerAnglesYXZ())
    local EAmain = Vector3.new(mainctrl.CFrame:toEulerAnglesYXZ())
    local newEA = 2*EApoint-EAmain
    secondaryctrl.CFrame = CFrame.new(secondaryctrl.Position, secondaryctrl.Position + CFrame.fromEulerAnglesYXZ(newEA.X, newEA.Y, newEA.Z).LookVector)
end

function m.reconnectPoints()
    m.checkDir()
    m.connections[#m.connections+1] = m.pathsDir.AncestryChanged:Connect(tablechange)
    for _, i in pairs(m.pathsDir:GetDescendants()) do
        if i:IsA("BasePart") then m.connections[#m.connections+1] = i.Changed:Connect(function(property) pointChange(property, i) end) end
        if i:IsA("Folder") then
            m.connections[#m.connections+1] = i.AncestryChanged:Connect(tablechange)
        end
    end
    for _, i in pairs(m.unloadedPathsDir:GetDescendants()) do
        if i:IsA("BasePart") then m.connections[#m.connections+1] = i.Changed:Connect(function(property) pointChange(property, i) end) end
        if i:IsA("Folder") then
            m.connections[#m.connections+1] = i.AncestryChanged:Connect(tablechange)
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
        m.connections[#m.connections+1] = newPoint.Changed:Connect(function(property) pointChange(property, newPoint) end)
    else newPoint.Locked = true end
    return newPoint
end

function m.pointGui(parent, name, type, adornee)
    local guipoint = Instance.new("BillboardGui", parent)
    local guiframe = Instance.new("Frame", guipoint)
    if name then guipoint.Name = name
    else guipoint.Name = "Point" end
    guipoint.AlwaysOnTop = false
    guipoint.Size = m.pointProperties[type].size
    guiframe.BackgroundColor3 = m.pointProperties[type].color
    guiframe.Size = UDim2.new(1,0,1,0)
    guiframe.BorderSizePixel = 0
    if adornee then guipoint.Adornee = adornee end
    return guipoint
end

function m.createDirection(cf, parent, name, type)
    local newPoint = Instance.new("Part", parent)
    newPoint.Name = name
    newPoint.CFrame = cf:ToWorldSpace(CFrame.new(0,0,-0.25))
    newPoint.Color = m.pointProperties[type].dircolor
    newPoint.Size = m.pointProperties[type].dirsize
    newPoint.Locked = true
    newPoint.Material = Enum.Material.Neon
end

function m.createLine(p1, p2, type, parent, num)
    if not num then num = 5 end
    for i = 1, num - 1 do
        local newPoint = m.point(CFrame.new(interp.linearInterp({p1.CFrame.Position, p2.CFrame.Position}, i * 1/num)), parent, p1.Name, true)
        newPoint.Size = Vector3.new(0.05,0.05,0.05)
        m.pointGui(newPoint, p1.Name, type, newPoint)
    end
end

function m.createControlPoints(point, previous)
    if not previous then return end
    local pointcf = point.CFrame
    local previouscf = previous.CFrame
    local relative1 = pointcf:ToObjectSpace(previouscf)
    local offset1 = CFrame.new(relative1.X/2, relative1.Y/2, relative1.Z/2)
    local p1 = point:FindFirstChild(interp.startctrlName)
    if not p1 then
        p1 = m.point(pointcf:ToWorldSpace(offset1), point, interp.startctrlName, false)
        m.connections[#m.connections+1] = p1.Changed:Connect(function(property) pointChange(property, p1) end)
    end
    local offset2 = offset1:Inverse()
    if previous:FindFirstChild(interp.startctrlName) then
        local relative2 = previouscf:ToObjectSpace(previous:FindFirstChild(interp.startctrlName).CFrame)
        offset2 = CFrame.new(-relative2.X, -relative2.Y, -relative2.Z)
    end
    local p2 = previous:FindFirstChild(interp.endctrlName)
    if not p2 then
        p2 = m.point(previouscf:ToWorldSpace(offset2), previous, interp.endctrlName, false)
        m.connections[#m.connections+1] = p2.Changed:Connect(function(property) pointChange(property, p2) end)
    end
    local checkp2 = previous:FindFirstChild(interp.startctrlName)
    if not checkp2 then
        checkp2 = m.point(previouscf:ToWorldSpace(offset2:Inverse()), previous, interp.startctrlName, false)
        m.connections[#m.connections+1] = checkp2.Changed:Connect(function(property) pointChange(property, checkp2) end)
    end
end


function m.clearCtrl()
    m.ignorechange = true
    if not m.notnill(m.pointDir) then m.checkDir() end
    local points = m.grabPoints()
    for _, i in pairs(points) do
        local c1 = i:FindFirstChild(interp.startctrlName)
        local c2 = i:FindFirstChild(interp.endctrlName)
        if c1 then c1:Destroy() end
        if c2 then c2:Destroy() end
    end
    m.ignorechange = false
    m.renderPath()
end

function m.renderSegment(target, parent)
    if not m.notnill(m.pointDir) then m.checkDir() end
    local points = m.grabPoints()
    local parent = parent or m.renderDir:FindFirstChild(target.Name)
    local index
    for ind, point in pairs(points)do
        if point.Name == target.Name then
            index = ind
            break
        end
    end
    if points[index + 1] then
        if parent then
            for _, i in pairs(parent:GetChildren()) do
                if tonumber(i.Name) then
                    i:Destroy()
                end
            end
        end
        local renderPoints = {}
        for i = -1,2,1 do
            if points[index+i] then
                renderPoints[i+1] = points[index+i]
            end
        end
        local t = 1
        local betweenCF = interp.segmentInterp(renderPoints, t / 5, interp[m.interpMethod])
        while betweenCF[1] ~= true do
            local newBTP = m.point(betweenCF[2], parent, t, true)
            newBTP.Size = Vector3.new(0.05,0.05,0.05)
            m.pointGui(newBTP, t, "path", newBTP)
            m.createDirection(betweenCF[2], newBTP, t, "path")
            t = t + 1
            betweenCF = interp.segmentInterp(renderPoints, t / 5, interp[m.interpMethod])
        end
    end
end

function m.renderPoint(point)
    if not m.notnill(m.pointDir) then m.checkDir() end
    local points = m.grabPoints()
    local index
    local parent = parent or m.renderDir:FindFirstChild(point.Name)
    if parent then parent:Destroy() end
    for ind, inst in pairs(points) do
        if inst.Name == point.Name then
            index = ind
            break
        end
    end
    local newPoint = point:Clone()
    newPoint:ClearAllChildren()
    newPoint.Parent = m.renderDir
    m.createDirection(newPoint.CFrame, newPoint, "point", "point")
    m.pointGui(newPoint, nil, "point", newPoint)
    if m.interpMethod == "bezierInterp" then
        if not (point:FindFirstChild(interp.endctrlName) and point:FindFirstChild(interp.startctrlName)) then
            m.createControlPoints(point, points[index-1])
            if points[index + 1] then
                m.createControlPoints(points[index + 1], point)
            end
        end
        for _, ctrl in pairs(point:GetChildren()) do
            if ctrl:IsA("BasePart") then
                local newCtrl = ctrl:Clone()
                newCtrl.Name = point.Name.."_"..ctrl.Name
                newCtrl.Parent = newPoint
                newCtrl.Size = Vector3.new(0.05,0.05,0.05)
                m.createDirection(newCtrl.CFrame, newCtrl, newCtrl.Name, "ctrl")
                m.pointGui(newCtrl, nil, "ctrl", newCtrl)
                m.createLine(newCtrl, newPoint, "ctrlpath", newPoint)
            end
        end
    end
    local segmentRange = {-1, 0}
    if m.interpMethod == "cubicInterp" then
        segmentRange = {-2, 1}
    end
    for i = index + segmentRange[1], index + segmentRange[2] do
        if points[i] then
            m.renderSegment(points[i], m.renderDir:FindFirstChild(points[i].Name))
        end
    end
    return newPoint
end

function m.renderPath()
    if m.playing or m.ignorechange then return end
    if not m.notnill(m.pointDir) then m.checkDir() end
    if m.renderDir then m.renderDir:ClearAllChildren() end
    local points = m.grabPoints()
    for _, point in pairs(points) do
        m.renderPoint(point)
    end
    return
end

function m.createPoint()
    m.checkDir(true)
    if not m.notnill(m.pointDir) then return end
    local Camera = workspace.CurrentCamera
    local points = m.grabPoints()
    local name = nil
    if #points > 0 then name = points[#points].Name+1 else name = 1 end
    local newPoint = m.point(Camera.CFrame, m.pointDir, name, false)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = setRoll.angle
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = Camera.FieldOfView
    m.createControlPoints(newPoint, points[#points])
    m.renderPoint(newPoint)
    if m.interpMethod == "bezierInterp" and #points > 0 then
        m.renderPoint(points[#points])
    end
end

function m.runPath()
    if m.playing then return end
    --wdg.autoreorder:SetDisabled(true)
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
    --wdg.autoreorder:SetDisabled(false)
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


m.resetTimescale()
m.interpMethod = wdg.interpDropdown:GetChoice()
local RunService = game:GetService("RunService")

m.connections[#m.connections+1] = RunService.Heartbeat:Connect(m.preview)
m.connections[#m.connections+1] = wdg["pathDropdown"]:GetButton().MouseButton1Click:Connect(m.reloadDropdown)

if workspace:FindFirstChild(m.mvmDirName) then
    m.checkDir()
    m.renderPath()
    m.reconnectPoints()
end


return m