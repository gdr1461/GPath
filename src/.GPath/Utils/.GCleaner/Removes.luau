return {
	--== Metatable
	function(Object)
		if typeof(Object) ~= "table" or Object.__metatable then
			return false
		end
		
		setmetatable(Object, nil)
		return true
	end,
	
	--== Connection
	function(Object)
		if typeof(Object) ~= "RBXScriptConnection" then
			return false
		end
		
		Object:Disconnect()
		return true
	end,
	
	--== Function
	function(Object)
		if type(Object) ~= "function" then
			return false
		end

		Object()
		return true
	end,
	
	--== Thread
	function(Object)
		if typeof(Object) ~= "thread" then
			return false
		end

		task.cancel(Object)
		return true
	end,
	
	--== Any instance
	function(Object)
		local Success = pcall(function()
			Object:Destroy()
		end)

		return Success
	end,
	
	--== Trying possible methods.
	function(Object)
		local Success = pcall(function()
			Object:Remove()
		end)
		
		if not Success then
			Success = pcall(function()
				Object:DisconnectAll()
			end)
		end
		
		if not Success then
			Success = pcall(function()
				Object:Disconnect()
			end)
		end
		
		if not Success then
			Success = pcall(function()
				Object:Stop()
			end)
		end
		
		if not Success then
			Success = pcall(function()
				Object:Pause()
			end)
		end

		return Success
	end,
}
