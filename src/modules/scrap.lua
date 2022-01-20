--[[local function revealFrame()
    for _, instance in pairs(widget:GetChildren()) do
        local clone = instance:Clone()
        clone.Parent = workspace
    end
end

local function revealElements()
    for index, instance in pairs(wdginit) do
        print(tostring(index))
    end
end]]