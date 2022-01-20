local m = {}

-- gets services
m.HistoryService = game:GetService("ChangeHistoryService")
m.Selection = game:GetService("Selection")
m.RepStorage = game:GetService("ReplicatedFirst")
m.coreGui = game:GetService("CoreGui")

m.moduledir = script.Parent.modules

m.dollycam = require(m.moduledir.dollycam)
m.setRoll = require(m.moduledir.setRoll)

return m