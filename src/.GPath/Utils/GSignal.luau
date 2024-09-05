--[[

	-- Modified version of GSignal.
	-- Was modified for GPath module.

]]

--==============================================================================================================================

local function GetErrorLocation(Path)
	local PathSplit = Path:split(":")[1]:split(".")
	local Success, Location = pcall(function()
		return game:GetService(PathSplit[1])
	end)
	
	if not Success then
		return "Unknown"
	end
	
	table.remove(PathSplit, 1)
	for i, PathName in ipairs(PathSplit) do
		if not Location:FindFirstChild(PathName) then
			return
		end
		
		Location = Location[PathName]
	end
	
	return Location
end

export type NewConnection = {
	Disconnect: (self: NewConnection) -> (),
	GetFunction: (self: NewConnection) -> Function,
	OnError: (self: NewConnection, Function: (ErrorMessage: string, any?) -> boolean) -> NewConnection,
	OnErrorDisconnnect: (self: NewConnection) -> NewConnection
}

local Proxy = require(script.Proxy)
local Connection: {new: (NewSignal, () -> ()) -> NewConnection, Disconnect: () -> ()} = {}
Connection.__index = Connection

function Connection.new(Signal: NewSignal, Function: () -> any): NewConnection
	local self: NewConnection = setmetatable({}, Connection)
	self.Signal = Signal
	self.Function = Function
	
	return self
end

function Connection:GetFunction()
	return self.Function
end

function Connection:Disconnect()
	local Connected = table.find(self.Signal.Signals, self.Function)
	if not Connected then
		return
	end
	
	table.remove(self.Signal.Signals, Connected)
end

function Connection:OnError(Function: (Error: string, any?) -> ())
	if not Function or type(Function) ~= "function" then
		warn(`Could not connect function to GSignal due of function being nil or not type of function.`)
		return
	end

	self.Signal.SignalSettings[self.Function] = self.Signal.SignalSettings[self.Function] or {Tries = 0, Handlers = {}}
	table.insert(self.Signal.SignalSettings[self.Function].Handlers, Function)
	return Connection
end

function Connection:OnErrorDisconnect()
	self.Signal.SignalSettings[self.Function].Handlers = {}
	return Connection
end

setmetatable(Connection, {
	__index = function(Table, Key)
		warn(`Attempt to get nil Connection value. ({Key})`)
	end,
	
	__newindex = function(Table, Key)
		warn(`Attempt to set new value '{Key}' to Connection.`)
	end,
})

local GSignalObjects = 0
local GSignal: {new: () -> NewSignal} = {}

GSignal.__type = "GSignal"
GSignal.__metatable = "Permission denied"

GSignal.Side = game.Players.LocalPlayer ~= nil and "Client" or "Server"
GSignal.OppositeSide = GSignal.Side == "Client" and "Server" or "Client"

type Function = {}
type Variables = {}

export type NewSignal = {
	Side: string,
	OppositeSide: string,
	
	ConnectionHandler: boolean,
	Signals: {T: () -> ()},
	Enhances: {T: {K: any}},
	Welds: {T: () -> ()},
	Weld: (Signal1: NewSignal, Signal2: NewSignal) -> {
		UnWeld: () -> ()
	},
	RecentVariables: {[Function]: Variables},
	RemoteEvent: RemoteEvent,
	RemoteEventConnection: RBXScriptConnection,
	RemoteEventFired: number,
	UnWeld: (self: NewSignal) -> NewSignal,
	Enhance: (self: NewSignal, Table: {[any]: any}) -> {[any]: any},
	Connect: (self: NewSignal, Function: (any) -> ()) -> NewConnection,
	Once: (self: NewSignal, Function: (any) -> ()) -> NewConnection,
	Wait: (self: NewSignal) -> any,
	DisconnectAll: (self: NewSignal) -> NewSignal,
	Handle: (self: NewSignal, Function: (self: NewSignal, any?) -> (), Specifics: {any}?, any?) -> (),
	Fire: (self: NewSignal, Variables: Variables) -> NewSignal,
	FireAllClients: (self: NewSignal, any) -> NewSignal,
	
	Cross: (self: NewSignal, Name: string, Weld: boolean?) -> RemoteEvent,
	UnCross: (self: NewSignal) -> NewSignal,
	GetEvent: (self: NewSignal, Name: string) -> RemoteEvent,
	
	Invoke: (self: NewSignal, Variables: Variables) -> {[Function]: Variables?},
	Get: (self: NewSignal, Function: Function?, UnPack: boolean?) -> {[Function]: Variables}?,
}

