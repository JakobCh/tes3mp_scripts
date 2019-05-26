customSpells = {}


local msg = function(pid, text)
	if text == nil then
		text = ""
	end
	tes3mp.SendMessage(pid, color.GreenYellow .. "[customSpells] " .. color.Default .. text .. "\n" .. color.Default)
end


local CUSTOM_SPELLS = {}
CUSTOM_SPELLS["Illusion"] = {}
CUSTOM_SPELLS["Illusion"]["$custom_spell_1"] = function(pid)
	local ply = Players[pid]
	msg(pid, "CUSTOM SPELL CAST")

	local amount = 1000
	local goldLoc = inventoryHelper.getItemIndex(ply.data.inventory, "gold_001", -1) --get the location of gold in the players inventory
	
	if goldLoc then --if the player already has gold in there inventory
		ply.data.inventory[goldLoc].count = ply.data.inventory[goldLoc].count + amount --add the new gold onto his already existing stack
	else
		table.insert(ply.data.inventory, {refId = "gold_001", count = amount, charge = -1}) --create a new stack of gold
	end
	
	ply:Save()
	msg(pid, "ADDED 1000 GOLD TO YOUR INVENTORY")
	ply:LoadInventory()
    ply:LoadEquipment()

end

customSpells.registerSpell = function(school, refId, func)
	CUSTOM_SPELLS[school][refId] = func
end

local getSkillThatsChanged = function(pid)
	local Player = Players[pid]
	local changedSkill
	local skillAmount

	for name in pairs(Player.data.skills) do
		local skillId = tes3mp.GetSkillId(name)
		--original[skillId] = name
		local baseProgress = Player.data.skillProgress[name]
		local changedProgress = tes3mp.GetSkillProgress(pid, skillId)
		--msg(pid, name .. ":" .. tostring(baseProgress) .. "/" .. changedProgress )
		if baseProgress < changedProgress then
			changedSkill = name
			skillAmount = changedProgress - baseProgress
		end
	end

	return changedSkill, skillAmount

end

customEventHooks.registerValidator("OnPlayerSkill", function(eventStatus, pid)
	msg(pid, "OnPlayerSkill")
	local selectedSpell = Players[pid].data.miscellaneous.selectedSpell
	msg(pid, selectedSpell)
	local changedSkill, skillAmount = getSkillThatsChanged(pid)
	msg(pid, changedSkill)
	msg(pid, skillAmount)

	if skillAmount == nil then return end

	if skillAmount < 0.5 then return end

	if CUSTOM_SPELLS[changedSkill] == nil then return end

	if CUSTOM_SPELLS[changedSkill][selectedSpell] == nil then return end

	--okey lets cast the spell
	CUSTOM_SPELLS[changedSkill][selectedSpell](pid)
end)

--OnPlayerSkill