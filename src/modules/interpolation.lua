local m = {}

m.defaultTiming = 2
m.constSpeed = true

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

function m.fourpBezierInterp(path, t, control)
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
m.bezierInterp = m.fourpBezierInterp

function m.interpolateCF(path, t, func, control)
    if not func then func = m.linearInterp end
    local pv = {}
    local lv = {}
    for i, v in pairs(path) do
        pv[i] = v.Position
        lv[i] = v.LookVector
    end
    local newpv = func(pv, t, control)
    local newlv = func(lv, t)
    return CFrame.new(newpv, newpv + newlv)
end



function m.pathInterp(points, t, func)
    if #points <= 0 then
        return {true, CFrame.new(), 60, 0}
    end
    local current_t = t
    for index, current in pairs(points) do
        local next = points[index+1]
        if next then
            local cframelist = {}
            local fovlist = {}
            local rolllist = {}
            local ctrllist = {}
            for i = -1,2,1 do
                if points[index+i] then
                    cframelist[i+1] = points[index+i].CFrame
                    fovlist[i+1] = points[index+i].FOV.Value
                    rolllist[i+1] = points[index+i].Roll.Value
                    ctrllist[i+1] = {}
                    for _, v in pairs(points[index+i]:GetChildren()) do
                        if v:IsA("BasePart") then ctrllist[i+1][tonumber(v.Name)] = v.Position end
                    end
                end
            end
            local dist = m.defaultTiming
            local progression = current_t/dist
            if progression >= 1 then
                current_t = current_t - dist
            else
                return {false,
                m.interpolateCF(cframelist, progression, func, ctrllist),
                func(fovlist, progression),
                func(rolllist, progression)}
            end
        end
    end
    local lastPoint = points[#points]
    return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
end


return m