GSignal.__index = GSignal
GSignal.__tostring = function(Table)
	return `GSignal Object #{Table.ID}`
end

GSignal.__Iter = function(Table)
	return next, Table
end

function GSignal.new()
	GSignalObjects += 1
	local self: NewSignal = setmetatable({}, GSignal)
	self.ID = GSignalObjects
	self.ConnectionHandler = false
	self.Signals = {}
	self.SignalSettings = {}
	self.Enhances = {}
	self.Welds = {}
	self.RecentVariables = {}
	
	return self
end

function GSignal:Connect(Function: (any) -> ())
	if not Function or type(Function) ~= "function" then
		warn(`Could not connect function to GSignal due of function being nil or not type of function.`)
		return
	end
	
	table.insert(self.Signals, Function)
	self.SignalSettings[Function] = {
		Tries = 0,
		Handlers = {}
	}
	
	local ConnectionNew = Connection.new(self, Function)
	return ConnectionNew
end

function GSignal:Once(Function: (any) -> ())
	local Connection
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		Function(...)
	end)
	
	return Connection
end

function GSignal:Wait()
	local Corountine = coroutine.running()
	local Connection
	
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		task.spawn(Corountine, ...)
	end)
	
	return coroutine.yield()
end

function GSignal:DisconnectAll()
	self.Signals = {}
	self.Welds = {}
	self.Enhanced = {}
	return self
end

function GSignal:Handle(Function: (self: NewSignal, any?) -> (), Specifics, ...)
	local Response = coroutine.wrap(function(...)
		local Success, Response
		local Variables = {...}
		
		local function OnError(Response)
			if #self.SignalSettings[Function].Handlers <= 0 then
				warn(`--==== NO ERROR HANDLERS DETECTED ====--`)
				warn(`ERROR OCCURRED AT:`)
				print(GetErrorLocation(Response) or Specifics.Place)
				warn(`SPECIFIC PLACE: {Specifics.SpecificPlace}`)
				warn(`ERROR:`)
				warn(`'{Response}'`)
				warn(`AT: {DateTime.now():FormatLocalTime("HH:mm:ss", "en-us")}`)
				warn(`FUNCTION CALLED: {Function}`)
				warn(`ARGUMENTS PASSED:`)
				print(unpack(Variables))
				warn(`--====                            ====--`)
				return
			end

			for i, ErrorHandler in pairs(self.SignalSettings[Function].Handlers) do
				local Retry = ErrorHandler(Response, unpack(Variables))
				if Retry and self.SignalSettings[Function].Tries < 3 then self.SignalSettings[Function].Tries += 1 self:Handle(Function, Specifics, unpack(Variables)) end
				if self.SignalSettings[Function].Tries >= 3 then warn(`[{self}]: Attempt limit exceeded.`) end
				self.SignalSettings[Function].Tries = 0
			end
		end
		
		Success, Response = pcall(Function, ...)
		if not Success then
			OnError(Response)
		end
		
		return Response
	end)(...)
	
	return Response
end

function GSignal:Fire(...)
	self.RecentVariables = {}
	for i, Function in pairs(self.Signals) do
		self.RecentVariables[Function] = {}
		table.insert(self.RecentVariables[Function], self:Handle(Function, {Place = tostring(self), SpecificPlace = `Function Call #{i}`}, ...))
	end
	
	if not self.RemoteEvent then
		return self
	end
	
	self.RemoteEventFired = tick()
	self.RemoteEvent[`Fire{self.OppositeSide}`](self.RemoteEvent, ...)
	return self
end

function GSignal:Get(Function, UnPack)
	local Arguments = Function and self.RecentVariables[Function] or self.RecentVariables
	return UnPack and unpack(Arguments) or Arguments
end

return GSignal
