local startctrlName = "1"
local endctrlName = "2"
local interpMethod = "bezierInterp"
local delay = 0
local tension = 0.5
local alpha = 0.5

local k = {}
local function CFrameDist(cf1, cf2)
    return math.abs((cf1.Position - cf2.Position).Magnitude)
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
k.linearInterp = linearInterp
local function cosineInterp(path, t)
    local p1 = path[1]
    local p2 = path[2] or p1
    return cosine(p1, p2, t)
end
local function cubic(t, a, b, c, d)
    return a + t*(b + t*(c + t*d))
end
k.cosineInterp = cosineInterp
function catmullRomInterp(path, t, _)
    local p0 = path[0] or path[1]
    local p1 = path[1]
    local p2 = path[2] or p1
	local p3 = path[3] or p2
	print(alpha)
	print(tension)
    local function tj(pi, pf)
        if pi == pf then return 1 end
        if type(pi) == "number" then
            return math.abs(pi-pf)
        elseif type(pi) == "vector" then
            return (pi-pf).Magnitude
        else
            return CFrameDist(pi,pf)^2
        end
	end
    local t0 = 0;
    local t1 = t0 + tj(p0,p1)^alpha;
    local t2 = t1 + tj(p1,p2)^alpha;
    local t3 = t2 + tj(p2,p3)^alpha;
    local m1 = (1.0 - tension) * (t2 - t1) * ((p1 - p0) / (t1 - t0) - (p2 - p0) / (t2 - t0) + (p2 - p1) / (t2 - t1));
	local m2 = (1.0 - tension) * (t2 - t1) * ((p2 - p1) / (t2 - t1) - (p3 - p1) / (t3 - t1) + (p3 - p2) / (t3 - t2));
    return cubic(t, p1, m1, -3*(p1 - p2) - m1 - m1 - m2, 2*(p1 - p2) + m1 + m2)
end
k.cubicInterp = catmullRomInterp
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
k.bezierInterp = fourpCubicInterp
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
local points = {}

local previewTime = 0
local Camera = workspace.CurrentCamera
local returnCFrame = Camera.CFrame
local returnFOV = Camera.FieldOfView
local timescale = 1
m.previewing = false

function m.startPreview(ts, interp, dlay, tension, alpha)
    tension = tension
    alpha = alpha
    local pointdir = script:FindFirstChildWhichIsA("Folder")
    local sort = {}
    for _, i in pairs(pointdir:GetChildren()) do
        if tonumber(i.Name) then sort[#sort+1] = tonumber(i.Name) end
    end
    table.sort(sort)
    for _, i in pairs(sort) do points[#points+1] = pointdir:FindFirstChild(tostring(i)) end
    interpMethod = interp or interpMethod
    timescale = ts
    delay = dlay
    previewTime = 0
    Camera = workspace.CurrentCamera
    returnCFrame = Camera.CFrame
    returnFOV = Camera.FieldOfView
    m.previewing = true
end
function m.stopPreview()
    Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = returnCFrame
    Camera.FieldOfView = returnFOV
    m.previewing = false
end

function m.setCFRoll(cf, r)
    local pitch, yaw, _ = cf:ToEulerAnglesYXZ()
	cf = CFrame.fromEulerAnglesYXZ(pitch, yaw, r) + cf.Position
    return cf
end

game:GetService("RunService").Heartbeat:Connect(function(step)
    if not points or not m.previewing then return end
    local scaledTime = previewTime * timescale
    local previewLocation = pathInterp(points, math.max(scaledTime-delay, 0), k[interpMethod])
    if not previewLocation[1] then
        Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = previewLocation[3]
        print(previewLocation[2])
        print(previewLocation[4])
        Camera.CFrame = m.setCFRoll(previewLocation[2], math.rad(previewLocation[4]))
    else
        m.stopPreview()
    end
    previewTime = previewTime + step
end)
return m