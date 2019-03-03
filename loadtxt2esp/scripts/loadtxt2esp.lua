-- put this file in mp-stuff/scripts
-- Add [loadtxt2esp = require("loadtxt2esp")] to the top of serverCore.lua
-- Add [elseif cmd[1] == "loadtxt2esp" then loadtxt2esp.command(pid, cmd)] to like line 42 in commandHandler
--        


loadtxt2esp = {}

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function splitOnSpace(str)
	local splitLine = {}
	for i in string.gmatch(str, "%S+") do table.insert(splitLine, i) end --split the line
	return splitLine
end

function addObject(cell, refId, location, isCreature)

	local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local refIndex = 0 .. "-" .. mpNum
	WorldInstance:SetCurrentMpNum(mpNum)
	tes3mp.SetCurrentMpNum(mpNum)

	cell:InitializeObjectData(refIndex, refId)

	cell.data.objectData[refIndex]["location"] = location

	if isCreature then
		table.insert(cell.data.packets.spawn, refIndex)
		table.insert(cell.data.packets.actorList, refIndex)
		--print("Added creature:" .. refId)
		tes3mp.LogMessage(enumerations.log.INFO, "Added creature:" .. refId)
	else
		table.insert(cell.data.packets.place, refIndex)
	end

	for pid, player in pairs(Players) do
		if player:IsLoggedIn() then
			--temp:LoadObjectsDeleted(pid, temp.data.objectData, goldUniqueIndexes)
			cell:LoadObjectsPlaced(pid, cell.data.objectData, {refIndex})
		end
	end

	cell:Save()
end


function loadtxt2esp.command(pid, cmd)
	local filename = tableHelper.concatenateFromIndex(cmd, 2)
	local cell = LoadedCells[tes3mp.GetCell(pid)]

	tes3mp.SendMessage(pid, tes3mp.GetModDir() .. "\\txt2esp\\" .. filename .. ".txt")

	local f = io.open(tes3mp.GetModDir() .. "\\txt2esp\\" .. filename .. ".txt", "r")
	if f == nil then
		tes3mp.SendMessage(pid, "Couldn't find a file with that name\n")
		return false
	end

	for line in f:lines() do
		if string.sub(line, 1, 1) ~= ";" then 
			
			local refId = string.match(line, '"(.-)"')
			if refId ~= nil then
				tes3mp.SendMessage(pid, refId .. "\n")
				local scale = string.match(line, '"%s(%d+)%s')
				tes3mp.SendMessage(pid, scale .. "\n")

				if string.starts(line, "tel_door_ref") then
					--special shit if its a door
					
				else
					local rotString = string.match(line, '"%s%d+%s<(.-)>') -- Example: "0 180 -240"
					local posString = string.match(line, '>%s<(.-)>') -- Example: "-2400 5800 -24000"
					--tes3mp.SendMessage(pid, "Rotation: " .. rotString .. "\n")
					--tes3mp.SendMessage(pid, "Position: " .. posString .. "\n")

					-- Apperently the game uses Radian instead of degrees
					local temp = splitOnSpace(rotString)
					local rotX = tonumber(temp[1]) * (3.14/180)
					local rotY = tonumber(temp[2]) * (3.14/180)
					local rotZ = tonumber(temp[3]) * (3.14/180)

					local temp = splitOnSpace(posString)
					local posX = tonumber(temp[1])
					local posY = tonumber(temp[2])
					local posZ = tonumber(temp[3])
					tes3mp.SendMessage(pid, "Rotation: " .. rotX .. " " .. rotY .. " " .. rotZ .. "\n")
					tes3mp.SendMessage(pid, "Position: " .. posX .. " " .. posY .. " " .. posZ .. "\n")
					
					local location = {}
					location["posX"] = posX
					location["posY"] = posY
					location["posZ"] = posZ
					location["rotX"] = rotX
					location["rotY"] = rotY
					location["rotZ"] = rotZ
					
					if string.starts(line, "reference") then
						addObject(cell, refId, location, false)
					else
						addObject(cell, refId, location, true)
					end
					
				end
			end
			

			--local splitLine = {}
			--for i in string.gmatch(line, "%S+") do table.insert(splitLine, i) end --split the line

			--[[if #splitLine > 1 then
				tes3mp.SendMessage(pid, splitLine[1] .. " " .. splitLine[2] .. "\n")

				if splitLine[1] == "reference" then

					local refId = splitLine[2]
					local scale = splitLine[3]
				end
			end]]--
		end
	end
	
	io.close(f)

end





return loadtxt2esp