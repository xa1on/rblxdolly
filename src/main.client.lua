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

if game:GetService("RunService"):IsRunning() then
    local dep = require(script.Parent.dependencies)
    dep.dollycam.hideRender()
    return
end

print("\n" ..
"       ____________ _     __   _____  ____   ____  ___\n" ..
"       | ___ \\ ___ \\ |    \\ \\ / /|  \\/  | | | |  \\/  |\n" ..
"       | |_/ / |_/ / |     \\ V / | .  . | | | | .  . |\n" ..
"       |    /| ___ \\ |     /   \\ | |\\/| | | | | |\\/| |\n" ..
"       | |\\ \\| |_/ / |____/ /^\\ \\| |  | \\ \\_/ / |  | |\n" ..
"       \\_| \\_\\____/\\_____/\\/   \\/\\_|  |_/\\___/\\_|  |_/\n" .. 
"\n\n                   [xalon / something786]\n")

local version = "0.5.13"
local newestversion
local outofdate = false

-- version check
pcall(function()
    local plugindesc = game:GetService("MarketplaceService"):GetProductInfo(9657949764).Description
    if plugindesc then
        local _, versionstr = string.find(plugindesc, "version: ")
        if versionstr then
            newestversion = string.sub(plugindesc, versionstr + 1)
            outofdate = newestversion ~= version
        end
    end
end)

local HttpService = game:GetService("HttpService")

local moduledir = script.Parent.modules
local gui = require(moduledir.rblxgui.initialize)(plugin, "RBLXDOLLY")

local settingobjs = {}
local savedsettings = plugin:GetSetting("rblxdolly saved settings") or {}
local function restoreSettings()
    for i, v in pairs(savedsettings) do
        if settingobjs[i] ~= nil then settingobjs[i]:SetValue(v) end
    end
end

local function saveSettings()
    savedsettings = {}
    for i, v in pairs(settingobjs) do
        if v.Input ~= nil then
            savedsettings[i] = {Name = v.Input.Text, Value = v.Value}
        else
            savedsettings[i] = v.Value
        end
    end
    plugin:SetSetting("rblxdolly saved settings", savedsettings)
end

-- toolbar
local toolbarname = "RBLXDOLLY - v" .. version
if outofdate then toolbarname = "RBLXDOLLY - Update available" end
local toolbar = plugin:CreateToolbar(toolbarname)

local widgettitle = "RBLXDOLLY v" .. version .. " - " .. game:GetService("Players"):GetNameFromUserIdAsync(game:GetService("StudioService"):GetUserId())
if outofdate then widgettitle = "RBLXDOLLY - Update available" end
local widget = gui.PluginWidget.new({ID = "rblxdolly", Enabled = false, DockState = Enum.InitialDockState.Left, Title = widgettitle})

local b_toggle = toolbar:CreateButton("Toggle","Toggle widget","")
b_toggle.Click:Connect(function() widget.Content.Enabled = not widget.Content.Enabled end)

local mainpage = gui.Page.new({
    Name = "MAIN",
    TitlebarMenu = widget.TitlebarMenu,
    Open = true
})

local filemenu = plugin:CreatePluginMenu(HttpService:GenerateGUID(false), "File Menu")
filemenu.Name = "File Menu"
local scriptExportAction = filemenu:AddNewAction("ScriptExport", "Export as Script")
local cam3DExportAction = filemenu:AddNewAction("3DExport", "Export as After Effects 3D Camera")

local filemenubutton = gui.TitlebarButton.new({
    Name = "FILE",
    PluginMenu = filemenu
})

gui.ViewButton.new()

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

gui.ListFrame.new({Height = 15})

local pathoptions = gui.Section.new({Text = "Path Options", Open = true})
pathoptions:SetMain()

local pathinput = gui.InputField.new({Placeholder = "Path Name"})
local pathlabel = gui.Labeled.new({Text = "Path", LabelSize = UDim.new(0,85), Object = pathinput})

local interpolationinput = gui.InputField.new({CurrentItem = {Name = "Cubic Curve", Value = "cubicInterp"}, Items = {{Name = "Manual Curve", Value = "bezierInterp"}, {Name = "Linear", Value = "linearInterp"}, {Name = "Cubic Curve", Value = "cubicInterp"}}, DisableEditing = true})
settingobjs.interpolationinput = interpolationinput
gui.Labeled.new({Text = "Interpolation", LabelSize = UDim.new(0,85), Object = interpolationinput})

local timescaleinput = gui.InputField.new({Placeholder = "Timescale Value", Value = 1, NoDropdown = true})
local timescalelabel = gui.Labeled.new({Text = "Timescale", LabelSize = UDim.new(0,85), Object = timescaleinput})

