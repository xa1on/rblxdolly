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


local moduledir = script.Parent.modules
local gui = require(moduledir.rblxgui.initialize)(plugin, "rblxdolly")

-- toolbar
local toolbar = plugin:CreateToolbar("rblxdolly")

local widget = gui.PluginWidget.new({ID = "rblxdolly", Enabled = true, DockState = Enum.InitialDockState.Left, Title = "RBLXDOLLY - " .. game:GetService("Players"):GetNameFromUserIdAsync(game:GetService("StudioService"):GetUserId())})
gui.ViewButton.new()

local b_toggle = toolbar:CreateButton("Toggle","Toggle widget","")
b_toggle.Click:Connect(function() widget.Content.Enabled = not widget.Content.Enabled end)

local mainpage = gui.Page.new({
    Name = "MAIN",
    TitlebarMenu = widget.TitlebarMenu,
    Open = true
})

local mainpageframe = gui.ScrollingFrame.new(nil, mainpage.Content)
mainpageframe:SetMain()

gui.ListFrame.new({Height = 5})

gui.Textbox.new({
    Text = "RBLXDOLLY",
    Font = Enum.Font.SourceSansBold,
    TextSize = 20,
    Alignment = Enum.TextXAlignment.Center
})

gui.Textbox.new({
    Text = "Enter a path name and create a point to get started.",
    Alignment = Enum.TextXAlignment.Center
})

gui.ListFrame.new({Height = 15})

local createpoint = gui.Button.new({Text = "Create Point", ButtonSize = 0.5})

local createscript = gui.Button.new({Text = "Create Playback Script", ButtonSize = 0.6})

gui.ListFrame.new({Height = 15})

local pathoptions = gui.Section.new({Text = "Path Options", Open = true})
pathoptions:SetMain()

local pathinput = gui.InputField.new({Placeholder = "Path Name"})
gui.Labeled.new({Text = "Path", LabelSize = UDim.new(0,85), Object = pathinput})

gui.ListFrame.new({Height = 5})

local interpolationinput = gui.InputField.new({CurrentItem = {Name = "Manual Curve", Value = "bezierInterp"}, Items = {{Name = "Manual Curve", Value = "bezierInterp"}, {Name = "Linear", Value = "linearInterp"}, {Name = "Cubic Curve", Value = "cubicInterp"}}, DisableEditing = true})
gui.Labeled.new({Text = "Interpolation", LabelSize = UDim.new(0,85), Object = interpolationinput})

local timescaleinput = gui.InputField.new({Placeholder = "Timescale Value", Value = 1, NoDropdown = true})
gui.Labeled.new({Text = "Timescale", LabelSize = UDim.new(0,85), Object = timescaleinput})

local scrubpathslider = gui.Slider.new({Min = 0, Max = 1})
gui.Labeled.new({Text = "Scrub Path", LabelSize = UDim.new(0, 85), Object = scrubpathslider})

local syncmoontimeline  = gui.Checkbox.new({Value = true})
local lsyncMASTLgui = gui.Labeled.new({Text = "Sync Moon Timeline", LabelSize = UDim.new(0.35,0), Object = syncmoontimeline})
if not _G.MoonGlobal then lsyncMASTLgui:SetDisabled(true) end

local matchmoonkeyframe  = gui.Checkbox.new({Value = false})
gui.Labeled.new({Text = "Match Moon Keyframes", LabelSize = UDim.new(0.35,0), Object = matchmoonkeyframe, Disabled = true})

gui.ListFrame.new({Height = 5})

local startstopplayback = gui.Button.new({Text = "Start/Stop Playback", ButtonSize = 0.5})

local resetcontrolpoints = gui.Button.new({Text = "Reset All Control Points", ButtonSize = 0.55})

gui.ListFrame.new({Height = 5})

local pointoptions = gui.Section.new({Text = "Point Options", Open = true}, mainpageframe.Content)
pointoptions:SetMain()

