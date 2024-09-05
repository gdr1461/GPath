function Proxy(Table)
	Table = Table or {}
	local ProxyTable = {}
	local Event = Instance.new("BindableEvent")
	
	ProxyTable.Proxy = {}
	ProxyTable.Changed = Event.Event
	
	setmetatable(ProxyTable, {
		__index = function(FakeTable, Key)
			return Table[Key]
		end,
		
		__newindex = function(Table, Key, NewValue)
			local OldValue = Table[Key]

			if OldValue ~= NewValue then
				Table.Proxy[Key] = NewValue
				Event:Fire(Key, OldValue, NewValue)
			end
		end,
		
		__len = function(Table)
			local Length = 0
			for i, v in pairs(Table) do
				Length += 1
			end

			return Length
		end,
		
		__iter = function(Table)
			local NewTable = {}
			for i, v in pairs(Table) do
				if type(v) == "function" then
					continue
				end

				NewTable[i] = v
			end

			return next, NewTable
		end
	})
	
	return ProxyTable
end

return Proxy
