local Bodies = {
	["Leg"] = function(Character)
		if Character.Humanoid.RigType == Enum.RigType.R15 then
			return Character.LeftFoot.Size + Character.LeftLowerLeg.Size + Character.LeftUpperLeg.Size
		end
		
		return Character["Left Leg"].Size
	end,
	
	["Torso"] = function(Character)
		return Character.HumanoidRootPart.Size
	end,
	
	["Arm"] = function(Character)
		if Character.Humanoid.RigType == Enum.RigType.R15 then
			return Character.LeftHand.Size + Character.LeftLowerArm.Size + Character.LeftUpperArm.Size
		end

		return Character["Left Arm"].Size
	end,
}

return function(R6Body, Character)
	return Bodies[R6Body](Character)
end
