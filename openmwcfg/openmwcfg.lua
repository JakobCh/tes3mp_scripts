--[[
Version: 0.1

Install:
	Put this file in /server/scripts/custom/
	Put [ openmwcfg = require("custom.openmwcfg") ] in customScripts.lua
	
Usage:
	openmwcfg["data"] = "C:\Program Files (x86)\Steam\steamapps\common\Morrowind\Data Files"
	openmwcfg["content"] = {"Morrowind.esm", "Tribunal.esm", "Bloodmoon.esm"}
	openmwcfg["fallback-archive"] = {"Morrowind.bsa", "Tribunal.bsa", "Bloodmoon.bsa"}
	openmwcfg["encoding"] = "win1252"
	openmwcfg["no-sound"] = "0"
	openmwcfg["fallback"] = like a huge table with a bunch of shit
]]

-- openmwcfg 
-- Version 0.1




local openmwcfg = {}

local function doInfo(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[openmwcfg]: " .. text) 
end

local function GetConfigPath()
    --Add linux support
	return "C:\\Users\\" .. os.getenv('USERNAME') .. "\\Documents\\My games\\OpenMW\\openmw.cfg"
end

local function Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function GetKeys(tab)
	local keyset={}
	local n=0

	for k,v in pairs(tab) do
	  n=n+1
	  keyset[n]=k
	end
	return keyset
end

local function PrintTable(tab, offset)
	for n,m in pairs(tab) do
		if type(m) == type({}) then
			doInfo("    " .. n .. ": table:" .. tostring(#GetKeys(m)))
		else
			doInfo("    " .. n .. ": " .. tostring(m))
		end
	end
end


do
	for line in io.lines(GetConfigPath()) do
		local sep = Split(line, "=")
		local sep2 = Split(sep[2], ",")
		
		if openmwcfg[sep[1]] == nil then
			if #sep2 == 1 then
				openmwcfg[sep[1]] = sep2[1]
			else
				local key = sep2[1]
				table.remove(sep2, 1)
				openmwcfg[sep[1]] = {}
				openmwcfg[sep[1]][sep2[1]] = table.concat(sep2, ",")
			end
		else
			if #sep2 == 1 then
				if type(openmwcfg[sep[1]]) == type("") then
					local temp = openmwcfg[sep[1]]
					openmwcfg[sep[1]] = {}
					table.insert(openmwcfg[sep[1]], temp)
					table.insert(openmwcfg[sep[1]], sep2[1])
				elseif type(openmwcfg[sep[1]]) == type({""}) then
					table.insert(openmwcfg[sep[1]], sep2[1])
				end
			else
				local key = sep2[1]
				table.remove(sep2, 1)
				openmwcfg[sep[1]][sep2[1]] = table.concat(sep2, ",")
			end
		end
    end
	
	for n,m in pairs(openmwcfg) do
		if n == "fallback-archive" or n == "content" then
			doInfo(n .. ": ")
			PrintTable(m)
		else
			doInfo(n .. ": " .. tostring(m))
		end
	end
	
end

return openmwcfg


