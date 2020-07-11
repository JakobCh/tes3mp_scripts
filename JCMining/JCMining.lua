-- JcMining 0.1 by Jakob
-- Made 2020-07-11

-- Makes players mine ores over a period of time

-- Install:
--     put this file in scripts/custom/
--     open up scripts/customscripts.lua and add "require("custom.JCMining")"


local function msg(pid, text)
	tes3mp.SendMessage(pid, color.Aqua .. "[JCMining] " .. color.Default .. text .. "\n" .. color.Default)
end

local function log(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[JCMining] " .. text)
end

JCMining = {}

JCMining.oreRespawn = 1000 --Amount in seconds that ore takes to respawn

JCMining.timerId = nil --used to keep track of the timer

JCMining.typeToItem = {
	ebony = "ingred_raw_ebony_01",
	glass = "ingred_raw_glass_01",
	diamond = "ingred_diamond_01"
}

--STORED ORES
JCMining.storedOres = {} --used to keep track of all ores in the world and what state they're in

JCMining.addOre = function(refId, uniqueIndex, cellDescription)
	if JCMining.storedOres[cellDescription] == nil then
		JCMining.storedOres[cellDescription] = {}
	end
	if JCMining.storedOres[cellDescription][uniqueIndex] ~= nil then --the ore already exists
		return
	end

	JCMining.storedOres[cellDescription][uniqueIndex] = {}
	JCMining.storedOres[cellDescription][uniqueIndex].refId = refId
	JCMining.storedOres[cellDescription][uniqueIndex].lastMined = 0
end

JCMining.canMineOre = function(uniqueIndex, cellDescription)
	if JCMining.storedOres[cellDescription] == nil then return false end
	if JCMining.storedOres[cellDescription][uniqueIndex] == nil then return false end

	--log("canMineOre")
	--log(tostring(JCMining.storedOres[cellDescription][uniqueIndex].lastMined))
	--log(tostring(os.time() + JCMining.oreRespawn))

	if JCMining.storedOres[cellDescription][uniqueIndex].lastMined + JCMining.oreRespawn < os.time() then
		return true
	end
	return false
end

JCMining.depleteOre = function(uniqueIndex, cellDescription)
	--log("deplet ore1")
	if JCMining.storedOres[cellDescription] == nil then
		--log("deplet ore2 " .. cellDescription)
		return false
	end
	if JCMining.storedOres[cellDescription][uniqueIndex] == nil then
		--log("deplet ore3 " .. uniqueIndex)
		return false
	end
	--log("depleting ore " .. uniqueIndex)
	JCMining.storedOres[cellDescription][uniqueIndex].lastMined = os.time()
	return true
end

--END STORED ORES

--MINERS
JCMining.currentlyMining = {}

JCMining.addMiner = function(pid, type, uniqueIndex, cellDescription)
	JCMining.currentlyMining[pid] = {}
	JCMining.currentlyMining[pid].uniqueIndex = uniqueIndex
	JCMining.currentlyMining[pid].cellDescription = cellDescription
	JCMining.currentlyMining[pid].type = type
	JCMining.currentlyMining[pid].pos = {
		x=tes3mp.GetPosX(pid),
		y=tes3mp.GetPosY(pid)
	}
	log(logicHandler.GetChatName(pid) .. " started mining " .. uniqueIndex)
end

JCMining.delMinerPid = function(pid)
	JCMining.currentlyMining[pid] = nil
end
--END MINERS



JCMining_TimerFunc = function()
	--tes3mp.LogMessage(enumerations.log.INFO, "JCMining TimerFunc!")

	for pid, info in pairs(JCMining.currentlyMining) do

		--if you move you stop mining
		if info.pos.x ~= tes3mp.GetPosX(pid) or info.pos.y ~= tes3mp.GetPosY(pid) then
			msg(pid, color.Red .. "You moved!")
			JCMining.delMinerPid(pid)
		elseif math.random(0,3) == 0 then --random chance to ore to dry up
			msg(pid, color.Red .. "The ore ran out!")
			JCMining.depleteOre(info.uniqueIndex, info.cellDescription)
			JCMining.delMinerPid(pid)
		else
			local itemRefId = JCMining.typeToItem[info.type]
			--msg(pid, color.Green .. "You mined some " .. itemRefId .. "!")
			--tes3mp.PlayAnimation(pid, "Slash Start", 0, 1, false) --TODO
			tes3mp.MessageBox(pid, -1, "You mine some " .. info.type .. ".")
			logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound Repair", false)
			inventoryHelper.addItem(Players[pid].data.inventory, itemRefId, 1, -1, -1, -1)
			Players[pid]:LoadInventory()
			Players[pid]:LoadEquipment()
			Players[pid]:LoadQuickKeys()
		end
	end

	tes3mp.RestartTimer(JCMining.timerId, time.seconds(3))
end

customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players) 
	for _,object in pairs(objects) do
		if object.pid == nil and object.activatingPid ~= nil then
			local refId = object.refId

			local t = string.match(refId, "^rock_(.-)_%d%d")
			if t ~= nil then
				JCMining.addOre(refId, object.uniqueIndex, cellDescription)
				if JCMining.canMineOre(object.uniqueIndex, cellDescription) then
					JCMining.addMiner(object.activatingPid, t, object.uniqueIndex, cellDescription)
					msg(object.activatingPid, color.Green .. "You start mining some " .. t .. "!")
				else
					msg(object.activatingPid, color.Red .. "That vain is empty.")
				end
				return customEventHooks.makeEventStatus(false, false)
			end
		end
	end
	return eventStatus
end)



customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	JCMining.timerId = tes3mp.CreateTimer("JCMining_TimerFunc", time.seconds(3))
    tes3mp.StartTimer(JCMining.timerId)
end)

-- 0.7.1 shoot bro
--[[
customEventHooks.registerHandler("OnObjectHit" function(eventStatus, pid, cellDescription, objects, targetPlayers)
	for _,obj in pairs(objects) do
		local refId = obj.refId
		local t = string.match(refId, "^rock_(.-)_%d%d")
		if t ~= nil then
			msg(pid, "You mined some " .. t .. "!")

			local itemRefId = JCMining.typeToItem[t]
			inventoryHelper.addItem(Players[pid].data.inventory, itemRefId, 1, -1, -1, -1)
		end
	end
end)
]]