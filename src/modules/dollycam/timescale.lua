local m = {}

m.timescale = 1

function m.resetTimescale()
    for _, i in pairs(workspace:GetDescendants()) do
        if i:IsA("ParticleEmitter") and i:FindFirstChild("originalTS") then
            i.TimeScale = i:FindFirstChild("originalTS").Value
            i:FindFirstChild("originalTS"):Destroy()
        end
    end
end

function m.particleTimescale(ts)
    m.resetTimescale()
    for _, i in pairs(workspace:GetDescendants()) do
        if i:IsA("ParticleEmitter") then
            local originalts = Instance.new("NumberValue", i)
            originalts.Name = "originalTS"
            originalts.Value = i.TimeScale
            i.TimeScale = i.TimeScale * ts
        end
    end
end
return m