-- AKA tweentime
local tweentimeinput = gui.InputField.new({Placeholder = "Transition Time Value", Value = 2.5, NoDropdown = true})
gui.Labeled.new({Text = "Transition Time", LabelSize = UDim.new(0,85), Object = tweentimeinput})

local fovinput = gui.InputField.new({Placeholder = "FOV Value", Value = math.round(workspace.CurrentCamera.FieldOfView), NoDropdown = true})
local fovslider = gui.Slider.new({Min = 0, Max = 120, Increment = 1})
gui.Labeled.new({Text = "FOV", LabelSize = UDim.new(0,85), Objects = {{Object = fovinput, Name = "input", Size = UDim.new(0.3,0)}, {Object = fovslider, Name = "slider"}}})

local rollinput = gui.InputField.new({Placeholder = "Roll Value", Value = 0, NoDropdown = true})
gui.Labeled.new({Text = "Roll", LabelSize = UDim.new(0,85), Object = rollinput})

local previeweditroll = gui.Button.new({Text = "Preview/Edit Roll", ButtonSize = 0.5})

local recallpoint = gui.Button.new({Text = "Preview Selected Point", ButtonSize = 0.55})

local settingspage = gui.Page.new({
    Name = "SETTINGS",
    TitlebarMenu = widget.TitlebarMenu
})

local settingsframe = gui.ScrollingFrame.new(nil, settingspage.Content)

local dollycamsettings = gui.Section.new({Text = "Dollycam", Open = true}, settingsframe.Content)
dollycamsettings:SetMain()

local lockcontrolpointscheckbox = gui.Checkbox.new({Value = true})
gui.Labeled.new({Text = "Lock Control Points", LabelSize = UDim.new(0, 85), Object = lockcontrolpointscheckbox})

local keybindsection = gui.Section.new({Text = "Keybinds", Open = true}, settingsframe.Content)

local savedkeybinds = plugin:GetSetting("rblxdolly saved keybinds") or {}
local function createKeybind(title, action, default, binds)
    if savedkeybinds[title] then default = savedkeybinds[title] end
    local newkeybind = gui.KeybindInputField.new({Action = action, CurrentBind = default, Binds = binds})
    gui.Labeled.new({Text = title, LabelSize = 0.4, Object = newkeybind}, gui.ListFrame.new(nil, keybindsection.Content).Content)
    newkeybind:Changed(function(p)
        savedkeybinds[title] = p
    end)
end

local dep = require(script.Parent.dependencies)

createKeybind("Toggle Widget", function() widget.Content.Enabled = not widget.Content.Enabled end, {{"LeftControl", "LeftShift", "T"}})

local function createPoint()
    if not dep.dollycam.playing then
        dep.dollycam.createPoint()
    end
    dep.HistoryService:SetWaypoint("Created Point")
end
createpoint:Clicked(createPoint)
createKeybind("Create Point", createPoint, {{"P"}})

local function createScript()
    dep.dollycam.createPlaybackScript()
    dep.HistoryService:SetWaypoint("Created Script")
end
createscript:Clicked(createScript)
createKeybind("Create Playback Script", createScript)

local function runPath()
    if not dep.dollycam.playing then dep.dollycam.runPath()
    else dep.dollycam.stopPreview() end
end
startstopplayback:Clicked(runPath)
createKeybind("Start/Stop Playback", runPath, {{"LeftControl", "LeftShift", "P"}})

local function editRoll()
    if not dep.dollycam.playing then dep.setRoll.toggleRollGui() end
end
previeweditroll:Clicked(editRoll)
createKeybind("Edit Roll", editRoll)

local function recallPoint()
    local selection = dep.Selection:Get()
    if not dep.dollycam.playing and #selection==1 then
        dep.dollycam.saveCam()
        local Camera = workspace.CurrentCamera
        --Camera.CameraType = Enum.CameraType.Scriptable
        Camera.FieldOfView = selection[1].FOV.Value
        Camera.CFrame = selection[1].CFrame * CFrame.Angles(0,0,math.rad(selection[1].Roll.Value))
    end
