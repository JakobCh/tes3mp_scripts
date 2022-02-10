--[[

Name: bookWriting
Version: 0.3
Tes3mp Version: 0.8
Author: JakobCh
Last update: 2022-02-10

Description:
    Allows players to create custom books

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.bookWriting") ] in server/scripts/customScripts.lua

Commands:
    /book: Help menu
    /book title <text>: Set the Name of the book
    /book addtext <text>: Add text to the book
    /book settext <text>: Set the text in the book (will remove all previous text)
    /book listsyles: lists all the styles
    /book setstyle: sets the style the book is going to use
    /book done: Creates the book (can be used several times at long as you dont use /book clear)
    /book clear: Deletes the book

Known issues/TODO:
    None
]]


bookWriting = {}

bookWriting.currentBooks = {} --used to store players individual in progress books

--the book styles
bookWriting.bookStyles = {}
table.insert(bookWriting.bookStyles, {model = "m\\Text_Octavo_08.nif", icon = "m\\Tx_book_02.tga", scroll = false, name = "Green Book"} )
table.insert(bookWriting.bookStyles, {model = "m\\Text_Parchment_02.nif", icon = "m\\Tx_parchment_02.tga", scroll = true, name = "Letter"} )
table.insert(bookWriting.bookStyles, {model = "m\\Text_Note_02.nif", icon = "m\\Tx_note_02.tga", scroll = true, name = "Note"} )
table.insert(bookWriting.bookStyles, {model = "m\\Text_Octavo_06.nif", icon = "m\\Tx_book_03.tga", scroll = false, name = "Lesson of Vivec"} )

bookWriting.nameSymbol = "~" --the symbol used before and after book names to differentiate them from vanila books


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
    elseif cmd[2] == "liststyle" or cmd[2] == "liststyles" then
        msg(pid, "Book Types:")
        for i, bookType in pairs(bookWriting.bookStyles) do
            msg(pid, tostring(i) .. ": " .. bookType.name)
        end
    elseif cmd[2] == "setstyle" then
        bookWriting.startBook(name)

        if tonumber(cmd[3]) == nil then return end
        if tonumber(cmd[3]) < 1 then return end
        if tonumber(cmd[3]) > #bookWriting.bookStyles then return end

        bookWriting.currentBooks[name].type = tonumber(cmd[3])
        msg(pid, "Style set.")
    else
        msg(pid, "Usage: /book <command>")
        msg(pid, "  title <text>: Set the title of the book (Use this to create a new one).")
        msg(pid, "  addtext <text>: Add text to the book.")
        msg(pid, "  settext <text>: Set the text in the book (will remove all other text).")
        msg(pid, "  liststyles: Lists all the styles.")
        msg(pid, "  setstyle <number>: Sets the style.")
        msg(pid, "  done: Make the book!")
        msg(pid, "  clear: Clear all the book data so you can start a new one.")
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
    --print("create book start")
    local name = Players[pid].name:lower()


    --Checks if players have the required Item(s)
	if inventoryHelper.containsItem(Players[pid].data.inventory,"sc_paper plain") then
		inventoryHelper.removeItem(Players[pid].data.inventory,"sc_paper plain",1)
        msg(pid, color.Green .. "You wrote a book!")
    elseif inventoryHelper.containsItem(Players[pid].data.inventory,"sc_paper_plain_01_canodia") then
        inventoryHelper.removeItem(Players[pid].data.inventory,"sc_paper_plain_01_canodia",1)
		msg(pid, color.Green .. "You wrote a book!")
	else
        msg(pid, color.Red .. "You lack the paper to write a book.")
		return
	end


    local model = bookWriting.bookStyles[bookWriting.currentBooks[name].type].model
    local icon = bookWriting.bookStyles[bookWriting.currentBooks[name].type].icon
    local scroll = bookWriting.bookStyles[bookWriting.currentBooks[name].type].scroll

    --print(model)
    --print(icon)

    local book = {}
    book["weight"] = 1
    book["icon"] = icon --"m\\Tx_note_02.tga"
    book["skillId"] = "-1"
    book["model"] = model --"m\\Text_Note_02.nif"
    book["text"] = bookWriting.currentBooks[name].text .. "<BR>" --Morrowind doesn't like not having atleast one line :/
    book["value"] = 1
    book["scrollState"] = scroll --false --true
    book["name"] = bookWriting.nameSymbol .. bookWriting.currentBooks[name].title .. bookWriting.nameSymbol

    --check if that book already exists, then just give them a copy of that
    for id,n in pairs(RecordStores["book"].data.generatedRecords) do
        --print(tostring(id), tostring(n), n.name, n.text)
        if n.name == book["name"] and n.text == book["text"] then
            msg(pid, "You got a copy of your book!")
            inventoryHelper.addItem(Players[pid].data.inventory, id, 1)
            --all them updates
            Players[pid]:Save()
            Players[pid]:LoadInventory()
            Players[pid]:LoadEquipment()
            Players[pid]:LoadQuickKeys()
            return
        end
    end

    --print("before create book record")
    local bookId = bookWriting.nuCreateBookRecord(pid, book)
    --print("after bookId " .. tostring(bookId))
    Players[pid]:AddLinkToRecord("book", bookId)
    inventoryHelper.addItem(Players[pid].data.inventory, bookId, 1)
    --print("after create book record")

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


