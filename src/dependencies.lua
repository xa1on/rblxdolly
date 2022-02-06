local m = {}

-- gets services
m.HistoryService = game:GetService("ChangeHistoryService")
m.Selection = game:GetService("Selection")
m.RepStorage = game:GetService("ReplicatedFirst")
m.CoreGui = game:GetService("CoreGui")
m.RunService = game:GetService("RunService")


m.moduledir = script.Parent.modules

m.dollycam = require(m.moduledir.dollycam)
m.setRoll = require(m.moduledir.setRoll)
m.interp = require(m.moduledir.interpolation)
m.util = require(m.moduledir.util)

return m