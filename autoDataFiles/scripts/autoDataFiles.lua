
--automatically use datafiles from your openmw config

--TODO checksums, use link below maybe
-- https://github.com/davidm/lua-digest-crc32lua/blob/master/lmod/digest/crc32lua.lua



local myDataFiles = {}

local doInfo = function(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[autoDataFiles]: " .. text) 
end

local configPath = "C:\\Users\\" .. os.getenv('USERNAME') .. "\\Documents\\My games\\OpenMW\\openmw.cfg"


customEventHooks.registerHandler("OnServerInit", function(eventStatus)
    doInfo("Using config file: " .. configPath)

	OnRequestDataFileList = function ()
        for line in io.lines(configPath) do
            if (string.match( line, "content")) then
                local fileName = string.gsub( line, "content=", "" ) -- content=Morrowind.esm -> Morrowind.esm
                doInfo("Using Datafile: " .. fileName)
                tes3mp.AddDataFileRequirement(fileName, "")
            end
        end
    end
    return eventStatus
end)


