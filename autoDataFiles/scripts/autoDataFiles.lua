--[[

Name: autoDataFiles
Version: 0.2
Tes3mp Version: 0.8
Author: JakobCh
Last update: 2022-02-10

Description:
    Automaticaly use the datafiles in your openmw config.

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.autoDataFiles") ] in server/scripts/customScripts.lua

Commands:
    None

Known issues/TODO:
    Doesn't add checksums.
    Haven't been tested on Linux/OS X
]]


--TODO checksums, use link below maybe
--https://github.com/davidm/lua-digest-crc32lua/blob/master/lmod/digest/crc32lua.lua


local doInfo = function(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[autoDataFiles]: " .. text)
end
local doError = function(text)
    tes3mp.LogMessage(enumerations.log.ERROR, "[autoDataFiles]: " .. text)
end

local configPath

-- Paths from here: https://openmw.readthedocs.io/en/stable/manuals/openmw-cs/files-and-directories.html
if tes3mp.GetOperatingSystemType() == "Windows" then
    doInfo("Detected Windows")
    configPath = "C:\\Users\\" .. os.getenv('USERNAME') .. "\\Documents\\My games\\OpenMW\\openmw.cfg"
elseif tes3mp.GetOperatingSystemType() == "Linux" then
    doInfo("Detected Linux")
    configPath = "~/.config/openmw/openmw.cfg"
elseif tes3mp.GetOperatingSystemType() == "OS X" then
    doInfo("Detected OS X")
    configPath = "~/Library/Application Support/openmw/openmw.cfg"
else
    doError("Unknown OS can't determine openmw config path")
    return --back out
end


customEventHooks.registerHandler("OnServerInit", function(eventStatus)
    doInfo("Using config file: " .. configPath)

    OnRequestDataFileList = function()
        for line in io.lines(configPath) do --Don't worry about reading the file here this function only gets called once
            if (string.match( line, "content")) then
                local fileName = string.gsub( line, "content=", "" ) -- content=Morrowind.esm -> Morrowind.esm
                doInfo("Using Datafile: " .. fileName)
                table.insert(clientDataFiles, fileName) --new in 0.8
                tes3mp.AddDataFileRequirement(fileName, "")
            end
        end
    end
    return eventStatus
end)


