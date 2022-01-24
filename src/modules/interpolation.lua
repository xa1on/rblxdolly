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

function m.bezierLength(path,type,acc)
    if not acc then
        acc = 0.1
    end
    local lengths = {}
    for i = 2, #path, 1 do
        local len = 0
        local l = acc
        local previous = type(path,0)
        while not previous[1] do
            local currentCFrame = type(path,l)
            len = m.CFrameDist(previous[2], currentCFrame[2])
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
    if #points > 0 then
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
    return {true,CFrame.new(),60,0}
end

m["linear"] = m.linearInterp

function m.hermiteInterp()
    
end

function m.catmullromInterp()

end


return m