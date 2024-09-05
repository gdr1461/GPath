export type GCleanerProxy = {
	__type: string,
	__version: string,
	
	New: (self: GCleanerProxy) -> NewCleaner
}

export type IDNumber = {}
export type NewCleaner = {
	Task: (self: NewCleaner, Object: any, ReturnId: boolean) -> IDNumber,
	Find: (self: NewCleaner, Object: any) -> IDNumber,
	GetObjects: (self: NewCleaner) -> {any},
	
	Clean: (self: NewCleaner) -> (),
	Remove: (self: NewCleaner) -> ()
}

return {}
