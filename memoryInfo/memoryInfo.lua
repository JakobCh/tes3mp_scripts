--[[
    MemoryInfo Version 0.1

    Description:
        Randomly decided to make this after I remembered lua has some garbage collection bindings

    Install:
	    Put this file in server/scripts/custom/
        Put [ require("custom.memoryInfo") ] in customScripts.lua
        
    Commands:
        /memoryinfo: Print memory usage
        /memoryinfo collect: Runs garbage collection
        /memoryinfo step: Runs a garbage collection step



]]

local function myPrint(text)
    tes3mp.LogMessage(enumerations.log.INFO, "[MemoryInfo]: " ..text)
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


