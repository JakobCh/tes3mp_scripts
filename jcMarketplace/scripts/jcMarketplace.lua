--[[
Version: 0.6 for 0.7-alpha
Requires kanaHousing basically

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.jcMarketplace") ] in customScripts.lua

Commands:
    /market: info on the current market

    /marketadd
    /market add
    /marketcreate
    /market create: Set the current cell as your market

    /marketremove
    /market remove
    /marketdelete
    /market delete: Remove your market from the current cell

    /marketlog
    /market log
    /marketmessages
    /market messages: List all your sales

    /marketclearlog
    /market clearlog: Clear your message log
	
	/marketjcinfo: will give you some debug info

Good to know:
    When you're inside a cell you own you can crouch+activate a droped item to set it's price.
    When a guest is inside a cell that's owned by someone they can't pick up anything that's been droped.
    When a guest tries to activate a droped item and that item has a price set they can buy it.
    Money will be transfered to the owned ever if they're offline.
]]

local Config = {}
Config.kanaHouseIntergration = true --if you have this of anyone can create a market in any interior cell
Config.GUIMain = 1190
Config.GUIItem = 1191
Config.GUIPrice = 1192

--all ref ids that the script wont block in market cells
--keep in mind this uses string.match/contains
Config.NonBlockedRedIds = {
    "door", --doors 
    "player_note_" --custom notes
}
Config.BlockDefaultObjects = true --if this is true the script also blocks all normaly present objects from being interacted with, by default the script only blocks player placed items

local DATA = jsonInterface.load("custom/marketplaceData.json")
if DATA == nil then
    DATA = {}
end

local save = function()
	jsonInterface.save("custom/marketplaceData.json", DATA)
end

local SELECTED = {} --items selected by players


local msg = function(pid, text)
    if text == nil then --Apparently this has happened once
        text = "Msg Error, please report what you were doing to Kneg."
        tes3mp.LogMessage(enumerations.log.ERROR, "[Marketplace] msg called with nil text") 
        tes3mp.LogMessage(enumerations.log.ERROR, debug.traceback()) 
    end
	tes3mp.SendMessage(pid, color.GreenYellow .. "[Marketplace] " .. color.Default .. text .. "\n" .. color.Default)
end


local split = function(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local name2pid = function(name)
	local name = name:lower()
	for pid,_ in pairs(Players) do
		if string.lower(Players[pid].accountName) == name then
			return pid
		end
	end
	return nil
end

local checkMarketAndOwn = function(cell, name)
    if DATA[cell] == nil then
        msg(pid, "There's not a market here.")
        return false
    end

    if DATA[cell]["owner"] ~= name then
        msg(pid, "You dont own this market.")
        return false
    end
    return true
end

local ownsCell = function(name, cell)
    if DATA[cell] == nil then return false end

    if DATA[cell]["owner"] == name then
        return true
    else
        return false
    end
end

local name2cell = function(name)
    for key,_ in pairs(DATA) do
        if DATA[key]["owner"] == name then
            return key
        end
    end
    return nil
end

--Returns the amount of gold in a player's inventory
local getPlayerGold = function(pid)
	local goldLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, "gold_001", -1)
	
	if goldLoc then
		return Players[pid].data.inventory[goldLoc].count
	else
		return 0
	end
end

--fake player so I can give them money when they're offline
local fakePlayer = function(name)
    local player = {}
    local accountName = fileHelper.fixFilename(name)
    player.accountFile = tes3mp.GetCaseInsensitiveFilename(tes3mp.GetModDir() .. "/player/", accountName .. ".json")

    if player.accountFile == "invalid" then
        tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] WARNING fakePlayer called with invalid name!")
        return
    end

    player.data = jsonInterface.load("player/" .. player.accountFile)

    function player:Save()
        local config = require("config")
        jsonInterface.save("player/" .. self.accountFile, self.data, config.playerKeyOrder)
    end

    return player
end

