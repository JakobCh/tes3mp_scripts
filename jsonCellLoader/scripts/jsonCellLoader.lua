-- jsonCellLoader 1.0 for tes3mp 0.7-alpha

--[[ Installation:
* Put this file in mp-stuff/scripts (mp-stuff/scripts/jsonCellLoader.lua)
* Put the jsonimport folder in mp-stuff/data (mp-stuff/data/jsonimport)
* Put the creature.json and npc.json in mp-stuff/data if you dont already have them there from some other script
* Add [ jsonCellLoader = require("jsonCellLoader") ] to the top of serverCore.lua
* In commandHandler, add this to the elseif block of ProcessCommand:
	elseif cmd[1] == "loadjson" then
        jsonCellLoader.HandleCommand(pid, cmd)
]]--

--[[Usage:
	/loadjson <jsonname without extension>
	/loadjson BIG_TEST
	/loadjson Kneg, Level 1
]]--

--[[ Json format:

{
	"0":{
		"refId": "in_c_plain_room_corner",
		"location": {
			"posX": 0,
			"posY": -150,
			"posZ": 30,
			"rotX": 0,
			"rotY": 180,
			"rotZ": 0
		}
	},
	"1":{
		"refId": "atronach_frost",
		"location": {
			"posX": 256,
			"posY": 0,
			"posZ": -86,
			"rotX": 0,
			"rotY": 0,
			"rotZ": 0
		}
	},
	"2":{
		"refId": "dwrv_chest_Bam",
		"location": {
			"posX": 0,
			"posY": 0,
			"posZ": 0,
			"rotX": 0,
			"rotY": 0,
			"rotZ": 0
		},
		"inventory":[
			{"enchantmentCharge": -1, "refId": "p_restore_health_q", "count": 3, "charge": -1, "soul": ""},
			{"enchantmentCharge": -1, "refId": "exquisite_shoes_01", "count": 1, "charge": -1, "soul": ""}
		]
	}

}


]]--

jsonCellLoader = {}

jsonCellLoader.debug = false


-- Yes this is copied from WorldMining https://github.com/rickoff/Tes3mp-Ecarlate-Script/
-- which might or might not have been copied from kanaFurniture https://github.com/Atkana/tes3mp-scripts
-- or maybe its the other way around anyway we use this to check if a refId is a npc/creature
local creatureList = {}
local furnLoader = jsonInterface.load("recordstore/npc.json")
for index, item in pairs(furnLoader) do
	table.insert(creatureList, {name = item.Name, refId = item.ID, tip = "npc", need = "spawn"})
end
local furnLoader = jsonInterface.load("recordstore/creature.json")
for index, item in pairs(furnLoader) do
	table.insert(creatureList, {name = item.FIELD3, refId = item.FIELD2, tip = "creature", need = "spawn"} )
end


function jsonCellLoader.isCreature(refId)
	local isCreature = false
	for k,v in pairs(creatureList) do
		if creatureList[k].refId == refId then
			isCreature = true
		end
	end
	return isCreature
end

function jsonCellLoader.addObject(cell, refId, data)
	
	--get a new refIndex
	local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local refIndex = 0 .. "-" .. mpNum
	WorldInstance:SetCurrentMpNum(mpNum)
	tes3mp.SetCurrentMpNum(mpNum)

	--create a new object with the passed refid and the new refIndex we made
	cell:InitializeObjectData(refIndex, refId)

	--set the objects data to whatever we got passed
	cell.data.objectData[refIndex] = data

	--tes3mp.LogMessage(enumerations.log.INFO, "Adding object:" .. refId .. " at X:" .. data["location"]["posX"] .. " Y:" .. data["location"]["posY"] .. " Z:" .. data["location"]["posZ"])

	--add the object to diferent packats dippending on what type it is
	if jsonCellLoader.isCreature(refId) then
		table.insert(cell.data.packets.spawn, refIndex)
		table.insert(cell.data.packets.actorList, refIndex)
		tes3mp.LogMessage(enumerations.log.INFO, "Adding creature/npc:" .. refId .. " at X:" .. data["location"]["posX"] .. " Y:" .. data["location"]["posY"] .. " Z:" .. data["location"]["posZ"])
	elseif data["inventory"] ~= nil then --if the object has an inventory aka its a container
		table.insert(cell.data.packets.container, refIndex)
		table.insert(cell.data.packets.place, refIndex)
		tes3mp.LogMessage(enumerations.log.INFO, "Adding container:" .. refId .. " at X:" .. data["location"]["posX"] .. " Y:" .. data["location"]["posY"] .. " Z:" .. data["location"]["posZ"])
	else
		table.insert(cell.data.packets.place, refIndex)
		tes3mp.LogMessage(enumerations.log.INFO, "Adding object:" .. refId .. " at X:" .. data["location"]["posX"] .. " Y:" .. data["location"]["posY"] .. " Z:" .. data["location"]["posZ"])
	end

	--send object creating packages
	for pid, player in pairs(Players) do
		if player:IsLoggedIn() then
			--temp:LoadObjectsDeleted(pid, temp.data.objectData, goldUniqueIndexes)
			cell:LoadObjectsPlaced(pid, cell.data.objectData, {refIndex})
			if data["inventory"] ~= nil then
				cell:LoadContainers(pid, cell.data.objectData, {refIndex})
			end
		end
	end

	cell:Save()
end


function jsonCellLoader.HandleCommand(pid, cmd)
	if Players[pid]:IsAdmin() == false then
		tes3mp.SendMessage(pid, "Only admins can use this command\n")
		return false
	end


	local jsonName = tableHelper.concatenateFromIndex(cmd, 2)
	tes3mp.SendMessage(pid, "Trying to load: jsonimport/" .. jsonName .. ".json\n")
	local temp = jsonInterface.load("jsonimport/" .. jsonName .. ".json")
	if temp == nil then
		tes3mp.SendMessage(pid, "File doesn't exist\n")
		return false
	end

	local cell = LoadedCells[tes3mp.GetCell(pid)]
	-- add everything that isn't a creature
	for k,v in pairs(temp) do
		if jsonCellLoader.isCreature(temp[k]["refId"]) == false then
			jsonCellLoader.addObject(cell, temp[k]["refId"], temp[k])
		end
	end
	-- then add everything that is a creature
	-- this is to not make then fall thrue the floor when the floor isn't loaded
	for k,v in pairs(temp) do
		if jsonCellLoader.isCreature(temp[k]["refId"]) then
			jsonCellLoader.addObject(cell, temp[k]["refId"], temp[k])
		end
	end

end














return jsonCellLoader
