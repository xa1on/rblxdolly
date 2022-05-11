local m = {}

-- gets services
m.HistoryService = game:GetService("ChangeHistoryService")
m.Selection = game:GetService("Selection")
m.RepStorage = game:GetService("ReplicatedFirst")
m.CoreGui = game:GetService("CoreGui")
m.RunService = game:GetService("RunService")


m.moduledir = script.Parent.modules
m.dollydir = m.moduledir.dollycam

m.util = require(m.moduledir.util)

m.dollycam = require(m.dollydir.dollycam)
m.setRoll = require(m.dollydir.setRoll)
m.interp = require(m.dollydir.interpolation)
m.timescale = require(m.dollydir.timescale)

return m