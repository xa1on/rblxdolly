local m = {}

-- dependencies
local setRoll = require(script.Parent.setRoll)
local interp = require(script.Parent.interpolation)
local wdg = require(script.Parent.widgets.initalize)

local HistoryService = game:GetService("ChangeHistoryService")

-- playback variables
local playbackTime = 0
local timescale = 1
m.interpMethod = interp[wdg.InterpDefault]

local returnCFrame
local returnFOV

m.playing = false

-- variables
m.mvmDirName = "mvmpaths"
m.renderDirName = "Render"
m.pointDirName = "Points"

m.mvmDir = nil
m.currentPath = nil

function m.reloadDropdown()
    wdg.pathDropdown:RemoveAll()
    if not m.mvmDir then
        m.checkPathDir()
        return
    end
    for index, inst in pairs(m.mvmDir:GetChildren()) do
        if inst.Name ~= m.renderDirName then
            wdg.pathDropdown:AddSelection({inst.Name, inst, tostring(index)})
        end
    end
end

function m.createIfNotExist(parent, type, name, connection, func)
    local newInst = parent:FindFirstChild(name)
    if not newInst then
        newInst = Instance.new(type, parent)
        newInst.Name = name
        if connection then
            newInst[connection]:Connect(func)
        end
    end
    return newInst
end

function m.checkPathDir()
    m.mvmDir = m.createIfNotExist(workspace, "Folder", m.mvmDirName, "ChildAdded", m.reloadDropdown)
    
end

function m.reconnectPoints()

end

function m.resetTimescale()

end

function m.createPoint()
    m.checkPathDir()
end

function m.playback()

end

return m