--add the purchased item to the player
local addItem = function(pid, refIndex)
    local cell = tes3mp.GetCell(pid)
    local _refId = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]
    local amount = LoadedCells[cell]["data"]["objectData"][refIndex]["count"]
    if amount == nil then
        amount = 1
    end
    local item = LoadedCells[cell]["data"]["objectData"][refIndex]

    --msg(pid, "BUYING " .. _refId .. "!!")

    local itemLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, _refId, -1) --find the item in the players inventory
    if itemLoc then --if the player already has that item in there inventory
        Players[pid].data.inventory[itemLoc].count = Players[pid].data.inventory[itemLoc].count + amount --add to there already existing item stack
    else
        table.insert(Players[pid].data.inventory, {refId = _refId, count = amount}) --add new item to players inventory
    end

    --remove the item from the cell
    local uniqueIndexes = { refIndex }
    for pid, ply in pairs(Players) do
        if ply:IsLoggedIn() then
            LoadedCells[cell]:LoadObjectsDeleted(pid, LoadedCells[cell]["data"]["objectData"], uniqueIndexes)
        end
    end
    LoadedCells[cell]["data"]["objectData"][refIndex] = nil
    LoadedCells[cell]:Save()

    --remove the item from out data
    DATA[cell]["items"][refIndex] = nil

    --the player should always be logged in 
	Players[pid]:Save()
	Players[pid]:LoadInventory()
    Players[pid]:LoadEquipment()
end

local addGold = function(name, amount)
    local pid = name2pid(name)
    local accountFile = ""
    local player = {}
    if pid == nil then -- if the player isn't logged in 
        player = fakePlayer(name)
    else
        player = logicHandler.GetPlayerByName(name) --tecnicaly you can use this for offline players aswell but the save function doesn't work see: https://github.com/TES3MP/CoreScripts/pull/73
    end
    

	local goldLoc = inventoryHelper.getItemIndex(player.data.inventory, "gold_001", -1) --get the location of gold in the players inventory
	
	if goldLoc then --if the player already has gold in there inventory
		player.data.inventory[goldLoc].count = player.data.inventory[goldLoc].count + amount --add the new gold onto his already existing stack
	else
		table.insert(player.data.inventory, {refId = "gold_001", count = amount, charge = -1}) --create a new stack of gold
    end
    
    
    player:Save()

end

--the menu when you activate an item
local GUIItem = function(pid, refIndex)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local isOwner = ownsCell(name, cell)
    if LoadedCells[cell]["data"]["objectData"][refIndex] == nil then return end
    local itemName = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]

    local message = "Item: " .. itemName
    local currentPrice = DATA[cell]["items"][refIndex]
    if currentPrice ~= nil then
        message = message .. "\nCurrent price: " .. tostring(currentPrice)
    end

    if isOwner then
        tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Set Price;Clear Price;Exit")
    else
        if DATA[cell]["items"][refIndex] ~= nil then --if the activated item is for sale
            local price = DATA[cell]["items"][refIndex]
            message = message .. "\nPrice: " .. tostring(price)
            tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Buy;Exit")
        end
    end

    --if DATA[cell]["items"][refIndex] ~= nil then
    
    --tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Buy;Exit")
end

--the price setting menu
local GUIPrice = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local refIndex = SELECTED[name]
    local itemName = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]

    local message = "Item: " .. itemName .. "\nSet price too:"
    tes3mp.InputDialog(pid, Config.GUIPrice, message, "")
end

--when you remove the price from an item
--originaly I didn't have this cus you can just pick up the item and place it down again but I thought it would probably be a good idea
local clearItemPrice = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)

    if SELECTED[name] == nil then return end

    DATA[cell]["items"][SELECTED[name]] = nil
    msg(pid, "Item " .. SELECTED[name] .. "'s price has been cleared.")
    SELECTED[name] = nil
end

