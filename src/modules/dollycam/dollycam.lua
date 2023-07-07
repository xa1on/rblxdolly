local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local interp = require(script.Parent.interpolation)
local tscale = require(script.Parent.timescale)
local util = require(script.Parent.Parent.util)

local repStorage = game:GetService("ReplicatedStorage")

local HistoryService = game:GetService("ChangeHistoryService")

-- playback variables
local previewTime = 0

local returnCFrame
local returnFOV

m.playing = false

-- variables
m.syncMAStl = true
m.matchMASkf = false

m.latesttweentime = nil
m.interpMethod = nil
m.currentPathValue = nil
m.dropdown = nil
m.lockctrlbezier = true

m.mvmDirName = "mvmpaths"
m.renderDirName = "Render"
m.pathsDirName = "Paths"
m.pointDirName = "Points"
m.scriptName = "mvmplayback"

m.mvmDir = nil
m.renderDir = nil
m.pathsDir = nil
m.currentDir = nil
m.pointDir = nil

m.unloadedMvmDir = nil
m.unloadedPathsDir = nil


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




function m.unloadPaths()
    m.ignorechange = true
    if not (util.notnill(m.pathsDir) and util.notnill(m.unloadedPathsDir)) then m.checkDir() end
    for _, i in pairs(m.pathsDir:GetChildren()) do
        i.Parent = m.unloadedPathsDir
    end
    m.ignorechange = false
end

function m.loadPath(path)
    m.ignorechange = true
    if not util.notnill(m.pathsDir) then m.checkDir() end
    path.Parent = m.pathsDir
    m.ignorechange = false
end

