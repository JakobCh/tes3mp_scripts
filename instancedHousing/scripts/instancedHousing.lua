--[[

Name: instancedHousing
Version: 0.2
Tes3mp Version: 0.8.1
Author: JakobCh
Last update: 2023-07-12

Description:
    Instanced player housing
    Create a template then coc into it to change it,
    then when a player creates a house from it it will have the changes in the template

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.instancedHousing") ] in server/scripts/customScripts.lua

Commands:
    /ihouse
    /ihouse template <id> <fancy name>: used by staff to create house templates
    /ihouse create <id>: used by players to create a house from a template
    /ihouse delete: used by players to delete there house
    /ihouse templatedelete: used by staff to remove templates
    /ihouse home: teleports a player to there house
    /ihouse list: lists all the templates

Known issues/TODO:
    This is the first release please let me know if something doesn't work.
    Sometimes houses doesn't reflect the changes from the template
]]

--Config
local chatCommand = "ihouse"
local chatPretextColor = color.GreenYellow
local savelocation = "custom/instancedHousing.json"
--cell prefixes
local templatePrefix = "ihouse_template_"
local housePrefix = "ihouse_house_"

-- don't edit below this line

local msg = function(pid, text)
	tes3mp.SendMessage(pid, chatPretextColor .. "[InstancedHousing] " .. color.Default .. tostring(text) .. "\n" .. color.Default)
end

local info = function(text)
    tes3mp.LogMessage(enumerations.log.INFO, "[InstancedHousing] " .. tostring(text))
end

local warn = function(text)
    tes3mp.LogMessage(enumerations.log.WARN, "[InstancedHousing] " .. tostring(text))
end

local warnAndMsg = function(pid, text)
    tes3mp.LogMessage(enumerations.log.WARN, "[InstancedHousing] " .. tostring(text))
    tes3mp.SendMessage(pid, chatPretextColor .. "[InstancedHousing] " .. color.Default .. tostring(text) .. "\n" .. color.Default)
end

---Takes a cell id / cellDescription and returns the file path
---@param cellId string
---@return string
local getCellFilePath = function(cellId)
    return tes3mp.GetCaseInsensitiveFilename(config.dataPath .. "/cell/", cellId .. ".json")
end

--debug commands
customCommandHooks.registerCommand("listloadedcells", function(pid, cmd)
    for i,v in pairs(LoadedCells) do
        msg(pid, tostring(i))
    end
end)




local instancedHousing = {}
instancedHousing.data = {} --What we store in the json file

-- instancedHousing.data.houses = {}
-- instancedHousing.data.templates = {}


instancedHousing.save = function()
    jsonInterface.save(savelocation, instancedHousing.data)
end

instancedHousing.load = function()
    instancedHousing.data = jsonInterface.load(savelocation)
    if instancedHousing.data == nil then
        --json format
        instancedHousing.data = {}
        instancedHousing.data.houses = {}
        instancedHousing.data.templates = {}
    end
end

---Takes a pid and returns the players name in the format instancedHousing expects
---@param pid number
---@return string
instancedHousing.pidToName = function(pid)
    return string.lower(Players[pid].accountName)
end

---Returns true if the player has a house
---@param playerName string
---@return boolean
instancedHousing.playerHasHouse = function(playerName)
    return instancedHousing.data.houses[playerName] ~= nil
end

---Creates a house for a player from a template id
---@param playerName string
---@param shortTemplateId string The full template id "ihouse_template_test1"
---@return boolean
instancedHousing.createHouse = function(playerName, shortTemplateId)

    local cellId = housePrefix .. playerName --the id of the new cell
    local templateId = templatePrefix .. shortTemplateId
    local recordStore = RecordStores["cell"]
    local template = instancedHousing.data.templates[templateId]
    local templateCell = recordStore.data.permanentRecords[templateId]

    if instancedHousing.playerHasHouse(playerName) then
        warn("Player already has a house.")
        return false
    end

    if template == nil then
        warn("Invalid template id.")
        return false
    end

    if templateCell == nil then
        warn("The template cell doesn't exist! (this shouldn't happen)")
        return false
    end

    --Add to the record store
    recordStore.data.permanentRecords[cellId] = {baseId=template.baseId}
    recordStore:QuicksaveToDrive()
    recordStore:LoadRecords(0, recordStore.data.permanentRecords, tableHelper.getArrayFromIndexes(recordStore.data.permanentRecords), true)


    instancedHousing.data.houses[playerName] = {
        id=cellId,
        baseId=template.baseId,
        spawn=template.spawn,
        name=template.name --TODO change the name to: "Player's House" ?
    }
    instancedHousing.save()

    --copy template
    local temp = jsonInterface.load("cell/" .. templateId .. ".json")
    temp.entry.description = cellId
    jsonInterface.save("cell/" .. cellId .. ".json", temp)

    info("Created new house for player: " .. playerName)

    return true
