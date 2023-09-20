local m = {}

local util = require(script.Parent.Parent.util)

m.startctrlName = "1"
m.endctrlName = "2"
m.tension = 0
m.alpha = 0
--[[
m.graph = game:GetService("StarterGui"):FindFirstChild("Graph")
m.graphy = 1


function m.clearGraph()
    if not m.graph then return end
    m.graph.Frame:ClearAllChildren()
    m.graphy = 1
end
function m.graphPoint(x)
    if not m.graph then return end
    local newPoint = m.graph.Dot:Clone()
    newPoint.Parent = m.graph.Frame
    newPoint.Position = UDim2.new(0, x, m.graphy, 0)
    m.graphy = m.graphy - 0.001
end]]

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
    return d + t*(c + t*(b + t*a))
end

function m.invquad(y, a, b, c)
    if a == 0 then return -((c-y)/b) end
    c = c - y
    return (-b+(b^2-4*a*c)^(1/2))/(2*a)
end

function m.invcubic(y, a, b, c, d, threshold, min, max)
    if not a then return m.invquad(y, b, c) end
    threshold = threshold or 0.0001
    max = max or 1
    min = min or 0
    if min > 1 - threshold then return 1 end
    if min >= max then
        return nil
    end
    local mid = (max + min)/2
    local calc = m.cubic(mid, a, b, c, d)
    local diff = y - calc
    if math.abs(diff) <= threshold then
        return mid
    elseif diff < 0 then
        return m.invcubic(y, a, b, c, d, threshold, min, mid)
    else
        return m.invcubic(y, a, b, c, d, threshold, mid, max)
    end
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
    if #path < 1 then return end
    local p1 = path[1]
    local p2 = path[2] or p1
    return m.lerp(p1, p2, t)
end

function m.cosineInterp(path, t)
    if #path < 1 then return end
    local p1 = path[1]
    local p2 = path[2] or p1
    return m.cosine(p1, p2, t)
end

function m.catmullRomInterp(path, t, _, tension, alpha, inv, y)
    if #path < 1 then return end
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
    if inv then return m.invcubic(y, 2*(p1 - p2) + m1 + m2, -3*(p1 - p2) - m1 - m1 - m2, m1, p1) end
    return m.cubic(t, 2*(p1 - p2) + m1 + m2, -3*(p1 - p2) - m1 - m1 - m2, m1, p1)
    --local a,b,c,d = m.CRCoefficents(p0, p1, p2, p3)
    --return m.cubic(t, a, b, c, d)
end
m.cubicInterp = m.catmullRomInterp

function m.fourpCubicInterp(path, t, control)
    if #path < 1 then return end
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
    local totaldist = 0
    local cframelist = {}
    local fovlist = {}
    local rolllist = {}
    local ctrllist = {}
    local distlist = {}
    for i = 0,3,1 do
        if points[i] then
            cframelist[i] = points[i].CFrame
            fovlist[i] = points[i].FOV.Value
            rolllist[i] = points[i].Roll.Value
            distlist[i+1] = points[i].TweenTime.Value + totaldist
            totaldist += points[i].TweenTime.Value
            ctrllist[i] = {}
            local startCtrl = points[i]:FindFirstChild(m.startctrlName)
            if startCtrl then ctrllist[i][1] = startCtrl.CFrame end
            local endCtrl = points[i]:FindFirstChild(m.endctrlName)
            if endCtrl then ctrllist[i][2] = endCtrl.CFrame end
        end
    end
    local progression = t/points[1].TweenTime.Value
    --[[
    if true then--func == m.catmullRomInterp then
        progression = m.catmullRomInterp(distlist, nil, nil, nil, nil, true, t + distlist[1])
        m.graphPoint(progression*200)
        --progression = (m.catmullRomInterp(distlist, (t/points[1].TweenTime.Value)) - distlist[1])/(points[2].TweenTime.Value)
        --print(progression)
        --print(t)
        print(util.dump(distlist))
        --task.wait(0.1)
    end]]
    if progression >= 1 then
        return {true, points[2].CFrame, points[2].FOV.Value, points[2].Roll.Value, points[1].TweenTime.Value}
    else
        return {false,
        m.interpolateCF(cframelist, progression, func, ctrllist),
        func(fovlist, progression),
        func(rolllist, progression)}
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
            if current_t >= points[index].TweenTime.Value then current_t = current_t - points[index].TweenTime.Value continue end
            local pointlist = {}
            for i = -1,2,1 do
                if points[index+i] then
                    pointlist[i+1] = points[index+i]
                end
            end
            local segInterp = m.segmentInterp(pointlist, current_t, func)
            --[[local dist = segInterp[5]
            if segInterp[1] then
                current_t = current_t - dist
            else]]
            --print(util.dump(segInterp))
                return segInterp
            --end
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
            progress[j] = 0
        else
            progress[j] = (t - v[1][2]) / (v[2][2] - v[1][2])
        end
    end
    --print(util.dump(content))
    --print(util.dump(progress))
    local returnTable = {false}
    returnTable[2] = m.interpolateCF(content.CFrame, progress.CFrame, func)
    returnTable[3] = func(content.FOV, progress.FOV)
    returnTable[4] = func(content.Roll, progress.Roll)
    return returnTable
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
    return {false, returnTable[2], returnTable[3], returnTable[4]}
end

return m