function m.grabPoints(path)
    if not path then m.checkDir() path = m.pointDir end
    if not path or not util.notnill(path) then return {} end
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
    if not m.dropdown then return end
    for _,v in pairs(m.dropdown.DropdownScroll.Content:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    if not m.mvmDir then m.checkDir() return end
    for _, inst in pairs(m.pathsDir:GetChildren()) do
        if inst.Name ~= m.renderDirName then
            m.dropdown:AddItem(inst.Name)
        end
    end
    for _, inst in pairs(m.unloadedPathsDir:GetChildren()) do
        if inst.Name ~= m.renderDirName then
            m.dropdown:AddItem(inst.Name)
        end
    end
end

local function tablechange()
    if m.playing or m.ignorechange then return end
    m.renderPath()
    m.reloadDropdown()
end

function m.checkDir(createpath)
    m.unloadedMvmDir = util.createIfNotExist(repStorage, "Folder", m.mvmDirName)
    m.unloadedPathsDir = util.createIfNotExist(m.unloadedMvmDir, "Folder", m.pathsDirName)
    m.mvmDir = util.createIfNotExist(workspace, "Folder", m.mvmDirName)
    m.renderDir = util.createIfNotExist(m.mvmDir, "Folder", m.renderDirName)
    m.pathsDir = util.createIfNotExist(m.mvmDir, "Folder", m.pathsDirName, "ChildAdded", m.reloadDropdown)
    if m.currentPathValue and string.len(m.currentPathValue) > 0 and createpath then
        if not m.pathsDir:FindFirstChild(m.currentPathValue) then
            m.unloadPaths()
            m.currentDir = util.createIfNotExist(m.pathsDir, "Folder", m.currentPathValue, "AncestryChanged", tablechange)
            m.renderPath()
        else
            m.currentDir = m.pathsDir:FindFirstChild(m.currentPathValue)
        end
        m.pointDir = util.createIfNotExist(m.currentDir, "Folder", m.pointDirName, "AncestryChanged", m.renderPath)
        m.reloadDropdown()
        m.dropdown:SetValue(m.currentPathValue)
    elseif #m.pathsDir:GetChildren() > 0 then
        m.reloadDropdown()
        m.currentDir = m.pathsDir:GetChildren()[1]
        m.dropdown:SetValue(m.currentDir.Name)
        m.pointDir = util.createIfNotExist(m.currentDir, "Folder", m.pointDirName, "AncestryChanged", m.renderPath)
        m.reloadDropdown()
        m.dropdown:SetValue(m.currentPathValue)
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
    if property == "CFrame" or property == "Parent" then
        if point.Parent and point.Parent.Name == m.pointDirName then
            m.renderPoint(point)
        elseif point.Parent and point.Parent.Parent and point.Parent.Parent.Name == m.pointDirName then
            if m.lockctrlbezier then
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
    util.appendConnection(m.pathsDir.AncestryChanged:Connect(tablechange))
    for _, i in pairs(m.pathsDir:GetDescendants()) do
        if i:IsA("BasePart") then util.appendConnection(i.Changed:Connect(function(property) pointChange(property, i) end)) end
        if i:IsA("Folder") then
            util.appendConnection(i.AncestryChanged:Connect(tablechange))
        end
    end
    for _, i in pairs(m.unloadedPathsDir:GetDescendants()) do
        if i:IsA("BasePart") then util.appendConnection(i.Changed:Connect(function(property) pointChange(property, i) end)) end
        if i:IsA("Folder") then
            util.appendConnection(i.AncestryChanged:Connect(tablechange))
        end
    end
end



function m.point(cf, parent, name, locked, transparent)
    local newPoint = Instance.new("Part", parent)
    newPoint.Size = Vector3.new(1,1,1)
    newPoint.Name = name
    newPoint.CFrame = util.setCFRoll(cf, 0)
    newPoint.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    newPoint.FrontSurface = Enum.SurfaceType.Studs
    newPoint.Anchored = true
    if not transparent then
        newPoint.Transparency = 1
    else
        newPoint.Transparency = transparent
    end
    if not locked then
        util.appendConnection(newPoint.Changed:Connect(function(property) pointChange(property, newPoint) end))
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
    newPoint.Anchored = true
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
        util.appendConnection(p1.Changed:Connect(function(property) pointChange(property, p1) end))
    end
    local offset2 = offset1:Inverse()
    if previous:FindFirstChild(interp.startctrlName) then
        local relative2 = previouscf:ToObjectSpace(previous:FindFirstChild(interp.startctrlName).CFrame)
        offset2 = CFrame.new(-relative2.X, -relative2.Y, -relative2.Z)
    end
    local p2 = previous:FindFirstChild(interp.endctrlName)
    if not p2 then
        p2 = m.point(previouscf:ToWorldSpace(offset2), previous, interp.endctrlName, false)
        util.appendConnection(p2.Changed:Connect(function(property) pointChange(property, p2) end))
    end
    local checkp2 = previous:FindFirstChild(interp.startctrlName)
    if not checkp2 then
        checkp2 = m.point(previouscf:ToWorldSpace(offset2:Inverse()), previous, interp.startctrlName, false)
        util.appendConnection(checkp2.Changed:Connect(function(property) pointChange(property, checkp2) end))
    end
end


function m.clearCtrl()
    m.ignorechange = true
    if not util.notnill(m.pointDir) then m.checkDir() end
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
    if not util.notnill(m.pointDir) then m.checkDir() end
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
    if not util.notnill(m.pointDir) then m.checkDir() end
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
    if not util.notnill(m.pointDir) then m.checkDir() end
    if m.renderDir then m.renderDir:ClearAllChildren() end
    local points = m.grabPoints()
    for _, point in pairs(points) do
        m.renderPoint(point)
    end
    return
end

function m.createPoint()
    m.checkDir(true)
    if not util.notnill(m.pointDir) then return end
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
    local tweenTime = Instance.new("NumberValue", newPoint)
        tweenTime.Name = "TweenTime"
        tweenTime.Value = m.latesttweentime
    m.createControlPoints(newPoint, points[#points])
    m.renderPoint(newPoint)
    if m.interpMethod == "bezierInterp" and #points > 0 then
        m.renderPoint(points[#points])
    end
end

function m.runPath()
    if m.playing then return end
    --.autoreorder:SetDisabled(true)
    m.checkDir()
    m.renderDir:ClearAllChildren()
    previewTime = 0
    local Camera = workspace.CurrentCamera
    m.returnCFrame = Camera.CFrame
    m.returnFOV = Camera.FieldOfView
    tscale.particleTimescale(tscale.timescale)
    m.playing = true
end

function m.stopPreview()
    --.autoreorder:SetDisabled(false)
    m.playing = false
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = m.returnCFrame
    Camera.FieldOfView = m.returnFOV
    tscale.resetTimescale()
    m.renderPath()
end

function m.saveCam()
    if m.playing then return end
    local Camera = workspace.CurrentCamera
    m.returnCFrame = Camera.CFrame
    m.returnFOV = Camera.FieldOfView
end

function m.recallCam()
    if m.playing then return end
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = m.returnCFrame
    Camera.FieldOfView = m.returnFOV
end

function m.goToTime(currenttime)
    local points = m.grabPoints()
    local previewLocation = interp.pathInterp(points, currenttime, interp[m.interpMethod])
    if previewLocation[1] then return true else
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = previewLocation[3]
        Camera.CFrame = util.setCFRoll(previewLocation[2], math.rad(previewLocation[4]))
    end
end

function m.preview(step)
    if not m.playing then return end
    if setRoll.roll_active then setRoll.toggleRollGui() end
    local scaledTime = previewTime * tscale.timescale
    if m.goToTime(scaledTime) then
        m.stopPreview()
    end
    previewTime = previewTime + step
end

function m.goToProgress(progress)
    if m.playing then return end
    if setRoll.roll_active then setRoll.toggleRollGui() end
    local totalTime = 0
    local points = m.grabPoints()
    for i, v in points do
        if i == #points then break end
        totalTime += v.TweenTime.Value
    end
    local currenttime = progress*totalTime
    m.goToTime(currenttime)
end

function m.createPlaybackScript()
    if workspace:FindFirstChild(m.scriptName) then workspace[m.scriptName]:Destroy() end
    local newScript = Instance.new("ModuleScript", workspace)
    newScript.Name = m.scriptName
    newScript.Source = [[local defaultTiming = 2.5
    local startctrlName = "1"
    local endctrlName = "2"
    local function CFrameDist(cf1, cf2)
        return math.abs((cf1.Position - cf2.Position).Magnitude)
    end
    -- Credit to @Fractality_alt on rblx devforums for the hermite and catmull rom coefficent functions
    -- hermite coefficents
    local function hermiteCoefficents(p0, p1, m0, m1)
        return p0, m0, 3*(p1 - p0) - 2*m0 - m1, 2*(p1 - p0) - m0 - m1
    end
    -- catmull rom coefficents
    local function CRCoefficents(p0, p1, p2, p3, r)
        r = r or 0.5
        return
            2*p1*r,
            (p2 - p0)*r,
            (2*p0 - 5*p1 + 4*p2 - p3)*r,
            (3*(p1 - p2) + (p3 - p0))*r
    end
    local function cubic(t, a, b, c, d)
        return a + t*(b + t*(c + t*d))
    end
    local function lerp(p1, p2, t)
        return p1 + (p2 - p1) * t
    end
    local function cosine(p1, p2, t)
        p2 = p2 or p1
        local f = (1 - math.cos(t * math.pi)) * 0.5
        return p1 * (1 - f) + p2 * f
    end
    local function linearInterp(path, t)
        local p1 = path[1]
        local p2 = path[2] or p1
        return lerp(p1, p2, t)
    end
    local function cosineInterp(path, t)
        local p1 = path[1]
        local p2 = path[2] or p1
        return cosine(p1, p2, t)
    end
    local function catmullRomInterp(path, t)
        local p0 = path[0] or path[1]
        local p1 = path[1]
        local p2 = path[2] or p1
        local p3 = path[3] or p2
        local a,b,c,d = CRCoefficents(p0, p1, p2, p3)
        return cubic(t, a, b, c, d)
    end
    local cubicInterp = catmullRomInterp
    local function fourpCubicInterp(path, t, control)
        if not control then return catmullRomInterp(path, t) end
        local p1 = path[1]
        local p2 = path[2]
        local c1 = control[1][2]
        local c2 = control[2][1]
        local l1 = lerp(p1, c1, t)
        local l2 = lerp(c1, c2, t)
        local l3 = lerp(c2, p2, t)
        local a = lerp(l1, l2, t)
        local b = lerp(l2, l3, t)
        return lerp(a, b, t)
    end
    local bezierInterp = fourpCubicInterp
    local function interpolateCF(path, t, func, control)
        if not func then func = linearInterp end
        local pv = {}
        local lv = {}
        for i, v in pairs(path) do
            pv[i] = v.Position
            lv[i] = v.LookVector
        end
        local cpv = {}
        local clv = {}
        for i, v in pairs(control) do
            cpv[i] = {}
            clv[i] = {}
            if v[1] then
                cpv[i][1] = v[1].Position
                clv[i][1] = v[1].LookVector
            end
            if v[2] then
                cpv[i][2] = v[2].Position
                clv[i][2] = v[2].LookVector
            end
        end
        local newpv = func(pv, t, cpv)
        local newlv = func(lv, t, clv)
        return CFrame.new(newpv, newpv + newlv)
    end
    local function segmentInterp(points, t, func)
        points[0] = points[0] or points[1]
        points[2] = points[2] or points[1]
        points[3] = points[3] or points[2]
        local cframelist = {}
        local fovlist = {}
        local rolllist = {}
        local ctrllist = {}
        for i = 0,3,1 do
            if points[i] then
                cframelist[i] = points[i].CFrame
                fovlist[i] = points[i].FOV.Value
                rolllist[i] = points[i].Roll.Value
                ctrllist[i] = {}
                local startCtrl = points[i]:FindFirstChild(startctrlName)
                if startCtrl then ctrllist[i][1] = startCtrl.CFrame end
                local endCtrl = points[i]:FindFirstChild(endctrlName)
                if endCtrl then ctrllist[i][2] = endCtrl.CFrame end
            end
        end
        local dist = points[2].TweenTime.Value
        local progression = t/dist
        if progression >= 1 then
            return {true, points[2].CFrame, points[2].FOV.Value, points[2].Roll.Value, dist}
        else
            return {false,
                interpolateCF(cframelist, progression, func, ctrllist),
                func(fovlist, progression),
                func(rolllist, progression),
                0}
        end
    end
    local function pathInterp(points, t, func)
        if #points <= 0 then
            return {true, CFrame.new(), 60, 0}
        end
        local current_t = t
        for index, _ in pairs(points) do
            local next = points[index+1]
            if next then
                local pointlist = {}
                for i = -1,2,1 do
                    if points[index+i] then
                        pointlist[i+1] = points[index+i]
                    end
                end
                local segInterp = segmentInterp(pointlist, current_t, func)
                local dist = segInterp[5]
                if segInterp[1] then
                    current_t = current_t - dist
                else
                    return segInterp
                end
            end
        end
        local lastPoint = points[#points]
        return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
    end
    local m = {}
    local points = false
    local renderfolder = false
    if workspace:FindFirstChild("]] .. m.mvmDirName .. [[") then
        if workspace.]] .. m.mvmDirName .. [[:FindFirstChild("]] .. m.pathsDirName .. [[") and #workspace.]] .. m.mvmDirName .. [[.]] .. m.pathsDirName .. [[:GetChildren()>0 and workspace.]] .. m.mvmDirName .. [[.]] .. m.pathsDirName .. [[:GetChildren()[1]:FindFirstChild("]] .. m.pointDirName .. [[") then
            points = workspace.]] .. m.mvmDirName .. [[.]] .. m.pathsDirName .. [[:GetChildren()[1].]] .. m.pointDirName .. [[:GetChildren()
        end
        if workspace.]] .. m.mvmDirName .. [[:FindFirstChild("]] .. m.renderDirName .. [[") then
            renderfolder = workspace.]] .. m.mvmDirName .. [[.]] .. m.renderDirName .. [[
            renderfolder.Parent = game:GetService("ServerStorage")
        end
    end
    local previewTime = 0
    local Camera = workspace.CurrentCamera
    local returnCFrame = Camera.CFrame
    local returnFOV = Camera.FieldOfView
    local timescale = 1
    m.previewing = false
    function m.startPreview(ts)
        timescale = ts
        previewTime = 0
        Camera = workspace.CurrentCamera
        returnCFrame = Camera.CFrame
        returnFOV = Camera.FieldOfView
        --Camera.CameraType = Enum.CameraType.Scriptable
        m.previewing = true
    end
    function m.stopPreview()
        Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CFrame = returnCFrame
        Camera.FieldOfView = returnFOV
        m.previewing = false
        if renderfolder then renderfolder.Parent = workspace.]] .. m.mvmDirName .. [[ end
    end
    game:GetService("RunService").Heartbeat:Connect(function(step)
        if not points or not m.previewing then return end
        local scaledTime = previewTime * timescale
        local previewlocation = pathInterp(points, scaledTime, ]] .. m.interpMethod .. [[)
        if not previewlocation[1] then
            Camera.FieldOfView = previewlocation[3]
            Camera.CFrame = previewLocation[2] * CFrame.Angles(0,0,math.rad(previewLocation[4]))
        else
            m.stopPreview()
        end
        previewTime = previewTime + step
    end)
    return m]]
    local runscript = Instance.new("Script", newScript)
    runscript.Name = "Run"
    runscript.Source = "local playback = require(script.Parent)\n\n-- 5 second delay before cine plays(loads things in)\ntask.wait(5)\nplayback.startPreview(" .. tscale.timescale .. ")"
end



tscale.resetTimescale()
local RunService = game:GetService("RunService")

local moon = _G.MoonGlobal
local MASLS
local previouskf = 0
if moon then MASLS = moon.Windows.MoonAnimator.g_e.LayerSystem end

util.appendConnection(RunService.Heartbeat:Connect(function(step)
    m.preview(step)
    if m.playing or (not moon) or (not MASLS) then return end
    local framenum = moon.time_offset + MASLS.SliderFrame
    if m.syncMAStl then
        if previouskf ~= framenum then
            previouskf = framenum
            local fps = moon.current_fps
            m.goToTime((framenum/fps)*tscale.timescale)
        end
    end
end))

function m.initialize()
    if workspace:FindFirstChild(m.mvmDirName) then
        m.checkDir()
        m.renderPath()
        m.reconnectPoints()
    end
end


return m