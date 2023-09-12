local m = {}
local inputService = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local util = require(script.Parent.Parent.util)

m.inputbox = nil

local colors = {
	black = Color3.new(0, 0, 0);
	grey = Color3.new(.5, .5, .5);
	white = Color3.new(1, 1, 1);
	red = Color3.new(1, .25, .25);
	green = Color3.new(.25, 1, .25);
	blue = Color3.new(.25, .25, 1);
}

local gui_roll = Instance.new("ScreenGui", coreGui)
gui_roll.Name = "ROLLGUI"
local tb_roll = Instance.new("TextButton", gui_roll)
    m.roll_active = false
    tb_roll.Visible = false
    tb_roll.Size = UDim2.new(1, 2, 0, 51)
    tb_roll.Position = UDim2.new(0, -1, 0, -1)
    tb_roll.AutoButtonColor = false
    tb_roll.BorderSizePixel = 0
    tb_roll.Text = "Click and drag over this box or use scroll wheel to set Camera roll. Right click to reset"
    tb_roll.BackgroundColor3 = colors.black
    tb_roll.TextColor3 = colors.white
    tb_roll.BackgroundTransparency = .2
    tb_roll.TextStrokeTransparency = 0
    tb_roll.TextStrokeColor3 = colors.black
local tb = Instance.new("TextBox", tb_roll)
    tb.Size = UDim2.new(0, 40, 0, 18)
    tb.Position = UDim2.new(.5, -20, 1, 0)
    tb.ClearTextOnFocus = true
    tb.BorderSizePixel = 0
    tb.Text = "0"
    tb.BackgroundColor3 = colors.black
    tb.TextColor3 = colors.white
    tb.BackgroundTransparency = .2
    tb.TextStrokeTransparency = 0
    tb.TextStrokeColor3 = colors.black

m.holding = false
m.curr_angle = 0
m.angle = 0

function m.updateTextBoxAngle()
	m.angle = math.floor(math.deg(m.curr_angle) + .5)
	tb.Text = m.angle
    m.inputbox:SetValue(m.angle)
end

function m.setCamRot(r)
	m.cam = workspace.CurrentCamera
    m.cam.CFrame = util.setCFRoll(m.cam.CFrame, r)
end

tb.FocusLost:Connect(function()
	m.n = tonumber(tb.Text)
	if not m.n then m.setCamRot(m.curr_angle) m.updateTextBoxAngle() return end
	m.angle = math.rad(tb.Text)
	m.setCamRot(m.angle)
	m.curr_angle = m.angle
	m.updateTextBoxAngle()
end)

function m.getAngleFromX(x)
	m.w = tb_roll.AbsoluteSize.X + 1
	return (x / m.w - .5) * 720
end

tb_roll.MouseMoved:Connect(function(x)
	if m.holding then
		m.angle = m.getAngleFromX(x)
		m.setCamRot(math.rad(m.angle))
		m.curr_angle = math.rad(m.angle)
		m.updateTextBoxAngle()
	end
end)

tb_roll.MouseButton2Down:Connect(function()
	m.setCamRot(0)
	m.curr_angle = 0
	m.updateTextBoxAngle()
end)

tb_roll.MouseButton1Down:Connect(function()
	if not m.roll_active then return end
	m.holding = true
end)

local function stopDrag()
	m.holding = false
end

util.appendConnection(tb_roll.MouseButton1Up:Connect(stopDrag))
util.appendConnection(tb_roll.MouseEnter:Connect(stopDrag))
util.appendConnection(tb_roll.MouseLeave:Connect(stopDrag))

function m.toggleRollGui()
	m.roll_active = not m.roll_active
	tb_roll.Visible = m.roll_active
	if not m.roll_active then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    elseif m.angle then
        m.setCamRot(math.rad(m.angle))
    end
end

function m.setRollTo(r)
    m.setCamRot(math.rad(r))
    m.curr_angle = math.rad(r)
    m.updateTextBoxAngle()
end

function m.updateRoll(r)
    m.curr_angle = math.rad(r)
    m.updateTextBoxAngle()
end

util.appendConnection(inputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel and m.roll_active == true then
        m.setRollTo(m.angle+(input.Position.Z)*2)
    end
end))

return m