local m = {}

local util = require(script.Parent.Parent.util)

m.defaultTiming = 2.5

m.startctrlName = "1"
m.endctrlName = "2"

function m.CFrameDist(cf1, cf2)
    return math.abs((cf1.Position - cf2.Position).Magnitude)
end

-- Credit to @Fractality_alt on rblx devforums for the hermite and catmull rom coefficent functions
-- hermite coefficents
function m.hermiteCoefficents(p0, p1, m0, m1)
	return p0, m0, 3*(p1 - p0) - 2*m0 - m1, 2*(p1 - p0) - m0 - m1
end

-- catmull rom coefficents
function m.CRCoefficents(p0, p1, p2, p3, r)
    r = r or 0.5
	return
		2*p1*r,
		(p2 - p0)*r,
		(2*p0 - 5*p1 + 4*p2 - p3)*r,
		(3*(p1 - p2) + (p3 - p0))*r
end

function m.cubic(t, a, b, c, d)
    return a + t*(b + t*(c + t*d))
end

function m.lerp(p1, p2, t)
    return p1 + (p2 - p1) * t
end

function m.cosine(p1, p2, t)
    p2 = p2 or p1
    local f = (1 - math.cos(t * math.pi)) * 0.5
	return p1 * (1 - f) + p2 * f
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

function m.catmullRomInterp(path, t)
    local p0 = path[0] or path[1]
    local p1 = path[1]
    local p2 = path[2] or p1
    local p3 = path[3] or p2
    local a,b,c,d = m.CRCoefficents(p0, p1, p2, p3)
    return m.cubic(t, a, b, c, d)
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

function m.segmentInterp(points, t, func, usetween)
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
    local dist = m.defaultTiming
    if usetween then dist = points[2].TweenTime.Value end
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

function m.pathInterp(points, t, func, usetween)
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
            local segInterp = m.segmentInterp(pointlist, current_t, func, usetween)
            local dist = m.defaultTiming
            if usetween then dist = segInterp[5] end
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

return m