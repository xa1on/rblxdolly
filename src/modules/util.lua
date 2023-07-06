local repStorage = game:GetService("ReplicatedStorage")

local m = {}
m.connections = {}

m.detectionlist = {}

function m.mvmprint(t)
    print("[" .. t .. " - RBLXDOLLY]")
end

function m.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. m.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

function m.notnill(inst)
    if not inst then
        return false
    end
    if inst.Parent then
        if inst.Parent == workspace or inst.Parent == repStorage then
            return true
        else 
            return m.notnill(inst.Parent)
        end
    else
        return false
    end
end

function m.createIfNotExist(parent, type, name, connection, func)
    local newInst = parent:FindFirstChild(name)
    if not newInst then
        newInst = Instance.new(type, parent)
        newInst.Name = name
        if connection then
            m.connections[#m.connections+1] = newInst[connection]:Connect(func)
        end
    end
    return newInst
end

function m.clearConnections()
    for _, v in pairs(m.connections) do
        v:Disconnect()
    end
    m.mvmprint("Connections Cleared")
end

function m.appendConnection(connection)
    m.connections[#m.connections+1] = connection
end

return m