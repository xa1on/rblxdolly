--[[
    rblxmvm
    something#7597
ideas:

campaths
    3 passes, regular, depth, greenscreen
    camdata exporting into AE
        ae script to import camdata

widget layout:
dollycam:
    create point

]]--

-- widget
local widgetInfo  = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,
	false,
	false,
	200,
	200,
	150,
	150)
local widget = plugin:CreateDockWidgetPluginGui("rblxmvm", widgetInfo)
widget.Title = "rblxmvm - something/xalon"

-- dependencies
local moduledir = script.Parent.modules

local wdginit = require(moduledir.widgets.initalize)
wdginit:GenerateWidget(widget)

require(moduledir.widgets.require)(plugin)

local dep = require(script.Parent.dependencies)

-- toolbar
local toolbar = plugin:CreateToolbar("rblxmvm")

-- buttons
local b_toggle = toolbar:CreateButton("Toggle","Toggle rblxmvm widget","")


-- local variables
local timescale = 1

-- local functions
dep.dollycam.RenderPath()

dep.dollycam:reconnectPoints()

b_toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)

dep.dollycam.resetTimescale()

-- DOLLYCAM

dep.RunService.Heartbeat:Connect(dep.dollycam.playback)

wdginit["pathDropdown"]:GetButton().MouseButton1Click:Connect(dep.dollycam.reloadDropdown)

wdginit["createPoint"].MouseButton1Down:Connect(function()
    if not dep.dollycam.playing then
        dep.dollycam.createPoint(dep.setRoll.angle, workspace.CurrentCamera.FieldOfView)
    end
end)

wdginit["runPath"].MouseButton1Down:Connect(function()
    if not dep.dollycam.playing then dep.dollycam.runPath(timescale) end
end)

wdginit["stopPath"].MouseButton1Down:Connect(function()
    if dep.dollycam.playing then dep.dollycam.stop() end
end)

--[[wdginit["rerenderPath"].MouseButton1Down:Connect(function()
    if not dep.dollycam.playing then dep.dollycam.RenderPath() end
end)]]

wdginit["timescaleInput"]:SetValueChangedFunction(function(newts)
    if tonumber(newts) then
        if not dep.dollycam.playing then
            timescale = newts
        else
            wdginit:SetValue(timescale)
        end
    end
end)

wdginit["fovInputSlider"]:SetValueChangedFunction(function(newfov)
    if not dep.dollycam.playing then 
        workspace.CurrentCamera.FieldOfView = newfov
        wdginit["fovInput"]:SetValue(newfov)
    else
        wdginit["fovInputSlider"]:SetValue(workspace.CurrentCamera.FieldOfView)
    end
end)

wdginit["fovInput"]:SetValueChangedFunction(function(newfov)
    if tonumber(newfov) then
        if not dep.dollycam.playing then 
            workspace.CurrentCamera.FieldOfView = newfov
            wdginit["fovInputSlider"]:SetValue(newfov)
        else
            wdginit["fovInput"]:SetValue(workspace.CurrentCamera.FieldOfView)
        end
    end
end)

wdginit["editRoll"].MouseButton1Down:Connect(function()
    if not dep.dollycam.playing then dep.setRoll.toggleRollGui() end
end)

wdginit["rollInput"]:SetValueChangedFunction(function(newroll)
    if tonumber(newroll) then
        if not dep.dollycam.playing and not dep.setRoll.roll_active then
            dep.setRoll.angle = newroll
        else
            wdginit["rollInput"]:SetValue(dep.setRoll.angle)
        end
    end
end)

wdginit["pathDropdown"]:SetValueChangedFunction(function(newpath)
    if not dep.dollycam.playing then
        wdginit["pathNameInput"]:SetValue(newpath.Name)
        dep.dollycam.RenderPath()
    end
end)

wdginit["interpDropdown"]:SetValueChangedFunction(function(newinterp)
    if not dep.dollycam.playing then
        dep.dollycam.interpMethod = newinterp
        dep.dollycam.RenderPath()
    end
end)