local delayinput = gui.InputField.new({Placeholder = "Delay (in seconds)", Value = 0, NoDropdown = true})
local delaylabel = gui.Labeled.new({Text = "Delay", LabelSize = UDim.new(0, 86), Object = delayinput})

gui.ListFrame.new({Height = 5})

local cubicoptions = gui.Section.new({Text = "Cubic Interpolation Options", Open = false})
cubicoptions:SetMain()

local tensioninput = gui.InputField.new({Placeholder = "Tension Value", NoDropdown = true, Value = 0})
local tensionslider = gui.Slider.new({Min = -3, Max = 1, Increment = 0.01, Value = 0})
local tensionlabel = gui.Labeled.new({Text = "Cubic Tension", LabelSize = UDim.new(0,85), Disabled = true, Objects = {{Object = tensioninput, Name = "input", Size = UDim.new(0.3,0)}, {Object = tensionslider, Name = "slider"}}})
settingobjs.tensioninput = tensioninput
settingobjs.tensionslider = tensionslider

local alphainput = gui.InputField.new({Placeholder = "Alpha Value", NoDropdown = true, Value = 0})
local alphaslider = gui.Slider.new({Min = 0, Max = 1, Increment = 0.01, Value = 0})
local alphalabel = gui.Labeled.new({Text = "Cubic Alpha", LabelSize = UDim.new(0,85), Disabled = true, Objects = {{Object = alphainput, Name = "input", Size = UDim.new(0.3,0)}, {Object = alphaslider, Name = "slider"}}})
settingobjs.alphainput = alphainput
settingobjs.alphaslider = alphaslider

pathoptions:SetMain()

local scrubpathslider = gui.Slider.new({Min = 0, Max = 1})
gui.Labeled.new({Text = "Scrub Path", LabelSize = UDim.new(0, 85), Object = scrubpathslider})

gui.ListFrame.new({Height = 5})

local startstopplayback = gui.Button.new({Text = "Start/Stop Playback", ButtonSize = 0.5})

local resetcontrolpoints = gui.Button.new({Text = "Reset All Control Points", ButtonSize = 0.55})

gui.ListFrame.new({Height = 5})

local moonPathSection = gui.Section.new({Text = "Moon Animator (MAS)", Open = false})
moonPathSection:SetMain()

gui.ListFrame.new({Height = 5})

local createMoonDollycam = gui.Button.new({Text = "Create Moon Dollycam"})

local scaleMASpathtotl = gui.Button.new({Text = "Scale Path To Moon Timeline Length"})

gui.ListFrame.new({Height = 5})

pathoptions:SetMain()

local pointoptions = gui.Section.new({Text = "Point Options", Open = true}, mainpageframe.Content)
pointoptions:SetMain()

-- AKA tweentime
local tweentimeinput = gui.InputField.new({Placeholder = "Transition Time Value", Value = 2.5, NoDropdown = true})
local tweentimelabel = gui.Labeled.new({Text = "Transition Time", LabelSize = UDim.new(0,85), Object = tweentimeinput})

local fovinput = gui.InputField.new({Placeholder = "FOV Value", Value = math.round(workspace.CurrentCamera.FieldOfView), NoDropdown = true})
local fovslider = gui.Slider.new({Min = 0, Max = 120, Increment = 1, Value = math.round(workspace.CurrentCamera.FieldOfView)})
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

local rendersettings = gui.Section.new({Text = "Render", Open = true}, settingsframe.Content)
rendersettings:SetMain()

local renderpathcheckbox = gui.Checkbox.new({Value = true})
settingobjs.renderpathcheckbox = renderpathcheckbox
gui.Labeled.new({Text = "Render Path Visual", LabelSize = UDim.new(0.35, 0), Object = renderpathcheckbox})

local forcerenderbutton = gui.Button.new({Text = "Force Re-render", ButtonSize = 0.55})

local dollycamsettings = gui.Section.new({Text = "Dollycam", Open = true}, settingsframe.Content)
dollycamsettings:SetMain()

local lockcontrolpoints = gui.Checkbox.new({Value = true})
settingobjs.lockcontrolpoints = lockcontrolpoints
gui.Labeled.new({Text = "Lock Control Points", LabelSize = UDim.new(0.35, 0), Object = lockcontrolpoints})

local playbacksettings = gui.Section.new({Text = "Playback", Open = true}, settingsframe.Content)
playbacksettings:SetMain()

local framebasedprev = gui.Checkbox.new({Value = true})
settingobjs.framebasedprev = framebasedprev
gui.Labeled.new({Text = "Frame-based Preview", LabelSize = UDim.new(0.35, 0), Object = framebasedprev})

