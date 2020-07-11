-- PlayerSkillResetFix by Jakob
-- Made 2020-07-11
-- Will probably not work if theres been a update to the BasePlayer:SaveSkills function after that.

-- This fixes a problem where the client tells the server that the base level in one of there stats is lower then whats already saved on the server.
-- This is cause by packet loss to the client when they log in so they never get there skills from the server.
-- This causes the client to use the default skills of a new character, that it will try to update the server with later.

-- To install:
-- 	Put this fine in scripts/custom/
-- 	open up scripts/customscripts.lua and add "require("custom.PlayerSkillResetFix")"

--This will override the normal BasePlayer:SaveSkills function
function BasePlayer:SaveSkills()

    for name in pairs(self.data.skills) do

        local skillId = tes3mp.GetSkillId(name)

        local baseValue = tes3mp.GetSkillBase(self.pid, skillId)
        local modifierValue = tes3mp.GetSkillModifier(self.pid, skillId)
        local maxSkillValue = config.maxSkillValue

        if name == "Acrobatics" then
            maxSkillValue = config.maxAcrobaticsValue
        end

        if baseValue > maxSkillValue then
            self:LoadSkills()

            local message = "Your base " .. name .. " has exceeded the maximum allowed value " ..
                "and been reset to its last recorded one.\n"
            tes3mp.SendMessage(self.pid, message)
        elseif (baseValue + modifierValue) > maxSkillValue and not config.ignoreModifierWithMaxSkill then
            tes3mp.ClearSkillModifier(self.pid, skillId)
            tes3mp.SendSkills(self.pid)

            local message = "Your " .. name .. " fortification has exceeded the maximum allowed " ..
                "value and been removed.\n"
			tes3mp.SendMessage(self.pid, message)
			
		elseif baseValue < self.data.skills[name].base then --if the client sends a lower value then the server already has
			tes3mp.LogAppend(enumerations.log.INFO, "Player " .. logicHandler.GetChatName(self.pid) ..
													" has a lower local skill in " .. name ..
													" then the server has stored.")
			self:LoadSkills() --Send the client the servers skills
        else
            self.data.skills[name] = {
                base = baseValue,
                damage = tes3mp.GetSkillDamage(self.pid, skillId),
                progress = tes3mp.GetSkillProgress(self.pid, skillId)
            }

            -- Removes old tables for skill progress
            if self.data.skillProgress ~= nil and self.data.skillProgress[name] ~= nil then
                self.data.skillProgress[name] = nil
            end
        end
    end

    -- Remove traces of old way of saving skill progress
    if self.data.skillProgress ~= nil and tableHelper.isEmpty(self.data.skillProgress) then
        self.data.skillProgress = nil
    end
end