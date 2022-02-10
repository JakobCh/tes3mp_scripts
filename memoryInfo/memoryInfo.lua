--[[

Name: memoryInfo
Version: 0.1
Tes3mp Version: 0.8
Author: JakobCh
Last update: 2022-02-10

Description:
    Commands to get memory usage and run garbage collection

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.memoryInfo") ] in server/scripts/customScripts.lua

Commands:
    /memoryinfo: Print memory usage
    /memoryinfo collect: Runs garbage collection
    /memoryinfo step: Runs a garbage collection step

Known issues/TODO:
    None
]]


local function myPrint(text)
    tes3mp.LogMessage(enumerations.log.INFO, "[memoryInfo]: " ..text)
end

local function getMemoryFormated()
    local kb = collectgarbage("count")
    if kb > 1024 then
        return tostring(math.floor((kb/1024) + 0.5)) .. " MegaBytes"
    end

    return tostring(math.floor(kb + 0.5)) .. " KiloBytes"

end

customEventHooks.registerHandler("OnServerInit", function(event)
    myPrint("Memory Init: " .. getMemoryFormated())
end)

customEventHooks.registerHandler("OnServerPostInit", function(event)
    myPrint("Memory Post Init: " .. getMemoryFormated())
end)



customCommandHooks.registerCommand("memoryinfo", function(pid, cmd)
    if Players[pid]:IsModerator() == false then --if they're a pleb
        return customEventHooks.makeEventStatus(true, true) --continue whatever
    end

    if cmd[2] == "collect" then
        collectgarbage("collect")
        tes3mp.SendMessage(pid, "Memory collection ran.\n")
    elseif cmd[2] == "step" then
        collectgarbage("step")
        tes3mp.SendMessage(pid, "Memory collection step ran.\n")
    end

    tes3mp.SendMessage(pid, "Current Lua memory usage is: " .. getMemoryFormated() .. "\n")

end)


