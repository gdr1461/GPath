local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local Utils = script.Utils
local Types = require(Utils.Types)

local NewPathfind = require(script.PathFind)
local GSignal = require(Utils.GSignal)
local GCleaner = require(Utils.GCleaner)

local Proxy = newproxy(true)
local GPath: Types.GPathProxy = getmetatable(Proxy)

GPath.__type = "GPath"
GPath.__version = "v0.3.0"

GPath.__metatable = "[GPath]: Metatable methods are restricted."
GPath.__Paths = {}
GPath.__Bin = Instance.new("Folder")

function GPath:__tostring()
	return self.__type, self.__version
end

function GPath:__index(Key)
	return GPath[Key]
end

function GPath:__newindex(Key, Value)
	GPath[Key] = Value
	return Value
end

function GPath:Create(Character)
	local self = setmetatable({}, NewPathfind)
	GPath.__Paths[Character.Name] = self
	
	self.__Cleaner = GCleaner.New()
	self.__Path = self.__Cleaner:Task(PathfindingService:CreatePath(self.Agent))
	
	self.State = "Default"
	self.Visualise = false
	self.Model = Character
	
	self.NextPoint = nil
	self.Goal = nil
	self.FollowTime = 0
	
	self.Playing = false
	self.Following = nil
	
	self.Agent = self:Calculate()
	self.Points = {}
	
	self.Blocked = self.__Cleaner:Task(GSignal.new())
	self.StateChange = self.__Cleaner:Task(GSignal.new())
	
	self.Played = self.__Cleaner:Task(GSignal.new())
	self.Stopped = self.__Cleaner:Task(GSignal.new())
	
	self.PointReached = self.__Cleaner:Task(GSignal.new())
	self.OnPlay = self.__Cleaner:Task(GSignal.new())
	self.Expect = self.__Cleaner:Task(GSignal.new())
	
	local Connection1
	local Connection2
	
	Connection1 = Character.Destroying:Once(function()
		Connection1 = nil
		self:Destroy()
	end)
	
	Connection2 = Character:GetPropertyChangedSignal("Parent"):Connect(function()
		if Character.Parent then
			return
		end
		
		self:Destroy()
		Connection2:Disconnect()
		
		if not Connection1 then
			return
		end
		
		Connection1:Disconnect()
	end)
	
	GPath.__Bin = GPath.__Bin or Instance.new("Folder")
	GPath.__Bin.Name = "GPath_Bin"
	GPath.__Bin.Parent = workspace
	
	return self
end

return Proxy :: Types.GPathProxy
