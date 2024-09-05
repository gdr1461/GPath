local GSignal = require(script.Parent.GSignal)
local GCleanerTypes = require(script.Parent.GCleaner.Types)

export type GPathProxy = {
	__type: string,
	__version: string,
	
	__Bin: Folder,
	__Paths: {
		[string]: NewPath
	},
	
	Create: (self: GPathProxy, Character: Model) -> NewPath
}

export type States = "Default" | "Following" | "Playing" | "Destroyed"
export type NewPath = {
	__Cleaner: GCleanerTypes.NewCleaner,
	__Path: Path,
	
	__ReachedConnection: RBXScriptConnection?,
	__FollowStart: number,
	
	State: States,
	Goal: Vector3?,
	NextPoint: number,
	
	Visualise: boolean,
	FollowTime: boolean,
	
	Model: Model,
	Playing: boolean,
	
	Following: BasePart?,
	Agent: NewAgent,
	
	Points: {
		[number]: PathWaypoint
	},
	
	Played: GSignal.NewSignal,
	Stopped: GSignal.NewSignal,
	
	PointReached: GSignal.NewSignal,
	Blocked: GSignal.NewSignal,
	StateChange: GSignal.NewSignal,
	
	OnPlay: GSignal.NewSignal,
	Expect: GSignal.NewSignal,
	
	Play: (self: NewPath) -> (),
	__Play: (self: NewPath) -> (),
	
	Follow: (self: NewPath, Part: BasePart) -> Connection,
	Stop: (self: NewPath) -> (),
	
	Next: (self: NewPath) -> (),
	Compute: (self: NewPath, Position: Vector3) -> (),
	Calculate: (self: NewPath) -> NewAgent,
	
	Visual: (self: NewPath) -> (),
	Destroy: (self: NewPath) -> (),
}

export type NewAgent = {
	AgentHeight: number,
	AgentRadius: number,

	AgentCanJump: boolean,
	AgentCanClimp: boolean,

	WaypointSpacing: number,
	Costs: {
		[string]: number
	}
}

export type Connection = {
	Object: any,
	Disconnect: (self: Connection) -> ()
}

return {}
