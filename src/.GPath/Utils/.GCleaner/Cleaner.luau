local Types = require(script.Parent.Types)
local Removes = require(script.Parent.Removes)

local Cleaner: Types.NewCleaner = {}

function Cleaner:__Clean(Object)
	local Id = self:Find(Object)
	if not Id then
		return
	end

	self[Id] = nil
	for i, Function in ipairs(Removes) do
		if not Function(Object) then
			continue
		end
		
		break
	end
end

function Cleaner:Task(Object, ReturnId)
	if Cleaner:Find(Object) then
		warn(`[GCleaner]: Unable to insert object :: {Object} :: Object already exists in cleaner!`)
		return
	end
	
	local Id
	repeat
		Id = math.random(999, 99999999)
		task.wait()
	until not self[Id]
	
	self[Id] = Object
	return ReturnId and Id or Object
end

function Cleaner:Find(Object)
	self.__Tasks = self.__Tasks or {}
	for Id, Task in pairs(self.__Tasks) do
		if Task == self or Task ~= Object then
			continue
		end
		
		return Id
	end
end

function Cleaner:GetObjects()
	local Objects = {}
	for Id, Task in pairs(self.__Tasks) do
		if Task == self then
			continue
		end

		table.insert(Objects, Task)
	end
	
	return Objects
end

function Cleaner:Remove()
	self:Clean()
	setmetatable(self, nil)
end

function Cleaner:Clean()
	local Objects = self:GetObjects()
	if not Objects or #Objects <= 0 then
		return
	end
	
	for i, Object in pairs(Objects) do
		self:__Clean(Object)
	end
end

return Cleaner