local framebasedfps = gui.InputField.new({Placeholder = "Roll Value", Value = 60, NoDropdown = true})
settingobjs.framebasedfps = framebasedfps
gui.Labeled.new({Text = "Frame-based FPS", LabelSize = UDim.new(0.5,0), Object = framebasedfps})

local MASsettings = gui.Section.new({Text = "Moon Animator (MAS)", Open = true}, settingsframe.Content)
MASsettings:SetMain()

local syncmoontimeline = gui.Checkbox.new({Value = false})
settingobjs.syncmoontimeline = syncmoontimeline
local lsyncMASTLgui = gui.Labeled.new({Text = "Sync Timelines", LabelSize = UDim.new(0.35, 0), Object = syncmoontimeline})

local synctimelineonplay = gui.Checkbox.new({Value = true})
settingobjs.synctimelineonplay = synctimelineonplay
local syncMASTLonplay = gui.Labeled.new({Text = "Sync Timeline on Play", LabelSize = UDim.new(0.35, 0), Object = synctimelineonplay})

local scaletoMASTLlength = gui.Checkbox.new({Value = false})
settingobjs.scaletoMASTLlength = scaletoMASTLlength
local lscaletoMASTLlength = gui.Labeled.new({Text = "Auto Scale Path to Timeline", LabelSize = UDim.new(0.35,0), Object = scaletoMASTLlength})

local autoDockMAS = gui.Checkbox.new({Value = true})
settingobjs.autoDockMAS = autoDockMAS
local lautoDockMAS = gui.Labeled.new({Text = "Auto Dock MAS Camera", LabelSize = UDim.new(0.35,0), Object = autoDockMAS})

if not _G.MoonGlobal then
    lsyncMASTLgui:SetDisabled(true)
    syncmoontimeline:SetValue(false)
    lscaletoMASTLlength:SetDisabled(true)
    scaletoMASTLlength:SetValue(false)
    scaleMASpathtotl:SetDisabled(true)
    createMoonDollycam:SetDisabled(true)
    lautoDockMAS:SetDisabled(true)
    synctimelineonplay:SetDisabled(true)
end

local keybindsection = gui.Section.new({Text = "Keybinds", Open = true}, settingsframe.Content)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end


local savedkeybinds = plugin:GetSetting("rblxdolly saved keybinds") or {}
local function createKeybind(title, paction, default, binds, raction, holdable, unrestricted)
    if savedkeybinds[title] and type(savedkeybinds[title]) == "table" then default = savedkeybinds[title] end
    local newkeybind = gui.KeybindInputField.new({PressedAction = paction, ReleasedAction = raction, CurrentBind = default, Binds = binds, Holdable = holdable, Unrestricted = unrestricted})
    gui.Labeled.new({Text = title, LabelSize = 0.5, Object = newkeybind}, gui.ListFrame.new(nil, keybindsection.Content).Content)
    newkeybind:Changed(function(p)
        savedkeybinds[title] = p
    end)
end

createKeybind("Toggle Widget", function() widget.Content.Enabled = not widget.Content.Enabled end, {{"LeftControl", "LeftShift", "T"}})

settingsframe:SetMain()

gui.ListFrame.new({Height = 5})

gui.Textbox.new({
    Text = "Current version: v" .. version,
    Alignment = Enum.TextXAlignment.Center,
    TextSize = 12
})

local dep = require(script.Parent.dependencies)

local function toggleMoonSync(on)
    pathlabel:SetDisabled(on)
    timescalelabel:SetDisabled(on)
    delaylabel:SetDisabled(on)
    tweentimelabel:SetDisabled(on)
    scaleMASpathtotl:SetDisabled(on)
    resetcontrolpoints:SetDisabled(on)
    --dep.dollycam.hideRender(not on)
    if on then
        if interpolationinput.Value == "bezierInterp" then
            interpolationinput:SetValue({Name = "Cubic Curve", Value = "cubicInterp"})
        end
        delayinput:SetValue(0)
        interpolationinput:RemoveItem("Manual Curve")
    else
        interpolationinput:AddItem({Name = "Manual Curve", Value = "bezierInterp"})
    end
end

restoreSettings()

