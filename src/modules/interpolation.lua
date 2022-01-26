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

function m.GetCentripetalCRCoefficients(p0, p1, p2, p3, r)
    local r = r or 0.5
	return
		2*p1*r,
		(p2 - p0)*r,
		(2*p0 - 5*p1 + 4*p2 - p3)*r,
		(3*(p1 - p2) + (p3 - p0))*r
end

function m.interpCosine(t, v1, v2)
    local v2 = v2 or v1
    local f = (1 - math.cos(t * math.pi)) * 0.5
	return v1 * (1 - f) + v2 * f
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

function m.pathCatmullRom(path,t)
    local p1 = path[2]
    local pi = path[1] or p1
    local p2 = path[3] or p1
    local pf = path[4] or p2
    return m.calcCatmullRom(t, p1, p2, pi, pf)
end

function m.pointCatmullRom(path,t)
    local p1 = path[2]
    local pi = path[1] or p1
    local p2 = path[3] or p1
    local pf = path[4] or p2
    local newposv = m.calcCatmullRom(t, p1.Position, p2.Position, pi.Position, pf.Position)
    local newlookv = m.calcCatmullRom(t, p1.LookVector, p2.LookVector, pi.LookVector, pf.LookVector)
    return CFrame.new(newposv, newposv + newlookv)
end

function bezierLength(path, type)

end

function m.grabPoints(path)
    local points = {}
    local sort = {}
    for _, i in pairs(path:GetChildren()) do
        if tonumber(i.Name) then sort[#sort+1] = tonumber(i.Name) end
    end
    table.sort(sort)
    for _, i in pairs(sort) do points[#points+1] = path:FindFirstChild(tostring(i)) end
    return points
end

function m.linearInterp(path,t)
    local points = m.grabPoints(path)
    if #points <= 0 then
        return {true,CFrame.new(),60,0}
    end
    local current_t = t * m.defaultSpeed
    for index, current in pairs(points) do
        local next = points[index+1]
        if next then
            local dist = m.CFrameDist(current.CFrame, next.CFrame)
            local progression = current_t/dist
            if progression >= 1 then
                current_t = current_t - dist
            else
                return {false,
                current.CFrame:Lerp(next.CFrame,progression),
                m.lerp(current.FOV.Value, next.FOV.Value, progression),
                m.lerp(current.Roll.Value, next.Roll.Value, progression)}
            end
        end
    end
    local lastPoint = points[#points]
    return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
end
m["linear"] = m.linearInterp

function m.hermiteInterp(path,t)
end

function m.catmullromInterp(path,t,constspeed)
    local points = m.grabPoints(path)
    if #points <= 0 then
        return {true,CFrame.new(),60,0}
    end
    local current_t = t * m.defaultSpeed
    for index, current in pairs(points) do
        local next = points[index+1]
        if next then
            local cframelist = {}
            local fovlist = {}
            local rolllist = {}
            for i = -1,2,1 do
                if points[index+i] then
                    cframelist[i+2] = points[index+i].CFrame
                    fovlist[i+2] = points[index+i].FOV.Value
                    rolllist[i+2] = points[index+i].Roll.Value
                end
            end
            local dist = 5 * m.defaultSpeed
            local progression = current_t/dist
            if progression >= 1 then
                current_t = current_t - dist
            else
                return {false,
                m.pointCatmullRom(cframelist,progression),
                m.pathCatmullRom(fovlist, progression),
                m.pathCatmullRom(rolllist, progression)}
            end
        end
    end
    local lastPoint = points[#points]
    return {true, lastPoint.CFrame, lastPoint.FOV.Value, lastPoint.Roll.Value}
end
m["cubic"] = m.catmullromInterp

return m