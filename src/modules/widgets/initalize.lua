local wdglib = require(script.Parent.require)()

local m = {}

m.InterpMethods = {
    {"linear", "linearInterp", "linear"},
    {"cubic", "cubicInterp", "cubic"},
    {"manual bezier", "bezierInterp", "bezier"}
}

m.InterpDefault = "cubic"

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

    m.pathNameInput = wdglib.LabeledTextInput.new("pathNameInput", "Path Name", "Name")
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

    m.manualbeziercollapse = wdglib.CollapsibleTitledSection.new("manualbeziercollapse", "Manual Bezier Option", true, true, false)
    m.manualbeziercollapse:GetSectionFrame().Parent = m.dollycamcollapse:GetContentsFrame()

    m.automatectrlbezier = wdglib.LabeledCheckbox.new("automatectrlbezier", "Automate Bezier Path", true, false)
    m.automatectrlbezier:GetFrame().Parent = m.manualbeziercollapse:GetContentsFrame()

    m.lockctrlbezier = wdglib.LabeledCheckbox.new("lockctrlbezier", "Lock Control Points", true, false)
    m.lockctrlbezier:GetFrame().Parent = m.manualbeziercollapse:GetContentsFrame()

    m.normalizectrlbezier = wdglib.CustomTextButton.new("normalizectrlbezier", "Normalize Control Points"):GetButton()
    m.normalizectrlbezier.Size = UDim2.new(1, 0, 0, 25)
    m.normalizectrlbezier.Parent = m.manualbeziercollapse:GetContentsFrame()




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
    m.settingscollapse = wdglib.CollapsibleTitledSection.new("settings", "Settings", true, true, true)
    m.listFrame:AddChild(m.settingscollapse:GetSectionFrame())

    m.autoreorder = wdglib.LabeledCheckbox.new("autoreorder", "Auto Point Ordering", true, false)
    m.autoreorder:GetFrame().Parent = m.settingscollapse:GetContentsFrame()


    m.listFrame:AddBottomPadding()
    m.listFrame:GetFrame().Parent = m.scrollFrame:GetContentsFrame()
    m.scrollFrame:GetSectionFrame().Parent = widget
end

return m