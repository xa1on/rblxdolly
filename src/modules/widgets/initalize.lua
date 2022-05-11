local wdglib = require(script.Parent.require)()

local m = {}

m.InterpMethods = {
    {"linear", "linearInterp", "linear"},
    {"cubic", "cubicInterp", "cubic"},
    {"manual bezier", "bezierInterp", "bezier"}
}

m.InterpDefault = "bezier"

function m:GenerateWidget(widget)
	local bgframe = Instance.new("Frame")
	bgframe.Parent = widget
	bgframe.Size = UDim2.new(1,0,1,0)
	wdglib.GuiUtilities.syncGuiElementBackgroundColor(bgframe)
    m.scrollFrame = wdglib.VerticalScrollingFrame.new("sframe")
    m.listFrame = wdglib.VerticallyScalingListFrame.new("lframe")


    -- dollycam
    m.dollycamcollapse = wdglib.CollapsibleTitledSection.new("dollycam", "Dollycam", true, true, false)
    m.listFrame:AddChild(m.dollycamcollapse:GetSectionFrame())
    
    m.pathDropdown = wdglib.DropdownMenu.new("pathDropdown", "Paths", {})
    m.pathDropdown:GetSectionFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.pathNameInput = wdglib.LabeledTextInput.new("pathNameInput", "Path Name")
    m.pathNameInput:SetMaxGraphemes(30)
    m.pathNameInput:GetFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.createPoint = wdglib.CustomTextButton.new("createPoint", "Create Point"):GetButton()
    m.createPoint.Size = UDim2.new(0, 100, 0, 25)
    m.createPoint.Parent = m.dollycamcollapse:GetContentsFrame()

    m.timescaleInput = wdglib.LabeledTextInput.new("timescaleInput", "Timescale", "1")
    m.timescaleInput:SetMaxGraphemes(10)
    m.timescaleInput:GetFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.fovInputSlider = wdglib.LabeledSlider.new("fovInputSlider", "FOV", 120, 1)
    m.fovInputSlider:SetValue(math.round(workspace.CurrentCamera.FieldOfView))
    m.fovInputSlider:GetFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.fovInput = wdglib.LabeledTextInput.new("fovInput", "", math.round(workspace.CurrentCamera.FieldOfView))
    m.fovInput:SetMaxGraphemes(3)
    m.fovInput:GetFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.editRoll = wdglib.CustomTextButton.new("editRoll", "Edit Roll"):GetButton()
    m.editRoll.Size = UDim2.new(0, 80, 0, 25)
    m.editRoll.Parent = m.dollycamcollapse:GetContentsFrame()

    m.rollInput = wdglib.LabeledTextInput.new("rollInput", "Secondary Roll", "0")
    m.rollInput:SetMaxGraphemes(10)
    m.rollInput:GetFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.interpDropdown = wdglib.DropdownMenu.new("interpDropdown", "Interpolation", m.InterpMethods, m.InterpDefault)
    m.interpDropdown:GetSectionFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.stopPath = wdglib.CustomTextButton.new("stopPath", "Stop Playback"):GetButton()
    m.stopPath.Size = UDim2.new(1, 0, 0, 25)
    m.stopPath.Parent = m.dollycamcollapse:GetContentsFrame()

    m.runPath = wdglib.CustomTextButton.new("runPath", "Playback Path"):GetButton()
    m.runPath.Size = UDim2.new(1, 0, 0, 30)
    m.runPath.Parent = m.dollycamcollapse:GetContentsFrame()

    m.pointsettingscollapse = wdglib.CollapsibleTitledSection.new("pointsettingscollapse", "Point Options", true, true, false)
    m.pointsettingscollapse:GetSectionFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    --m.autoreorder = wdglib.LabeledCheckbox.new("autoreorder", "Auto Point Ordering", true, false)
    --m.autoreorder:GetFrame().Parent = m.pointsettingscollapse:GetContentsFrame()

    m.lockctrlbezier = wdglib.LabeledCheckbox.new("lockctrlbezier", "Lock Control Points", true, false)
    m.lockctrlbezier:GetFrame().Parent = m.pointsettingscollapse:GetContentsFrame()

    m.clearctrlbezier = wdglib.CustomTextButton.new("clearctrlbezier", "Reset Control Points"):GetButton()
    m.clearctrlbezier.Size = UDim2.new(1, 0, 0, 25)
    m.clearctrlbezier.Parent = m.pointsettingscollapse:GetContentsFrame()






    m.cinepasscollapse = wdglib.CollapsibleTitledSection.new("cinepass", "Passes", true, true, true)
    m.cinepasscollapse:GetSectionFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    -- lighting
    m.lightingcollapse = wdglib.CollapsibleTitledSection.new("lighting", "Lighting", true, true, true)
    m.listFrame:AddChild(m.lightingcollapse:GetSectionFrame())


    -- poses
    m.posetoolcollapse = wdglib.CollapsibleTitledSection.new("posetool", "Posing", true, true, true)
    m.listFrame:AddChild(m.posetoolcollapse:GetSectionFrame())


    -- weapons & skins
    m.camotoolcollapse = wdglib.CollapsibleTitledSection.new("camotool", "Weapons & Camos", true, true, true)
    m.listFrame:AddChild(m.camotoolcollapse:GetSectionFrame())

    -- settings
    m.settingscollapse = wdglib.CollapsibleTitledSection.new("settings", "Settings", true, true, false)
    m.listFrame:AddChild(m.settingscollapse:GetSectionFrame())


    -- dev settings
    m.devsettingscollapse = wdglib.CollapsibleTitledSection.new("devsettings", "Developer Settings", true, true, true)
    m.listFrame:AddChild(m.devsettingscollapse:GetSectionFrame())

    m.disconnect = wdglib.CustomTextButton.new("disconnect", "Disconnect (Warning: disables the plugin)"):GetButton()
    m.disconnect.Size = UDim2.new(1, 0, 0, 25)
    m.disconnect.Parent = m.devsettingscollapse:GetContentsFrame()


    m.listFrame:AddBottomPadding()
    m.listFrame:GetFrame().Parent = m.scrollFrame:GetContentsFrame()
    m.scrollFrame:GetSectionFrame().Parent = widget
end

return m