dep.dollycam.interpMethod = interpolationinput.Value
dep.dollycam.dropdown = pathinput
dep.dollycam.latesttweentime = tweentimeinput.Value
dep.dollycam.tsinput = timescaleinput
dep.dollycam.framebased = framebasedprev.Value
dep.dollycam.framebasedfps = framebasedfps.Value
dep.dollycam.scaleMAStl = scaletoMASTLlength.Value
dep.dollycam.syncMAStl = syncmoontimeline.Value
dep.dollycam.syncMAStlonplay = synctimelineonplay.Value
dep.dollycam.toggleMoonSync = toggleMoonSync
dep.dollycam.autoDockMAS = autoDockMAS.Value
dep.dollycam.renderVisual = renderpathcheckbox.Value


local function exportScript()
    dep.dollycam.createPlaybackScript()
    dep.HistoryService:SetWaypoint("Exported as Script")
end
createKeybind("Export Playback Script", exportScript)

local function exportAs3D()

end
createKeybind("Export AE 3D Camera", exportAs3D)

dep.util.appendConnection(scriptExportAction.Triggered:Connect(exportScript))
dep.util.appendConnection(cam3DExportAction.Triggered:Connect(exportAs3D))

local function createPoint()
    if not dep.dollycam.playing then
        dep.dollycam.createPoint()
    end
    dep.HistoryService:SetWaypoint("Created Point")
end
createpoint:Clicked(createPoint)
createKeybind("Create Point", createPoint, {{"P"}})

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

createMoonDollycam:Clicked(dep.dollycam.createMoonDollycam)
createKeybind("Create Moon Dollycam")

local function scaleMASpath()
    if dep.dollycam.playing then return end
    dep.dollycam.scaleTLTween()
end
scaleMASpathtotl:Clicked(scaleMASpath)
createKeybind("Moon Timeline Scale", scaleMASpath)

tensioninput:Changed(function(newtension)
    if dep.interp.tension == newtension then return end
    if not tonumber(newtension) then return end
    dep.interp.tension = newtension
    dep.dollycam.renderPath()
    if tensionslider.Value ~= newtension then tensionslider:SetValue(newtension) end
end)

tensionslider:Changed(function(newtension)
    if dep.interp.tension == newtension then return end
    dep.interp.tension = newtension
    dep.dollycam.renderPath()
    if tensioninput.Value ~= newtension then tensioninput:SetValue(newtension) end
end)

alphainput:Changed(function(newalpha)
    if dep.interp.alpha == newalpha then return end
    if not tonumber(newalpha) then return end
    dep.interp.alpha = newalpha
    dep.dollycam.renderPath()
    if alphaslider.Value ~= newalpha then alphaslider:SetValue(newalpha) end
end)

alphaslider:Changed(function(newalpha)
    if dep.interp.alpha == newalpha then return end
    dep.interp.alpha = newalpha
    dep.dollycam.renderPath()
    if alphainput.Value ~= newalpha then alphainput:SetValue(newalpha) end
end)

timescaleinput:Changed(function(newts)
    if tonumber(newts) then
        dep.timescale.timescale = newts
    end
end)

delayinput:Changed(function(newdelay)
    if tonumber(newdelay) then
        dep.dollycam.delay = tonumber(newdelay)
    end
end)

fovslider:Changed(function(newfov)
    if fovinput.Value ~= newfov then fovinput:SetValue(newfov) end
    workspace.CurrentCamera.FieldOfView = newfov
end)
fovinput:Changed(function(newfov)
    if tonumber(newfov) then
        workspace.CurrentCamera.FieldOfView = newfov
        if fovslider.Value ~= newfov then fovslider:SetValue(newfov) end
    end
end)
dep.util.appendConnection(workspace.CurrentCamera.Changed:Connect(function(p)
    if p == "FieldOfView" then
        fovinput:SetValue(workspace.CurrentCamera.FieldOfView)
        fovslider:SetValue(workspace.CurrentCamera.FieldOfView)
    end
end))

scrubpathslider:Changed(function(progress)
    if not dep.dollycam.playing then
        dep.dollycam.goToProgress(progress, true)
    end
end)
scrubpathslider:Pressed(function() dep.dollycam.saveCam() end)
scrubpathslider:Released(function() dep.dollycam.recallCam() end)

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

pathinput:LostFocus(dep.dollycam.pathChange)
pathinput:Changed(function(p)
    if not pathinput.Input:IsFocused() then dep.dollycam.pathChange(p) end
end)
pathinput:DropdownToggled(function()
    dep.dollycam.reloadDropdown()
end)

local function interpUpdate(newinterp)
    if newinterp == nil then newinterp = interpolationinput.Value end
    dep.dollycam.interpMethod = newinterp
    if newinterp == "cubicInterp" then
        tensionlabel:SetDisabled(false)
        alphalabel:SetDisabled(false)
    else
        alphalabel:SetDisabled(true)
        tensionlabel:SetDisabled(true)
    end
    if newinterp == "bezierInterp" and dep.dollycam.useMoonCam then
        interpolationinput:SetValue({Name = "Cubic Curve", Value = "cubicInterp"})
    end
    dep.dollycam.renderPath()