end
local function leavePoint()
    dep.dollycam.recallCam()
end
recallpoint:Pressed(recallPoint)
recallpoint:Released(leavePoint)

local function clearctrlbezier()
    if not dep.dollycam.playing then
        dep.dollycam.clearCtrl()
    end
end
resetcontrolpoints:Clicked(clearctrlbezier)
createKeybind("Reset Control Points", clearctrlbezier)

timescaleinput:Changed(function(newts)
    if tonumber(newts) then
        dep.timescale.timescale = newts
    end
end)

fovslider:Changed(function(newfov)
    workspace.CurrentCamera.FieldOfView = newfov
    if fovinput.Value ~= newfov then fovinput:SetValue(newfov) end
end)
fovinput:Changed(function(newfov)
    if tonumber(newfov) then
        workspace.CurrentCamera.FieldOfView = newfov
        if fovslider.Value ~= newfov then fovslider:SetValue(newfov) end
    end
end)

scrubpathslider:Changed(function(progress)
    if not dep.dollycam.playing then
        dep.dollycam.goToProgress(progress)
    end
end)
scrubpathslider:Pressed(function() dep.dollycam.saveCam() end)
scrubpathslider:Released(function() dep.dollycam.recallCam() end)

local function syncMAStl(value)
    if value == nil then value = syncmoontimeline.Value() end
    dep.dollycam.syncMAStl = value
end
syncmoontimeline:Clicked(function(value)
    if not dep.dollycam.playing then
        syncMAStl(value)
    end
end)
createKeybind("Toggle MAS Sync", syncMAStl)

local function matchMASkf(value)
    if value == nil then value = matchmoonkeyframe.Value() end
    dep.dollycam.matchMASkf = value
end
matchmoonkeyframe:Clicked(function(value)
    if not dep.dollycam.playing then
        matchMASkf(value)
    end
end)
createKeybind("Match MAS Keyframes", matchMASkf)

rollinput:Changed(function(newroll)
    if tonumber(newroll) then
        dep.setRoll.angle = newroll
    end
end)
dep.setRoll.inputbox = rollinput

tweentimeinput:Changed(function(newtween)
    if tonumber(newtween) then
        dep.dollycam.latesttweentime = newtween
    end
end)
dep.dollycam.latesttweentime = tweentimeinput.Value

pathinput:Changed(function(newpath)
    if dep.dollycam.currentPathValue == newpath then return end
    dep.dollycam.currentPathValue = newpath
    local newpathdir = dep.dollycam.unloadedPathsDir:FindFirstChild(newpath)
    if newpathdir then
        dep.dollycam.unloadPaths()
        dep.dollycam.loadPath(newpathdir)
        dep.dollycam.checkDir()
        dep.dollycam.renderPath()
        dep.HistoryService:SetWaypoint("Switched paths")
    end
end)
pathinput:DropdownToggled(function()
    dep.dollycam.reloadDropdown()
end)
dep.dollycam.dropdown = pathinput

interpolationinput:Changed(function(newinterp)
    dep.dollycam.interpMethod = newinterp
    dep.dollycam.renderPath()
    dep.HistoryService:SetWaypoint("Changed interpolation methods")
end)
dep.dollycam.interpMethod = interpolationinput.Value

lockcontrolpointscheckbox:Clicked(function(newvalue)
    dep.dollycam.lockctrlbezier = newvalue
end)

dep.dollycam.initialize()

--[["autoreorder":SetValueChangedFunction(function(newvalue)
    if not dep.dollycam.playing then
        dep.dollycam.allowReorder = newvalue
        dep.dollycam.renamePoints()
    end
end)]]

plugin.Unloading:Connect(function()
    dep.util.mvmprint("Unloading Plugin")
    dep.util.clearConnections()
    plugin:SetSetting("rblxdolly saved keybinds", savedkeybinds)
end)

dep.util.mvmprint("Finished Loading")