local m = {}

function m.CFrameDist(cf1, cf2)
    return math.abs((cf1.Position - cf2.Position).Magnitude)
end

function m.lerp(start, goal, alpha)
    return start + (goal - start) * alpha
end

function m.quadLerp(p1, p2, p0, t)
    local l1 = p1:Lerp(p0, t)
    local l2 = p0:Lerp(p2, t)
    return l1:Lerp(l2, t)
end

function m.cubicLerp(p1, p2, ps1, ps2, t)
    local l1 = p1:Lerp(ps1, t)
    local l2 = ps1:Lerp(ps2, t)
    local l3 = ps2:Lerp(p2, t)
    local r1 = l1:Lerp(l2, t)
    local r2 = l2:Lerp(l3, t)
    return r1:Lerp(r2, t)
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

return m