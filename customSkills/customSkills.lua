-- CustomSkills by Jakob
-- Made 2020-07-11

-- NOT DONE DON'T USE

-- A library for handling custom skills

-- Helper functions
local function msg(pid, text)
	tes3mp.SendMessage(pid, color.Aqua .. "[CustomSkills] " .. color.Default .. text .. "\n" .. color.Default)
end

local function log(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[CustomSkills] " .. text)
end

local function warn(text)
	tes3mp.LogMessage(enumerations.log.WARN, "[CustomSkills] " .. text)
end

local function makeStringTable(t, columnNames)
	assert(type(t) == "table")
	
	--calculate the maximum string size for each column
	local sizes = {}
	for _,row in pairs(t) do
		assert(type(row) == "table")
		for i=1,#row do
			if sizes[i] == nil then
				sizes[i] = 0 --start of all sizes at 0
			end
			if #tostring(row[i]) > sizes[i] then 
				sizes[i] = #tostring(row[i])
			end
		end
	end
	
	local out = ""
	
	for l=1,#t do
		local row = t[l]
		for i=1,#row do
			if i ~= 1 then --if it's not the first column add a seperator
				out = out .. "| "
			end
			out = out .. string.rep(" ", sizes[i] - #tostring(row[i])) .. tostring(row[i]) .. " "
		end
		out = out .. "\n"
		if l == 1 and columnNames then --if columnNames are on draw a line under the first row
			for i=1,#row do
				out = out .. string.rep("-", sizes[i]+3)
			end
			out = out .. "\n"
		end
	end
	return out
end

local skills = {}

customSkills = {}

-- Should be called on server start by other scripts that implement custom skills
customSkills.addSkill = function(skillId, name, base)
	assert(type(skillId) == "string") -- the id used internaly (no spaces pls)
	assert(type(name) == "string") -- the ui text
	assert(type(base) == "number") -- starting level

	if skills[skillId] ~= nil then
		warn("Trying to add new skill " .. skillId .. " but it already exists.")
		return
	end

	skills[skillId] = {
		name = name,
		base = base
	}
end

customSkills.getSkill = function(pid, skillId)
	return Players[pid].data.customVariables.customSkills[skillId]
end

customSkills.setSkill = function(pid, skillId, value)
	Players[pid].data.customVariables.customSkills[skillId] = value
end

-- Add progress to a skill
customSkills.addProgress = function(pid, skillId, amount)
	assert(type(pid) == "number")
	assert(type(skillId) == "string")
	assert(type(amount) == "number")

	local sk = customSkills.getSkill(pid, skillId)
	sk.progress = sk.progress + amount

	if sk.progress >= 100 then
		if sk.base < 100 then
			sk.base = sk.base + 1
		end
		sk.progress = sk.progress - 100
		tes3mp.MessageBox(pid, -1, "You have gained a level in " .. skills[skillId].name .. "!")
	end

	customSkills.setSkill(pid, skillId, sk)
end

-- First time setup for a player
customSkills.initPlayer = function(pid)
	assert(type(pid) == "number")

	if Players[pid].data.customVariables.customSkills == nil then
		Players[pid].data.customVariables.customSkills = {}
	end
	
	for skillId, skillData in pairs(skills) do
		if customSkills.getSkill(pid, skillId) == nil then
			customSkills.setSkill(pid, skillId, {
				base = skillData.base,
            	damage = 0,
            	progress = 0
			})
		end
	end
	log("Player " .. logicHandler.GetChatName(pid) .. " got inited!")
end



customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid)
	customSkills.initPlayer(pid)
end)

customCommandHooks.registerCommand("customskills", function(pid, cmd)
	if skills[cmd[2]] then
		customSkills.addProgress(pid, cmd[2], 20)
		msg(pid, "Incresed your " .. cmd[2] .. " skill.")
	else
		local t = {{"Name", "Level", "Progress"}}
		for skillId, skillData in pairs(skills) do
			local sk = customSkills.getSkill(pid, skillId)
			table.insert( t, {skillData.name, tostring(sk.base) .. "/100", tostring(sk.progress) .. "/100"} )
		end

		tes3mp.CustomMessageBox(pid, -1, makeStringTable(t, true), "Close")
	end
end)

customSkills.addSkill("test", "Test Skill", 1)
customSkills.addSkill("mining", "Mining", 20)


--OnPlayerFinishLogin

-- Players[pid].data.customVariables.customSkills