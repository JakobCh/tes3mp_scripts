

local doInfo = function(text)
	tes3mp.LogMessage(enumerations.log.INFO, text) 
end

doInfo("[espParserTest] Start")

--get all Misc ids
for _,subrecord in pairs(espParser.getAllSubRecords("MISC", "NAME")) do
	doInfo(subrecord.data)
end

--get all Book ids function
local getBookIds = function()
	local out = {}
	for _,subrecord in pairs(espParser.getAllSubRecords("BOOK", "NAME")) do
		table.insert(out, subrecord.data)
	end
	return out
end

--get all Creatures ids function
local getNPCIds = function()
	local out = {}
	for _,subrecord in pairs(espParser.getAllSubRecords("CREA", "NAME")) do
		table.insert(out, subrecord.data)
	end
	for _,subrecord in pairs(espParser.getAllSubRecords("NPC_", "NAME")) do
		table.insert(out, subrecord.data)
	end
	return out
end


--all LongBladeOneHand Weapons
require "custom.struct" --we're gonna need struct for this
for _,record in pairs(espParser.getAllRecords("WEAP")) do --go thru all weapon records
	
	local weaponName
	for _, subrecord in pairs(record.subRecords) do --go thru all subrecords
		if subrecord.name == "NAME" then
			weaponName = subrecord.data --pick up the name so we can print it later
		end
	
		if subrecord.name == "WPDT" then --weapon data subrecord
			local weaponType = struct.unpack( "H", string.sub(subrecord.data, 9, 9+2) ) -- 9 cus we want to skip two 4 byte values and the value we're grabing is a short (2 bytes) see https://en.uesp.net/morrow/tech/mw_esm.txt
			if weaponType == 1 then --if the weapontype is "1 = LongBladeOneHand"
				--print(subrecord.name)
				--print(weaponType)
				--print(weaponName .. ": " .. tostring(weaponType))
			end
		end
	end
end

--Get all misc item ids
--[[
for filename,records in pairs(espParser.files) do
	doInfo("Found file " .. filename)
	for _,record in pairs(records) do
		if record.name == "MISC" then
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					doInfo(subrecord.data)
				end
			end
		end
	end
end
]]

local out = {}
for filename,records in pairs(espParser.files) do
	out[filename] = {}
	for _, record in pairs(records) do
		if record.name == "CREA" or record.name == "NPC_" then
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					table.insert(out[filename], subrecord.data)
				end
			end
		end
	end
end

for _, id in pairs(out["Morrowind.esm"]) do
	print(id)
end

--[[
{
	"Morrowind.esm": ["creature_id", "npc_id"],
	"Tribunal.esm": [""]
}
]]--


doInfo("[espParserTest] End")

