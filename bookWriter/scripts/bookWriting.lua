bookWriting = {}

bookWriting.currentBooks = {}
bookWriting.bookTypes = {} -- { {model: "", icon: ""}, {model: "", icon: ""} }

table.insert(bookWriting.bookTypes, {model = "m\\Text_Octavo_08.nif", icon = "m\\Tx_book_02.tga", scroll = false, name = "Green Book"} )
table.insert(bookWriting.bookTypes, {model = "m\\Text_Parchment_02.nif", icon = "m\\Tx_parchment_02.tga", scroll = true, name = "Letter"} )
table.insert(bookWriting.bookTypes, {model = "m\\Text_Note_02.nif", icon = "m\\Tx_note_02.tga", scroll = true, name = "Note"} )
table.insert(bookWriting.bookTypes, {model = "m\\Text_Octavo_06.nif", icon = "m\\Tx_book_03.tga", scroll = true, name = "Lesson of Vivec"} )

local msg = function(pid, text)
	tes3mp.SendMessage(pid, color.GreenYellow .. "[BookWriting] " .. color.Default .. text .. "\n" .. color.Default)
end


function bookWriting.onCommand(pid, cmd)
    local name = Players[pid].name:lower()
    if cmd[2] == "clear" then
        bookWriting.currentBooks[name] = nil
        msg(pid, "Cleared.")
    elseif cmd[2] == "title" then
        bookWriting.startBook(name)
        bookWriting.currentBooks[name].title = table.concat(cmd, " ", 3)
        msg(pid, "Set title.")
    elseif cmd[2] == "addtext" then
        bookWriting.startBook(name)
        bookWriting.currentBooks[name].text = bookWriting.currentBooks[name].text .. table.concat(cmd, " ", 3)
        msg(pid, "Added text.")
    elseif cmd[2] == "settext" then
        bookWriting.startBook(name)
        bookWriting.currentBooks[name].text = table.concat(cmd, " ", 3)
        msg(pid, "Set text.")
    elseif cmd[2] == "done" then
        if bookWriting.currentBooks[name] == nil then
            msg(pid, "You haven't made a book yet, try using /book title <text>")
        else
            bookWriting.createBook(pid)
        end
    elseif cmd[2] == "liststyle" then
        msg(pid, "Book Types:")
        for i, bookType in pairs(bookWriting.bookTypes) do
            msg(pid, tostring(i) .. ": " .. bookType.name)
        end
    elseif cmd[2] == "setstyle" then
        bookWriting.startBook(name)
        bookWriting.currentBooks[name].type = tonumber(cmd[3])
    end
end
customCommandHooks.registerCommand("book", bookWriting.onCommand)


-- just creates the table if it needs to
function bookWriting.startBook(name)
    if bookWriting.currentBooks[name] == nil then
        bookWriting.currentBooks[name] = {}
        bookWriting.currentBooks[name].title = "Empty Title"
        bookWriting.currentBooks[name].text = ""
        bookWriting.currentBooks[name].type = 1
    end
end

function bookWriting.createBook(pid)
    print("create book start")
    local name = Players[pid].name:lower()
    --TODO check if they have paper


    local model = bookWriting.bookTypes[bookWriting.currentBooks[name].type].model
    local icon = bookWriting.bookTypes[bookWriting.currentBooks[name].type].icon
    local scroll = bookWriting.bookTypes[bookWriting.currentBooks[name].type].scroll

    print(model)
    print(icon)

    local book = {}
    book["weight"] = 1
    book["icon"] = icon --"m\\Tx_note_02.tga"
    book["skillId"] = "-1"
    book["model"] = model --"m\\Text_Note_02.nif"
    book["text"] = bookWriting.currentBooks[name].text
    book["value"] = 1
    book["scrollState"] = scroll --false --true
    book["name"] = "*" .. bookWriting.currentBooks[name].title .. "*"

    print("before create book record")
    local bookId = bookWriting.nuCreateBookRecord(pid, book)
    print("after bookId " .. tostring(bookId))
    Players[pid]:AddLinkToRecord("book", bookId)
    inventoryHelper.addItem(Players[pid].data.inventory, bookId, 1)
    print("after create book record")

    --all them updates
    Players[pid]:Save()
	Players[pid]:LoadInventory()
    Players[pid]:LoadEquipment()
    Players[pid]:LoadQuickKeys()
end


--stolen from notewriting lmao
function bookWriting.nuCreateBookRecord(pid, recordTable)
    local recordStore = RecordStores["book"]
    local id = recordStore:GenerateRecordId()
    local savedTable = recordTable
	
    recordStore.data.generatedRecords[id] = savedTable
    for _, player in pairs(Players) do
        if not tableHelper.containsValue(player.generatedRecordsReceived, id) then
            table.insert(player.generatedRecordsReceived, id)
        end
    end
    recordStore:Save()
    tes3mp.ClearRecords()
    tes3mp.SetRecordType(enumerations.recordType[string.upper("book")])
    packetBuilder.AddBookRecord(id, savedTable)
    tes3mp.SendRecordDynamic(pid, true, false)
	
    return id
end


