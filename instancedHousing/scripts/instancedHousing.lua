--[[

Name: instancedHousing
Version: 0.1
Tes3mp Version: 0.8
Author: JakobCh
Last update: 2022-02-13

Description:
    Instanced player housing

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.instancedHousing") ] in server/scripts/customScripts.lua

Commands:
    /ihouse
    /ihouse template <id> <fancy name>: used by staff to create house templates
    /ihouse create <id>

Known issues/TODO:
    THIS IS NOT FINISHED
]]


local msg = function(pid, text)
	tes3mp.SendMessage(pid, color.GreenYellow .. "[InstancedHousing] " .. color.Default .. text .. "\n" .. color.Default)
end

local doInfo = function(text)
    tes3mp.LogMessage(enumerations.log.INFO, text)
end

customCommandHooks.registerCommand("thiscell", function(pid, cmd)
    msg(pid, "\"" .. Players[pid].data.location.cell .. "\"")
end)


local chatCommand = "ihouse"
local savelocation = "custom/instancedHousing.json"

--cell prefixes
local templatePrefix = "ihouse_template_"
local housePrefix = "ihouse_house_"


instancedHousing = {} --Global
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

instancedHousing.createHouseForPlayer = function(playername, templateId)
    playername = playername:lower()



end

instancedHousing.subCommands = {} --keyed with cmd2

--Subcommand template
instancedHousing.subCommands.template = function(pid, cmd)
    --command to add a new template

    if cmd[4] == nil then
        msg(pid, "Usage: template <id> <fancy name>")
        msg(pid, "       <id> can only be one word")
        return
    end

    local player = Players[pid]
    local templateName = cmd[3]
    local fancyName = tableHelper.concatenateFromIndex(cmd, 4)

    if templateName == nil or templateName == "" or templateName:find(" ") then
        msg(pid, "Invalid template name: \"" .. templateName .. "\"")
    end

    --TODO check if that template name already exists

    local newRecord = {}
    newRecord.baseId = player.data.location.cell
    newRecord.id = templatePrefix .. templateName
    newRecord.name = fancyName
    newRecord.spawn = {
        x=player.data.location.posX,
        y=player.data.location.posY,
        z=player.data.location.posZ
    }

    msg(pid, "Adding a template with id: " .. newRecord.id)
    msg(pid, "with baseId: " .. newRecord.baseId)
    msg(pid, "with the fancy name: " .. fancyName)


    instancedHousing.data.templates[newRecord.id] = newRecord
    instancedHousing.save()

    --Add to the record store
    local recordStore = RecordStores["cell"]
    recordStore.data.permanentRecords[newRecord.id] = {baseId=player.data.location.cell} --it only needs a baseId in it
    recordStore:QuicksaveToDrive()

end

--subcommand create
instancedHousing.subCommands.create = function(pid, cmd)
    --command to create a house for the current player from a template

    if cmd[3] == nil then
        msg(pid, "Usage: create <template id>")
        return
    end

    local templateId = cmd[3]

    local template = instancedHousing.data.templates[templateId]
    if template == nil then
        msg(pid, "Invalid template id.")
        return 
    end


    local player = Players[pid]
    local playerName = string.lower(Players[pid].accountName)
    local cellId = housePrefix .. playerName

    --Add to the record store
    local recordStore = RecordStores["cell"]
    recordStore.data.permanentRecords[cellId] = {baseId=template.baseId}
    recordStore:QuicksaveToDrive()

    msg(pid, "Created new house for player: " .. playerName)

    instancedHousing.data.houses[playerName] = {
        id=cellId,
        spawn=template.spawn
    } --TODO houses should probably have more data then this
    instancedHousing.save()

    --TODO sync removed objects from the template

    --copy template
    local temp = jsonInterface.load("cell/" .. template.baseId .. ".json")
    temp.entry.description = cellId
    jsonInterface.save("cell/" .. cellId .. ".json", temp)

    logicHandler.LoadCell(cellId)
end

instancedHousing.subCommands.home = function(pid, cmd)
    --send player to his house
    local playerName = string.lower(Players[pid].accountName)
    local house = instancedHousing.data.houses[playerName]

    if house == nil then
        msg(pid, "You don't have a house.")
        return
    end

    tes3mp.SetCell(pid, house.id)
	tes3mp.SendCell(pid)
	
	tes3mp.SetPos(pid, house.spawn.x, house.spawn.y, house.spawn.z)
	tes3mp.SendPos(pid)

end

instancedHousing.subCommands.delete = function(pid, cmd)

    if cmd[3] == nil then
        msg(pid, "Usage: delete <cell id>")
        return
    end

    local cellId = cmd[3]

end

--COMMAND HOOK
customCommandHooks.registerCommand(chatCommand, function(pid, cmd)

    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)

    if cmd[2] == nil then
        --no subcommand
        msg(pid, "Welcome to instanced housing!")
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




--[[
local recordStore = RecordStores["cell"]

msg(pid, "All permanent cell records:")
for i,v in pairs(recordStore.permanentRecords) do
    msg(pid, v.id .. " " .. v.baseId)
end
]]