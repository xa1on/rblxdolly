local RunService = game:GetService("RunService")
--[[
    RBLXMVM
    something#7597
    ideas:
    lighting configs
    editing point properties

    campaths
        3 passes, regular, depth, greenscreen
        camdata exporting into AE
            ae script to import camdata
    widget layout:
]]--

if game:GetService("RunService"):IsRunning() then return end

print("\n" ..
"       ____________ _     __   _____  ____   ____  ___\n" ..
"       | ___ \\ ___ \\ |    \\ \\ / /|  \\/  | | | |  \\/  |\n" ..
"       | |_/ / |_/ / |     \\ V / | .  . | | | | .  . |\n" ..
"       |    /| ___ \\ |     /   \\ | |\\/| | | | | |\\/| |\n" ..
"       | |\\ \\| |_/ / |____/ /^\\ \\| |  | \\ \\_/ / |  | |\n" ..
"       \\_| \\_\\____/\\_____/\\/   \\/\\_|  |_/\\___/\\_|  |_/\n" .. 
"\n\n                   [xalon / something786]\n")

-- widget
local widgetInfo  = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Left,
	false,
	false,
	275,
	200,
	275,
	200)
local widget = plugin:CreateDockWidgetPluginGui("RBLXDOLLY", widgetInfo)
local playerId = game:GetService("StudioService"):GetUserId()
widget.Title = "RBLXDOLLY - " .. game:GetService("Players"):GetNameFromUserIdAsync(playerId)


-- dependencies
local moduledir = script.Parent.modules

-- initalizing widget
local wdg = require(moduledir.widgets.initalize)
wdg:GenerateWidget(widget)

require(moduledir.widgets.require)(plugin)

local dep = require(script.Parent.dependencies)

-- toolbar
local toolbar = plugin:CreateToolbar("rblxdolly")

-- buttons
local b_toggle = toolbar:CreateButton("Toggle","Toggle widget","")

-- local variables


-- local functions

local function createAction(id, title, desc, icon, action, bindable)
    return plugin:CreatePluginAction(id, title, desc .. " - rblxdolly", icon, bindable).Triggered:Connect(action)
end

b_toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
createAction("toggleWidget", "Toggle Widget", "Toggles widget", "", function() widget.Enabled = not widget.Enabled end)



-- creating points
local function createPoint()
    if not dep.dollycam.playing then
        dep.dollycam.createPoint()
    end
    dep.HistoryService:SetWaypoint("Created Point")
end
wdg["createPoint"].MouseButton1Down:Connect(createPoint)
createAction("createPoint", "Create Point", "Creates a campath point", "", createPoint)


-- running path
local function runPath()
    if not dep.dollycam.playing then dep.dollycam.runPath() end
end
wdg["runPath"].MouseButton1Down:Connect(runPath)
createAction("runPath", "Play Path", "Plays selected path", "", runPath)


-- stop playback
local function stopPath()
    if dep.dollycam.playing then dep.dollycam.stopPreview() end
end
wdg["stopPath"].MouseButton1Down:Connect(stopPath)
createAction("stopPath", "Stop Playback", "Stops playback", "", stopPath)


-- editing roll
local function editRoll()
    if not dep.dollycam.playing then dep.setRoll.toggleRollGui() end
end
wdg["editRoll"].MouseButton1Down:Connect(editRoll)
createAction("editRoll", "Edit Roll", "Toggles roll GUI", "", editRoll)


wdg["timescaleInput"]:SetValueChangedFunction(function(newts)
    if tonumber(newts) then
        if not dep.dollycam.playing then
            dep.timescale.timescale = newts
        else
            wdg["timescaleInput"]:SetValue(dep.timescale.timescale)
        end
    end
end)

wdg["fovInputSlider"]:SetValueChangedFunction(function(newfov)
    if not dep.dollycam.playing then 
        workspace.CurrentCamera.FieldOfView = newfov
        wdg["fovInput"]:SetValue(newfov)
    else
        wdg["fovInputSlider"]:SetValue(workspace.CurrentCamera.FieldOfView)
    end
end)

wdg["fovInput"]:SetValueChangedFunction(function(newfov)
    if tonumber(newfov) then
        if not dep.dollycam.playing then 
            workspace.CurrentCamera.FieldOfView = newfov
            wdg["fovInputSlider"]:SetValue(newfov)
        else
            wdg["fovInput"]:SetValue(workspace.CurrentCamera.FieldOfView)
        end
    end
end)

wdg["rollInput"]:SetValueChangedFunction(function(newroll)
    if tonumber(newroll) then
        if not dep.dollycam.playing and not dep.setRoll.roll_active then
            dep.setRoll.angle = newroll
        else
            wdg["rollInput"]:SetValue(dep.setRoll.angle)
        end
    end
end)

wdg["tweenTime"]:SetValueChangedFunction(function(newtween)
    if tonumber(newtween) then
        if not dep.dollycam.playing then
            dep.dollycam.latesttweentime = newtween
        else
            wdg["tweenTime"]:SetValue(dep.dollycam.latesttweentime)
        end
    end
end)


wdg["pathDropdown"]:SetValueChangedFunction(function(newpath)
    if not dep.dollycam.playing then
        dep.dollycam.unloadPaths()
        wdg["pathNameInput"]:SetValue(newpath.Name)
        dep.dollycam.loadPath(dep.dollycam.unloadedPathsDir:FindFirstChild(newpath.Name))
        dep.dollycam.checkDir()
        dep.dollycam.renderPath()
        dep.HistoryService:SetWaypoint("Switched paths")
    end
end)

wdg["interpDropdown"]:SetValueChangedFunction(function(newinterp)
    if not dep.dollycam.playing then
        dep.dollycam.interpMethod = newinterp
        dep.dollycam.renderPath()
        dep.HistoryService:SetWaypoint("Changed interpolation methods")
    end
end)

--[[
wdg["autoreorder"]:SetValueChangedFunction(function(newvalue)
    if not dep.dollycam.playing then
        dep.dollycam.allowReorder = newvalue
        dep.dollycam.renamePoints()
    end
end)]]


local function clearctrlbezier()
    if not dep.dollycam.playing then
        dep.dollycam.clearCtrl()
    end
end
wdg["clearctrlbezier"].MouseButton1Down:Connect(clearctrlbezier)
createAction("clearctrlbezier", "Reset Control Points", "Resets Control Points", "", clearctrlbezier)


local function disconnect()
    if not dep.dollycam.playing then
        dep.util.clearConnections()
    end
end
wdg["disconnect"].MouseButton1Down:Connect(disconnect)
createAction("disconnect", "Disconnect", "Clears Connections", "", disconnect)
--[[
local sgui = Instance.new("ScreenGui", workspace)
for _,i in pairs(widget:GetChildren()) do
    i:Clone().Parent = sgui
end
]]--
plugin.Unloading:Connect(function()
    dep.util.mvmprint("Unloading Plugin")
    disconnect()
end)

dep.util.mvmprint("Finished Loading")