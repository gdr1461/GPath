local Utils = script.Parent.Utils
local Types = require(Utils.Types)

local GetSize = require(Utils.GetSize)
local Data = require(Utils.Data)

local Path: Types.NewPath = {}
Path.__index = function(self, Key)
	local IndexChangeList = rawget(self, "__NewIndexChangeList")
	local IndexChange = rawget(self, "__NewIndexChange")
	
	rawset(self, "__NewIndexChangeList", IndexChangeList or {"State"})
	rawset(self, "__NewIndexChange", IndexChange or {})
	
	IndexChangeList = rawget(self, "__NewIndexChangeList")
	IndexChange = rawget(self, "__NewIndexChange")
	
	if table.find(IndexChangeList, Key) then
		return IndexChange[Key]
	end
	
	return rawget(Path, Key)
end

Path.__newindex = function(self, Key, Value)
	self.__NewIndexChangeList = self.__NewIndexChangeList or {"State"}
	self.__NewIndexChange = self.__NewIndexChange or {}
	
	if table.find(self.__NewIndexChangeList, Key) then
		if self.__NewIndexChange[Key] ~= Value and self[`{Key}Change`] then
			self[`{Key}Change`]:Fire(Value, self.__NewIndexChange[Key])
		end
		
		self.__NewIndexChange[Key] = Value
		return
	end
	
	rawset(self, Key, Value)
end

function Path:Follow(Part)
	if not Part or typeof(Part) ~= "Instance" or not Part:IsA("BasePart") then
		warn(`[GPath]: Follow Error :: {self.Model.Name} :: Invalid Part.`)
		self.Expect:Fire("Follow", `Invalid Part: {typeof(Part) ~= "Instance" and Part or Part.Name}; Type: {typeof(Part) ~= "Instance" and typeof(Part) or Part.ClassName};`)
		return
	end
	
	self.Following = Part
	self.State = "Following"
	
	local Connection
	Connection = {
		Object = false,
		Disconnect = function()
			self.Following = nil
			self.State = "Default"

			Connection.Object = true
			table.clear(Connection)
			Connection = nil
		end,
	}
	
	Part.Destroying:Once(function()
		Connection:Disconnect()
	end)
	
	local IsNear = false
	local Sent = false
	
	task.spawn(function()
		self.__FollowStart = tick()
		while Connection and Part and Part.Parent and self.Model and self.Model.Parent do
			if self.FollowTime > 0 and tick() - self.__FollowStart >= self.FollowTime then
				break
			end
			
			task.wait()
			if not self.Playing then
				continue
			end
			
			local Distance = (self.Model:GetPivot().Position - Part.Position).Magnitude
			IsNear = Distance <= 3
			
			if not IsNear and Sent then
				Sent = false
			end
			
			if IsNear and not Sent then
				Sent = true
				self.Played:Fire(Distance)
				continue
			end
			
			self:Compute()
			if not self.Model or not self.Model.Parent then
				break
			end
			
			self:Next()
			--Part:GetPropertyChangedSignal("Position"):Wait()
		end
		
		if Connection then 
			Connection:Disconnect()
		end
	end)
	
	return Connection
end

function Path:Play()
	if not self.Model or not self.Model.Parent then
		return
	end
	
	if self.Following then
		task.spawn(self.__Play, self)
		return
	end
	
	if self.Playing or #self.Points <= 0 then
		return
	end
	
	task.spawn(self.__Play, self)
end

function Path:Stop()
	if not self.Model or not self.Model.Parent or not self.Playing then
		return
	end
	
	self.Playing = false
	self.Stopped:Fire()
	self.State = self.Following and "Following" or "Default"
end

function Path:__Play()
	if not self.Model or not self.Model.Parent then
		return
	end
	
	self.Playing = true
	self.OnPlay:Fire()
	
	if self.Following then
		return
	end
	
	self.State = "Playing"
	local BlockedConnection
	local ReachedConnection
	
	BlockedConnection = self.__Path.Blocked:Once(function(Id)
		if Id < self.NextPoint then
			return
		end
		
		self.Blocked:Fire(Id)
		self:Compute(self.Goal)
		self:__Play()
	end)
	
	if not self.__ReachedConnection then
		self.__ReachedConnection = self.Model.Humanoid.MoveToFinished:Connect(function(Reached)
			if self.NextPoint >= #self.Points then
				BlockedConnection:Disconnect()
				self.Playing = false
				self.Played:Fire()
				
				self.State = "Default"
				self.NextPoint = nil
				return
			end
			
			if not Reached then
				BlockedConnection:Disconnect()
				warn(`[GPath]: Path Error :: {self.Model.Name} :: Point #{self.NextPoint} hasn't been reached.`)
				
				self.Expect:Fire("Path", `Point #{self.NextPoint} hasn't been reached.`)
				return
			end

			self:Next()
		end)
		
		self.__Cleaner:Task(self.__ReachedConnection)
	end
	
	self.NextPoint = self.NextPoint or 1
	self:Next()