--When you click the buy item button 
local buyItem = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local playerGold = getPlayerGold(pid)
    local cost = DATA[cell]["items"][SELECTED[name]]
    if cost > playerGold then
        msg(pid, "You dont have enoght gold to buy this item.")
        return
    end

    local itemName = LoadedCells[cell]["data"]["objectData"][SELECTED[name]]["refId"]
    local ownerName = DATA[cell]["owner"]
    local ownerPid = name2pid(ownerName)
    if ownerPid ~= nil then --owner is online
        msg(ownerPid, name .. " bought " .. itemName .. " from you for " .. tostring(cost) .. "!")
    end

    --add message to messages/log
    local time = os.date("%Y-%m-%d %I:%M:%S")
    table.insert(DATA[cell]["messages"], time .. ": " .. name .. " bought " .. itemName .. " from you for " .. tostring(cost) .. " gold!")

    addGold(ownerName, cost) --add gold to the owner
    addGold(name, -cost) --remove gold from the buyer
    addItem(pid, SELECTED[name]) --add the item to the buyers inventory
                
    msg(pid, "You've bought the " .. itemName .. "!")
    SELECTED[name] = nil
    save()
end

--when you type /marketadd/marketcreate
local marketCreate = function(pid)
    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    if LoadedCells[cell].isExterior then --dont allow markets in external cells
        msg(pid, "You can't make a market in an exterior cell.")
        return
    end

    if DATA[cell] ~= nil then --we already have data about a market here
        msg(pid, "There already exists a market here.")
        return
    end
    
    --kanaHousing, I really dont see why you would use this whitout it
    if Config.kanaHouseIntergration and kanaHousing ~= nil then --if kanaHousing is installed

        --make sure its a house registered with kanaHousing
        if kanaHousing.GetCellData(cell) == false or kanaHousing.GetCellData(cell).house == nil then
            msg(pid, "This isn't a kanaHouse.")
            return
        end
        
        --check if the house owner is false aka noone owns the house
        if kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house) == false then
            msg(pid, "You don't own this house. 1")
            return
        end

        --check if the current player owns the house
        if kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house) ~= name then
            msg(pid, "You don't own this house. 2")
            return
        end

    end
    --kanaHousing.GetOwnerData(name)

    --create a new market
    DATA[cell] = {}
    DATA[cell]["owner"] = name
    DATA[cell]["items"] = {}
    DATA[cell]["messages"] = {}
    msg(pid, "Market created!")
    save()
    --isExterior
end

--when you use /market delete /market remove
local marketDelete = function(pid)
    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)

    if Players[pid]:IsAdmin() then --if they're an admin they can just delete all markets
        DATA[cell] = nil
        msg(pid, "[Admin] Market removed.")
        save()
        return
    end

    if not checkMarketAndOwn(cell, name) then return end

    DATA[cell] = nil
    msg(pid, "Market removed.")
    save()
end

--just print out all the messages in the logs
local marketLog = function(pid)
	local name = string.lower(Players[pid].accountName)
    local ownedCell = name2cell(name)
    if ownedCell == nil then
        msg(pid, "You don't own a market.")
        return
    end

    msg(pid, "----START----")
    for _,message in pairs(DATA[ownedCell]["messages"]) do
        if message ~= nil then
            msg(pid, message)
        end
    end
    msg(pid, "----END----")

end

--clear the log, maybe put a confirmation here
local marketClearLog = function(pid)
    local name = string.lower(Players[pid].accountName)
    local ownedCell = name2cell(name)

    if ownedCell == nil then 
        msg(pid, "You don't own a market.")
        return
    end

    DATA[ownedCell]["messages"] = nil --rip, atleast you still have your money
    msg(pid, "Log cleared.")
end

customCommandHooks.registerCommand("marketadd", marketCreate)
customCommandHooks.registerCommand("marketcreate", marketCreate)

customCommandHooks.registerCommand("marketremove", marketDelete)
customCommandHooks.registerCommand("marketdelete", marketDelete)

customCommandHooks.registerCommand("marketlog", marketLog)
customCommandHooks.registerCommand("marketmessages", marketLog)

customCommandHooks.registerCommand("marketclearlog", marketClearLog)

customCommandHooks.registerCommand("marketjcinfo", function(pid,cmd)

    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    local temp 

    temp = kanaHousing.GetCellData(cell)
    if temp == false then return end
    msg(pid, tostring(temp))

    temp = kanaHousing.GetCellData(cell).house
    if temp == false then return end
    msg(pid, tostring(temp))

    temp = kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house)
    if temp == false then return end
    msg(pid, tostring(temp))

    msg(pid, name)

