-- PlayerSkillResetFix by Jakob
-- Made 2020-07-11

-- This fixes a problem where the client tells the server that the base level in one of there stats is lower then whats already saved on the server.
-- This is cause by packet loss to the client when they log in so they never get there skills from the server.
-- This causes the client to use the default skills of a new character, that it will try to update the server with later.

-- To install:
--     Put this fine in scripts/custom/
--     open up scripts/customscripts.lua and add "require("custom.PlayerSkillResetFix")"



customEventHooks.registerValidator("OnPlayerSkill", function(eventStatus, pid)

    local player = Players[pid]

    for name in pairs(player.data.skills) do
        local skillId = tes3mp.GetSkillId(name)
        local baseValue = tes3mp.GetSkillBase(pid, skillId)

        if baseValue < player.data.skills[name].base then
            tes3mp.LogAppend(enumerations.log.INFO, "Player " .. logicHandler.GetChatName(pid) ..
                                                    " has a lower local skill in " .. name ..
                                                    " then the server has stored.")
            self:LoadSkills() --Send the client the servers skills
            return customEventHooks.makeEventStatus(false,false)
            break
        end
    end

    return eventStatus
end)