end

interpolationinput:Changed(function(newinterp)
    interpUpdate(newinterp)
    dep.HistoryService:SetWaypoint("Changed interpolation methods")
end)

lockcontrolpoints:Clicked(function(newvalue)
    dep.dollycam.lockctrlbezier = newvalue
end)

local function renderpathtoggle(value)
    if value == nil then value = dep.dollycam.renderVisual end
    dep.dollycam.renderVisual = value
    dep.dollycam.hideRender(value)
    if value then
        dep.dollycam.renderPath()
    end
end
renderpathcheckbox:Clicked(function(value)
    renderpathtoggle(value)
end)

local function forcerender()
    dep.dollycam.renderPath()
end
forcerenderbutton:Clicked(forcerender)
createKeybind("Force Re-render", forcerender)

local function framebasedprevtoggle(newvalue)
    if newvalue == nil then newvalue = dep.dollycam.framebased end
    dep.dollycam.framebased = newvalue
    framebasedfps:SetDisabled(not newvalue)
end
framebasedprevtoggle()

framebasedprev:Clicked(function(newvalue)
    framebasedprevtoggle(newvalue)
end)

framebasedfps:Changed(function(newvalue)
    dep.dollycam.framebasedfps = newvalue
end)

local function syncMAStl(value)
    if value == nil and not syncmoontimeline.Disabled then
        value = not syncmoontimeline.Value
        syncmoontimeline:SetValue(value)
    end
    dep.dollycam.syncMAStl = value
end
local function toggleMAStl()
    if syncmoontimeline.Disabled or not syncmoontimeline.Value then
        dep.dollycam.syncMAStl = not dep.dollycam.syncMAStl
    end
end
syncmoontimeline:Clicked(function(value)
    if not dep.dollycam.playing then
        syncMAStl(value)
    end
end)
createKeybind("Moon Timeline Sync", toggleMAStl, {{"LeftShift"}}, {{"LeftShift"}}, toggleMAStl, true, true)
createKeybind("Toggle MAS TL Sync", syncMAStl)

local function syncMAStlonplay(value)
    if value == nil and not synctimelineonplay.Disabled then
        value = not synctimelineonplay.Value
        synctimelineonplay:SetValue(value)
    end
    dep.dollycam.syncMAStlonplay = value
end
synctimelineonplay:Clicked(syncMAStlonplay)
createKeybind("Toggle Sync On Playback", syncMAStlonplay)

local function scaleMASTLlength(value)
    if value == nil then
        value = not scaletoMASTLlength.Value
        scaletoMASTLlength:SetValue(value)
    end
    dep.dollycam.scaleMAStl = value
    timescalelabel:SetDisabled(value)
    if value then dep.dollycam.scaleTL() end
end
scaletoMASTLlength:Clicked(function(value)
    if not dep.dollycam.playing then
        scaleMASTLlength(value)
    end
end)
createKeybind("Toggle MAS TL Auto-Scale", scaleMASTLlength)

local function fautoDockMAS(value)
    if value == nil then
        value = not autoDockMAS.Value
        autoDockMAS:SetValue(value)
    end
    dep.dollycam.autoDockMAS = value
end
autoDockMAS:Clicked(function(value)
    if not dep.dollycam.playing then
        fautoDockMAS(value)
    end
end)




if dep.dollycam.initialize() then
    interpUpdate()
    scaleMASTLlength(scaletoMASTLlength.Value)
end
dep.dollycam.hideRender(true)


--[["autoreorder":SetValueChangedFunction(function(newvalue)
    if not dep.dollycam.playing then
        dep.dollycam.allowReorder = newvalue
        dep.dollycam.renamePoints()
    end
end)]]

dep.util.appendConnection(plugin.Unloading:Connect(function()
    dep.util.mvmprint("Unloading Plugin")
    local coreGui = game:GetService("CoreGui")
    coreGui:FindFirstChild("ROLLGUI"):Destroy()
    dep.dollycam.hideRender()
    dep.util.clearConnections()
    plugin:SetSetting("rblxdolly saved keybinds", savedkeybinds)
    saveSettings()
end))

if outofdate then
    dep.util.mvmprint("OUT OF DATE - Version: " .. version .. " -> " .. newestversion)
else
    dep.util.mvmprint("Version: " .. version)
end

dep.util.mvmprint("Finished Loading")

--task.wait(5)
--gui.GUIUtil.DumpGUI(widget.Content)