end)

customCommandHooks.registerCommand("market", function(pid, cmd)
    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    
    if cmd[2] == nil then
        if DATA[cell] ~= nil then
            msg(pid, "There's a market owned by " .. DATA[cell]["owner"] .. " here.")
        else
            msg(pid, "There's no market here, use /marketcreate or /marketadd to create a market here.")
        end
    elseif cmd[2] == "add" or cmd[2] == "create" then
        marketCreate(pid)
    elseif cmd[2] == "remove" or cmd[2] == "delete" then
        marketDelete(pid)
    elseif cmd[2] == "log" or cmd[2] == "messages" then
        marketLog(pid)
    elseif cmd[2] == "clearlog" then
        marketClearLog(pid)
    end

end)


-- This should block all object deletes
customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
    local name = string.lower(Players[pid].accountName)

    if DATA[cellDescription] == nil then --its not in a cell we care about
        return
    end

    for n,object in pairs(objects) do
        local temp = split(object.uniqueIndex, "-")
        local RefNum = temp[1]
        local MpNum = temp[2]

        --dont block refIds in the NonBlocked list
        for _, refId in pairs(Config.NonBlockedRedIds) do
            if string.match(object.refId, refId) then
                return
            end
        end

        if DATA[cellDescription]["owner"] == name then --if its the owner of the cell they can do whatever they want
            if tes3mp.GetSneakState(pid) then -- they're crouching, open the item menu
                GUIItem(pid, object.uniqueIndex)
                SELECTED[name] = object.uniqueIndex
                eventStatus.validDefaultHandler = false
                return eventStatus
            end
            return
        end

        if tonumber(RefNum) == 0 then --its a placed item
            GUIItem(pid, object.uniqueIndex)
            SELECTED[name] = object.uniqueIndex
            eventStatus.validDefaultHandler = false
            return eventStatus
        end

        --block default objects
        if Config.BlockDefaultObjects and tonumber(MpNum) == 0 then
            eventStatus.validDefaultHandler = false
            return eventStatus
        end
    end

    return eventStatus
end)

customEventHooks.registerValidator("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)
	local name = string.lower(Players[pid].accountName)

    if DATA[cellDescription] == nil then --its not in a cell we care about
        return
    end

    for n,object in pairs(objects) do
        local temp = split(object.uniqueIndex, "-")
        local RefNum = temp[1]
        local MpNum = temp[2]

        if string.match(object.refId, "door") then --if its a door we probably dont want to block it
            return
        end

        if DATA[cellDescription]["owner"] == name then --if its the owner of the cell they can do whatever they want
            return
        end

        if tonumber(RefNum) == 0 then --its a placed item
            --delete the item from the players inventory
            logicHandler.RunConsoleCommandOnPlayer(pid, "player->removeitem \"" .. object.refId .. "\", 1")

            eventStatus.validDefaultHandler = false
            return eventStatus
        end
    end

    return eventStatus
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local isOwner = ownsCell(name, cell)

    if idGui == Config.GUIItem then
        if isOwner then
            if tonumber(data) == 0 then
                GUIPrice(pid)
            elseif tonumber(data) == 1 then
                clearItemPrice(pid)
            end
        else
            if tonumber(data) == 0 then -- were buying the item
                buyItem(pid)
            end
        end
    elseif idGui == Config.GUIPrice then -- we've set a price on an item
        if tonumber(data) == nil then
            msg(pid, "You didn't enter a valid number.")
        else
            local newPrice = tonumber(data)

            if SELECTED[name] == nil then --this really shouldn't happen but apparently it has
                tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] Someone tried to set the price of an item but haven't actually selected an item.")
                return
            end

            if DATA[cell] == nil then --this really shouldn't happen but apparently it has
                tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] Someone tried to set the price of an item in a non market cell.")
                return
            end

            DATA[cell]["items"][SELECTED[name]] = newPrice
            msg(pid, "Item " .. SELECTED[name] .. "'s price has been set to " .. tostring(data) .. ".")
            SELECTED[name] = nil
            save()
        end
    end

end)


--customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid) 
--end)