end

function Path:Next()
	if (not self.Model or not self.Model.Parent) or not self.Playing or self.NextPoint >= #self.Points then
		return
	end
	
	self.Model.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
	if self.NextPoint > 1 then self.PointReached:Fire(self.NextPoint) end
	
	self.NextPoint += 1
	self.Model.Humanoid:MoveTo(self.Points[self.NextPoint].Position)
	self:Visual()
end

function Path:Compute(Position)
	if not self.Model or not self.Model.Parent then
		return
	end
	
	Position = self.Following or Position
	if not Position or not table.find({"Instance", "Vector3"}, typeof(Position)) then
		warn(`[GPath]: Compute Error :: {self.Model.Name} :: Invalid Position.`)
		self.Expect:Fire("Compute", "Invalid Position")
		return
	end
	
	self.NextPoint = 1
	Position = typeof(Position) == "Instance" and Position.Position or Position
	self.Goal = Position
	
	local Success, Response = pcall(function()
		self.__Path:ComputeAsync(self.Model.PrimaryPart.Position, self.Goal)
	end)
	
	if not Success or self.__Path.Status ~= Enum.PathStatus.Success then
		self.State = self.__Path.Status.Name
		warn(`[GPath]: Compute Error :: {self.Model.Name} :: {Response or self.__Path.Status.Name}`)
		self.Expect:Fire("Compute", Response or self.__Path.Status.Name)
		return
	end
	
	if not self.Model or not self.Model.Parent then
		return
	end
	
	self.Points = self.__Path:GetWaypoints()
	self:Visual()
end

function Path:Visual()
	if not self.Model or not self.Model.Parent or not self.Visualise or not self.__Path then
		if Data.Bin[self.Model.Name] then
			Data.Bin[self.Model.Name].Folder:ClearAllChildren()
		end
		
		return
	end
	
	if Data.Bin[self.Model.Name] and Data.Bin[self.Model.Name].Owner ~= self.Model then
		warn(`[GPath]: Visual Error :: {self.Model.Name} :: Folder named '{self.Model.Name}' already exists.`)
		self.Expect:Fire("Visual", `Folder named '{self.Model.Name}' already exists.`)
		return
	end
	
	if not Data.Bin[self.Model.Name] then
		local Folder = self.__Cleaner:Task(Instance.new("Folder"))
		Folder.Name = self.Model.Name
		Folder.Parent = workspace.GPath_Bin
		
		Data.Bin[self.Model.Name] = {
			Owner = self.Model,
			Folder = Folder,
		}
	end
	
	Data.Bin[self.Model.Name].Folder:ClearAllChildren()
	self.NextPoint = self.NextPoint or 1
	
	for i, Waypoint in ipairs(self.Points) do
		local Point = Instance.new("Part")
		Point.Name = `{self.Model.Name}_{i}`
		Point.CanCollide = false
		
		Point.Shape = Enum.PartType.Ball
		Point.Material = Enum.Material.Neon
		
		Point.Anchored = true
		Point.Size = Vector3.new(.5, .5, .5)
		
		Point.Color = self.NextPoint > i and Color3.new(1, 0.360784, 0.360784) or Color3.new(0.454902, 1, 0.360784)
		Point.Color = self.NextPoint == i and Color3.new(0.988235, 1, 0.180392) or Point.Color
		
		Point.Position = Waypoint.Position
		Point.Parent = Data.Bin[self.Model.Name].Folder
	end
end

function Path:Calculate()
	local TorsoSize = GetSize("Torso", self.Model)
	local Height = GetSize("Leg", self.Model).Y + TorsoSize.Y + self.Model.Head.Size.Y
	local Radius = TorsoSize.X + (GetSize("Arm", self.Model).X * 2)
	
	return {
		AgentHeight = Height,
		AgentRadius = Radius
	}
end

function Path:Destroy()
	Data.Bin[self.Model.Name] = nil
	
	self.__Cleaner:Remove()
	setmetatable(self, nil)
	
	table.remove(self)
	self.State = "Destroyed"
end

return Path
