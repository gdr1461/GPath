--[[

	-- Modified version of GCleaner.
	-- Was modified for GPath module.

]]

--==============================================================================================================================

local Types = require(script.Types)
local Cleaner = require(script.Cleaner)

local Proxy = newproxy(true)
local GCleaner: Types.GCleanerProxy = getmetatable(Proxy)

GCleaner.__type = "GCleaner"
GCleaner.__version = "v0.2.0"

function GCleaner:__tostring()
	return self.__type, self.__version
end

function GCleaner:__index(Key)
	return GCleaner[Key]
end

function GCleaner:__newindex(Key, Value)
	GCleaner[Key] = Value
	return Value
end

function GCleaner:New()
	local CleanerProxy = table.clone(Cleaner)
	local NewCleaner = setmetatable({
		__Tasks = {},
	}, CleanerProxy)
	
	CleanerProxy.__index = function(Table, Key)
		return CleanerProxy[Key] or NewCleaner.__Tasks[Key]
	end
	
	CleanerProxy.__newindex = function(Table, Key, Value)
		local OldValue = CleanerProxy[Key]
		if OldValue ~= nil and Value == nil then
			CleanerProxy:__Clean(OldValue)
			return
		end
		
		if CleanerProxy:Find(Value) then
			warn(`[GCleaner]: Unable to insert object :: {Value} :: Object already exists in cleaner!`)
			return
		end
		
		NewCleaner.__Tasks[Key] = Value
	end

	return NewCleaner
end

return Proxy :: Types.GCleanerProxy
