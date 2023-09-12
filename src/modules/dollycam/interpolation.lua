local m = {}

local util = require(script.Parent.Parent.util)

m.startctrlName = "1"
m.endctrlName = "2"
m.tension = 0
m.alpha = 0

function m.CFrameDist(cf1, cf2)
    if not cf1 or not cf2 then return 0 end
    return math.abs((cf1.Position - cf2.Position).Magnitude)
end

-- hermite coefficents
function m.hermiteCoefficents(p0, p1, m0, m1)
	return p0, m0, 3*(p1 - p0) - 2*m0 - m1, 2*(p1 - p0) - m0 - m1
end

-- catmull rom coefficents
function m.CRCoefficents(p0, p1, p2, p3, t)
    t = t or m.tension
	return
	    p1,
		-t*p0 + t*p2,
		2*t*p0 + (t-3)*p1 + (3-2*t)*p2 - t*p3,
		-t*p0 + (2-t)*p1 + (t-2)*p2 + t*p3
end

function m.cubic(t, a, b, c, d)
    return a + t*(b + t*(c + t*d))
end

function m.lerp(p1, p2, t)
    return p1 + (p2 - p1) * t
end

function m.cosine(p1, p2, t)
    p2 = p2 or p1
    local f = (1 - math.cos(t * math.pi)) / 2
	return m.lerp(p1,p2,f)
end

function m.linearInterp(path, t)
    local p1 = path[1]
    local p2 = path[2] or p1
    return m.lerp(p1, p2, t)
end

function m.cosineInterp(path, t)
    local p1 = path[1]
    local p2 = path[2] or p1
    return m.cosine(p1, p2, t)
end

function m.catmullRomInterp(path, t, _, tension, alpha)
    tension = tension or m.tension
    alpha = alpha or m.alpha
    local p0 = path[0] or path[1]
    local p1 = path[1]
    local p2 = path[2] or p1
    local p3 = path[3] or p2
    local function tj(pi, pf)
        if pi == pf then return 1 end
        if type(pi) == "number" then
            return pi-pf
        elseif type(pi) == "vector" then
            return (pi-pf).Magnitude
        else
            return m.CFrameDist(pi,pf)^2
        end
    end
    local t0 = 0;
    local t1 = t0 + tj(p0,p1)^alpha;
    local t2 = t1 + tj(p1,p2)^alpha;
    local t3 = t2 + tj(p2,p3)^alpha;
    local m1 = (1.0 - tension) * (t2 - t1) * ((p1 - p0) / (t1 - t0) - (p2 - p0) / (t2 - t0) + (p2 - p1) / (t2 - t1));
    local m2 = (1.0 - tension) * (t2 - t1) * ((p2 - p1) / (t2 - t1) - (p3 - p1) / (t3 - t1) + (p3 - p2) / (t3 - t2));

    return m.cubic(t, p1, m1, -3*(p1 - p2) - m1 - m1 - m2, 2*(p1 - p2) + m1 + m2)
    --local a,b,c,d = m.CRCoefficents(p0, p1, p2, p3)
    --return m.cubic(t, a, b, c, d)
end
m.cubicInterp = m.catmullRomInterp

function m.fourpCubicInterp(path, t, control)
    if not control then return m.catmullRomInterp(path, t) end
    local p1 = path[1]
    local p2 = path[2]
    local c1 = control[1][2]
    local c2 = control[2][1]
    local l1 = m.lerp(p1, c1, t)
    local l2 = m.lerp(c1, c2, t)
    local l3 = m.lerp(c2, p2, t)
    local a = m.lerp(l1, l2, t)
    local b = m.lerp(l2, l3, t)
    return m.lerp(a, b, t)
end
m.bezierInterp = m.fourpCubicInterp

function m.interpolateCF(path, t, func, control)
    if not func then func = m.linearInterp end
    local pv = {}
    local lv = {}
    for i, v in pairs(path) do
        pv[i] = v.Position
        lv[i] = v.LookVector
    end
    local cpv = {}
    local clv = {}
    if control then
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
    end
    local newpv = func(pv, t, cpv)
    local newlv = func(lv, t, clv)
    return CFrame.new(newpv, newpv + newlv)
end

function m.segmentInterp(points, t, func)
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
            local startCtrl = points[i]:FindFirstChild(m.startctrlName)
            if startCtrl then ctrllist[i][1] = startCtrl.CFrame end
            local endCtrl = points[i]:FindFirstChild(m.endctrlName)
            if endCtrl then ctrllist[i][2] = endCtrl.CFrame end
        end
    end
    local dist = points[1].TweenTime.Value
    local progression = t/dist
    if progression >= 1 then
        return {true, points[2].CFrame, points[2].FOV.Value, points[2].Roll.Value, dist}
    else
        return {false,
        m.interpolateCF(cframelist, progression, func, ctrllist),
        func(fovlist, progression),
        func(rolllist, progression),
        0}
    end
end

function m.pathInterp(points, t, func)
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
            local segInterp = m.segmentInterp(pointlist, current_t, func)
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

function m.moonSegmentInterp(points, t, func)
    for _,v in pairs(points) do
        v[0] = v[0] or v[1]
        v[1] = v[1] or v[2]
        v[2] = v[2] or v[1]
        v[3] = v[3] or v[2]
    end
    local content = {CFrame = {}, FOV = {}, Roll = {}}
    local progress = {CFrame = 0, FOV = 0, Roll = 0}
    for j, v in pairs(points) do
        for i = 0,3,1 do
            if v[i] then content[j][i] = v[i][1] end
        end
        if v[2][2] - v[1][2] == 0 then
            progress[j] = 1
        else
            progress[j] = (t - v[1][2]) / (v[2][2] - v[1][2])
        end
    end
    --print(util.dump(content))
    --print(util.dump(progress))
    return {false,
    m.interpolateCF(content.CFrame, progress.CFrame, func),
    func(content.FOV, progress.FOV),
    func(content.Roll, progress.Roll),0}
end

function m.moonPathInterp(points, t, func)
    local returnTable
    local inputTable = {}
    local found = false
    for i,v in pairs(points) do
        found = false
        for j, k in pairs(v) do
            if k[2] > t then
                inputTable[i] = {[0] = v[j-2], [1] = v[j-1], [2] = k, [3] = v[j+1]}
                found = true
                break
            end
        end
        if not found then inputTable[i] = {v[#v]} end
    end
    returnTable = m.moonSegmentInterp(inputTable, t, func)
    return {false, returnTable[2], returnTable[3], returnTable[4], 0}
end

return m