local TextService = game:GetService("TextService")
local NoticePopup = {}
NoticePopup.__index = NoticePopup

function NoticePopup.new(Text, Parent, Action, CloseOnPress)
    local self = {}
    setmetatable(self, NoticePopup)
    self.Text = Text
    local Button = Instance.new("TextButton", Parent)
    Button.Name = "NoticePopup"
    Button.AnchorPoint = Vector2.new(0.5, 0.5)
    Button.BackgroundColor3 = Color3.new(46/255, 46/255, 46/255)
    Button.BackgroundTransparency = 0.3
    Button.Position = UDim2.fromScale(0.5,0.5)
    Button.TextColor3 = Color3.new(1, 1, 1);
    Button.Text = Text
    Button.RichText = true
    Button.TextSize = 20
    Button.Font = Enum.Font.SourceSans
    self.Button = Button
    self:MatchTextSize()
    self.Action = Action
    Button.MouseButton1Click:Connect(function()
        if Action then Action() end
        if CloseOnPress then self:Close() end
    end)
    return self
end

function NoticePopup:MatchTextSize()
    local bounds = self.Button.TextBounds
    self.Button.Size = UDim2.fromOffset(bounds.X + 170, bounds.Y + 60)
end

function NoticePopup:SetText(Text)
    self.Text = Text
    self.Button.Text = Text
end

function NoticePopup:Close()
    self.Button:Destroy()
    self = nil
end

return NoticePopup