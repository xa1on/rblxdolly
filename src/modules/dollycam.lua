local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local interp = require(script.Parent.interpolation)
local wdg = require(script.Parent.widgets.initalize)

local HistoryService = game:GetService("ChangeHistoryService")

-- playback variables
local previewTime = 0
m.timescale = 1
m.interpMethod = interp[wdg.InterpDefault]

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

function m.reconnectPoints()
    m.checkDir()
    for _, i in pairs(m.mvmDir:GetDescendants()) do
        if i:IsA("BasePart") and not i.Locked then i.Changed:Connect(m.renderPath) end
        if i:IsA("Folder") and i.Name ~= m.renderDirName and i.Name ~= m.pointDirName then
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

function m.point(cf, parent, name, locked)
    local newPoint = Instance.new("Part", parent)
    newPoint.Size = Vector3.new(1,1,1)
    newPoint.Name = name
    newPoint.CFrame = cf
    newPoint.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.FrontSurface = Enum.SurfaceType.Studs
    newPoint.Transparency = 1
    if not locked then
        newPoint.Changed:Connect(m.renderPath)
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
    else
        guipoint.Size = UDim2.new(0.2, 0, 0.2, 0)
        guiframe.BackgroundColor3 = Color3.new(0,1,0)
    end
    guiframe.Size = UDim2.new(1,0,1,0)
    guiframe.BorderSizePixel = 0
    if adornee then guipoint.Adornee = adornee end
    return guipoint
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
    end
    local t = 1
    local betweenCF = m.interpMethod(m.pointDir, t / 3)
    while betweenCF[1] ~= true do
        local newPoint = m.point(betweenCF[2], m.renderDir, t, true)
        m.pointGui(newPoint, t, "inbetween", newPoint)
        t = t + 1
        betweenCF = m.interpMethod(m.pointDir, t / 3)
    end
end

function m.createPoint()
    local Camera = workspace.CurrentCamera
    if not m.notnill(m.pointDir) then m.checkDir() end
    local newPoint = m.point(Camera.CFrame + Camera.CFrame.LookVector, m.pointDir, #(m.pointDir):GetChildren()+1, false)
    local rollValue = Instance.new("NumberValue", newPoint)
        rollValue.Name = "Roll"
        rollValue.Value = setRoll.angle
    local fovValue = Instance.new("NumberValue", newPoint)
        fovValue.Name = "FOV"
        fovValue.Value = Camera.FieldOfView
    HistoryService:SetWaypoint("Created Point")
    m:renderPath()
end

function m.runPath()
    if m.playing then return end
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
    local previewLocation = m.interpMethod(m.pointDir, previewTime * m.timescale)
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