end

---Used to create a template cell
---@param pid number The player making the template ofc
---@param shortTemplateId string The short id of the template you want to create "test1", "farm_house"
---@param templateName string The display name of the template
---@return boolean If the template got created or not
instancedHousing.createTemplate = function(pid, shortTemplateId, templateName)

    local player = Players[pid]

    if shortTemplateId == nil or shortTemplateId == "" or shortTemplateId:find(" ") then
        warnAndMsg(pid, "Invalid short template id: \"" .. shortTemplateId .. "\"")
        return false
    end

    local templateId = templatePrefix .. shortTemplateId

    if instancedHousing.data.templates[templateId] then
        warnAndMsg(pid, "Template id already exists: \"" .. templateId .. "\"")
        return false
    end

    local newRecord = {}
    newRecord.baseId = player.data.location.cell
    newRecord.id = templateId
    newRecord.shortId = shortTemplateId
    newRecord.name = templateName
    newRecord.spawn = {
        posX=tes3mp.GetPosX(pid),
        posY=tes3mp.GetPosY(pid),
        posZ=tes3mp.GetPosZ(pid),
        rotX=tes3mp.GetRotX(pid),
        rotZ=tes3mp.GetRotZ(pid)
    }

    instancedHousing.data.templates[newRecord.id] = newRecord
    instancedHousing.save()

    --Add to the record store
    local recordStore = RecordStores["cell"]

    recordStore.data.permanentRecords[newRecord.id] = {baseId=newRecord.baseId} --it only needs a baseId in it
    recordStore:QuicksaveToDrive()
    recordStore:LoadRecords(pid, recordStore.data.permanentRecords, tableHelper.getArrayFromIndexes(recordStore.data.permanentRecords), true)

    msg(pid, "Added a template with id: " .. newRecord.id)
    msg(pid, "with baseId: " .. newRecord.baseId)
    msg(pid, "with name: " .. templateName)

    return true
end

---It teleports a player to there house if they have one wow!
---@param pid number
instancedHousing.teleportPlayerToThereHouse = function(pid)
    local playerName = instancedHousing.pidToName(pid)
    local house = instancedHousing.data.houses[playerName]

    if house == nil then
        msg(pid, "You don't have a house.")
        return
    end

    tes3mp.SetCell(pid, house.id)
	tes3mp.SendCell(pid)

	tes3mp.SetPos(pid, house.spawn.posX, house.spawn.posY, house.spawn.posZ)
    tes3mp.SetRot(pid, house.spawn.rotX, house.spawn.rotZ)
	tes3mp.SendPos(pid)

end

---Remove a persons house
---@param playerName string
---@return boolean
instancedHousing.deleteHouse = function(playerName)

    if not instancedHousing.playerHasHouse(playerName) then
        warn(playerName .. " doesn't have a house.")
        return false
    end

    local cellId = instancedHousing.data.houses[playerName].id
    local recordStore = RecordStores["cell"]

    logicHandler.UnloadCell(cellId) --saves the file to disk then frees it from memory

    recordStore.data.permanentRecords[cellId] = nil --remove the custom record
    recordStore:QuicksaveToDrive()
    recordStore:LoadRecords(0, recordStore.data.permanentRecords, tableHelper.getArrayFromIndexes(recordStore.data.permanentRecords), true)

    instancedHousing.data.houses[playerName] = nil --remove our data
    instancedHousing.save()

    local filename = getCellFilePath(cellId)
    os.remove(filename)

    info(playerName .. "'s house deleted!")

    return true
end

