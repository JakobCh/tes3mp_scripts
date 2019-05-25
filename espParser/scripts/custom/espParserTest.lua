

local doInfo = function(text)
	tes3mp.LogMessage(enumerations.log.INFO, text) 
end

doInfo("[espParserTest] Start")

--get all Misc ids
for _,subrecord in pairs(espParser.getAllSubRecords("MISC", "NAME")) do
	doInfo(subrecord.data)
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
				print(weaponName .. ": " .. tostring(weaponType))
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


doInfo("[espParserTest] End")