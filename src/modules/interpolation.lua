local m = {}
m.defaultSpeed = 15

function m.CFrameDist(cf1, cf2)
    return math.abs((cf1.Position - cf2.Position).Magnitude)
end

function m.lerp(start, goal, alpha)
    return start + (goal - start) * alpha
end

-- Credit to @Fractality_alt on rblx devforums for the hermite and catmull rom coefficent functions
function m.GetHermiteCoefficients(p0, p1, m0, m1)
	return p0, m0, 3*(p1 - p0) - 2*m0 - m1, 2*(p1 - p0) - m0 - m1
end

function m.GetCentripetalCRCoefficients(p0, p1, p2, p3)
	return
		p1,
		0.5*(p2 - p0),
		p0 - 2.5*p1 + 2*p2 - 0.5*p3,
		1.5*(p1 - p2) + 0.5*(p3 - p0)
end

function m.calcCubic(t,a,b,c,d)
    return a + t*(b + t*(c + t*d))
end

function m.calcCatmullRom(t, p1, p2, pi, pf)
    local p1 = p1 -- lol yeah ik
    local pi = pi or p1
    local p2 = p2 or p1
    local pf = pf or p2
    local a,b,c,d = m.GetCentripetalCRCoefficients(pi, p1, p2, pf)
    return m.calcCubic(t,a,b,c,d)
end

function m.pointCatmullRom(path,t)
    local p1 = path[2]
    local pi = path[1] or p1
    local p2 = path[3] or p1
    local pf = path[4] or p2
    return CFrame.new(m.calcCatmullRom(t, p1.Position, p2.Position, pi.Position, pf.Position), m.calcCatmullRom(t, p1.LookVector, p2.LookVector, pi.LookVector, pf.LookVector))
end

function m.bezierLength(path,type,acc)
    if not acc then
        acc = 0.05
    end
    local lengths = {}
    for i = 2, #path, 1 do
        local len = 0
        local l = acc
        local previous = type(path,0)
        while not previous[1] do
            local currentCFrame = type(path,l)
            len = len + m.CFrameDist(previous[2], currentCFrame[2])
            l=l+acc
            previous = currentCFrame
        end
        lengths[i-1] = len
    end
    return lengths
end

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
    if #points < 0 then
        return {true,CFrame.new(),60,0}
    end
    local current_t = t * m.defaultSpeed
    for index, current in pairs(points) do
        local previous = points[index-1]
        if previous then
            local dist = m.CFrameDist(current.CFrame, previous.CFrame)
            local progression = current_t/dist
            if progression >= 1 then
                current_t = current_t - dist
            else
                return {false,
                previous.CFrame:Lerp(current.CFrame,progression),
                m.lerp(previous.FOV.Value, current.FOV.Value, progression),
                m.lerp(previous.Roll.Value, current.Roll.Value, progression)}
            end
        end
    end
    local lastPoint = points[#points]
    return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
end

m["linear"] = m.linearInterp

function m.hermiteInterp(path,t)
end

function m.catmullromInterp(path,t)
    local points = m.grabPoints(path)
    if #points < 0 then
        return {true,CFrame.new(),60,0}
    end
    local current_t = t * m.defaultSpeed
    for index, current in pairs(points) do
        local previous = points[index-1]
        if previous then
            local cframelist = {}
            for i = -1,2,1 do
                if points[index+i] then cframelist[i+2] = points[index+i].CFrame
                else cframelist[i+2] = nil end
            end
            local dist = m.bezierLength(cframelist)
            local progression = current_t/dist
            if progression >= 1 then
                current_t = current_t - dist
            else
                return {false,
                m.pointCatmullRom(cframelist,progression),
                m.lerp(previous.FOV.Value, current.FOV.Value, progression),
                m.lerp(previous.Roll.Value, current.Roll.Value, progression)}
            end
        end
    end
    local lastPoint = points[#points]
    return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
end
m["cmrom"] = m.catmullromInterp

return m