---Removes a template cell
---@param shortTemplateId string
---@return boolean
instancedHousing.deleteTemplate = function(shortTemplateId)

    local templateId = templatePrefix .. shortTemplateId

    if not instancedHousing.data.templates[templateId] then
        warn("Tried to delete template that doesn't exist: " .. templateId)
        return false
    end

    instancedHousing.data.templates[templateId] = nil
    instancedHousing.save()

    local recordStore = RecordStores["cell"]
    recordStore.data.permanentRecords[templateId] = nil --it only needs a baseId in it
    recordStore:QuicksaveToDrive()
    recordStore:LoadRecords(0, recordStore.data.permanentRecords, tableHelper.getArrayFromIndexes(recordStore.data.permanentRecords), true)


    local filename = getCellFilePath(templateId)
    os.remove(filename)
    return true
end

--COMMANDS
instancedHousing.subCommands = {} --keyed with cmd2

instancedHousing.subCommands.template = function(pid, cmd)
    --command to add a new template

    if not Players[pid]:IsAdmin() then
        msg(pid, "This is an admin only command.")
        return
    end

    if cmd[4] == nil then
        msg(pid, "Usage: template <id> <fancy name>")
        msg(pid, "       <id> can only be one word")
        return
    end

    local player = Players[pid]
    local shortTemplateId = cmd[3]
    local templateName = tableHelper.concatenateFromIndex(cmd, 4)

    instancedHousing.createTemplate(pid, shortTemplateId, templateName)
end

instancedHousing.subCommands.create = function(pid, cmd)
    --command to create a house for the current player from a template

    if cmd[3] == nil then
        msg(pid, "Usage: create <id>")
        return
    end

    local player = Players[pid]
    local playerName = string.lower(player.accountName)
    local templateId = templatePrefix .. cmd[3]
    local recordStore = RecordStores["cell"]
    local template = instancedHousing.data.templates[templateId]
    local templateCell = recordStore.data.permanentRecords[templateId]

    if instancedHousing.data.houses[playerName] then
        msg(pid, "You already have a house!")
        return
    end

    if template == nil then
        msg(pid, "Invalid template id.")
        return
    end

    if templateCell == nil then
        msg(pid, "The template cell doesn't exist! (this shouldn't happen)")
        return
    end

    instancedHousing.createHouse(playerName, cmd[3])
    msg(pid, "House created!")
end

instancedHousing.subCommands.home = function(pid, cmd)
    instancedHousing.teleportPlayerToThereHouse(pid)
end

instancedHousing.subCommands.delete = function(pid, cmd)

    local playerName = instancedHousing.pidToName(pid)

    if not instancedHousing.playerHasHouse(playerName) then
        msg(pid, "You don't have a house!")
        return
    end

    local cellId = instancedHousing.data.houses[playerName].id

    --I rather not bother with kicking the player out
    if LoadedCells[cellId] then
        msg(pid, "Please exit your house first.")
        return
    end
    
    instancedHousing.deleteHouse(playerName)

    msg(pid, "House deleted!")
end

instancedHousing.subCommands.templatedelete = function(pid, cmd)
    
    if not Players[pid]:IsAdmin() then
        msg(pid, "This is an admin only command.")
        return
    end
    
    if cmd[3] == nil then
        msg(pid, "Usage: templatedelete <id>")
        return
    end

    local templateId = templatePrefix .. cmd[3]
    if not instancedHousing.data.templates[templateId] then
        msg(pid, "That template doesn't exist!")
        return
    end

    if instancedHousing.deleteTemplate(cmd[3]) then
        msg(pid, "Template deleted.")
    else
        msg(pid, "Template couldn't be deleted. Check server logs.")
    end
end

instancedHousing.subCommands.list = function(pid,cmd)
    for i,v in pairs(instancedHousing.data.templates) do
        msg(pid, v.shortId .. ":" .. v.name)
    end
end

--COMMAND HOOK
customCommandHooks.registerCommand(chatCommand, function(pid, cmd)

    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)

    if cmd[2] == nil then
        --no subcommand
        msg(pid, "Welcome to instanced housing!")
        msg(pid, "Commands: template, create, home, delete, templatedelete, list")
    elseif instancedHousing.subCommands[cmd[2]] == nil then
        --subcommand doesn't exist
    else
        --subcommand exists
        instancedHousing.subCommands[cmd[2]](pid,cmd)
    end

end)




--EVENTS
customEventHooks.registerHandler("OnServerPostInit", function(event)
    instancedHousing.load()
end)

customEventHooks.registerHandler("OnServerExit", function(event)
    instancedHousing.save()
end)


return instancedHousing