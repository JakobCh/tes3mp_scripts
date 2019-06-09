--[[
	espParser 0.3
	By Jakob https://github.com/JakobCh
	Mostly using: https://en.uesp.net/morrow/tech/mw_esm.txt
	
	This does not parse the subrecord data! You have to do that yourself.
	
	Installation:
		1. Put this file and struct.lua ( https://github.com/iryont/lua-struct ) in /server/scripts/custom/
		2. Add "require("custom.espParser")" to /server/scripts/customScripts.lua
		3. Create a folder called "esps" in /server/data/custom/
		4. Place your esp/esm files in the new folder (/server/data/custom/esps/)
		5. Change the "files" table a couple lines down to match your files
		(6. Check the espParserTest.lua file for examples)
	
]]

local files = {
	"Morrowind.esm",
	"Tribunal.esm",
	"Bloodmoon.esm"
}

require "custom.struct" -- Requires https://github.com/iryont/lua-struct

--Global
espParser = {}

--print(debug.getinfo(2, "S").source:sub(2))

espParser.Stream = {}
espParser.Stream.__index = espParser.Stream
function espParser.Stream:create(data)
	local newobj = {}
	setmetatable(newobj, espParser.Stream)
	newobj.data = data
	newobj.pointer = 1
	return newobj
end
function espParser.Stream:len()
	return string.len(self.data)
end
function espParser.Stream:read(amount)
	local temp = string.sub(self.data, self.pointer, self.pointer+amount-1)
	self.pointer = self.pointer + amount
	return temp
end
function espParser.Stream:sub(start, send)
	local temp = string.sub(self.data, start, send)
	return temp
end

espParser.Record = {}
espParser.Record.__index = espParser.Record
function espParser.Record:create(stream)
	local newobj = {}
	setmetatable(newobj, espParser.Record)
	newobj.name = stream:read(4) 
	newobj.size = struct.unpack( "i", stream:read(4) )
	--print("EEEE1")
	newobj.header1 = struct.unpack( "i", stream:read(4) )
	newobj.flags = struct.unpack( "i", stream:read(4) )
	newobj.data = stream:read(newobj.size)
	newobj.subRecords = {}
	--print("OOO")

	--get subrecords
	local st = espParser.Stream:create(newobj.data)
	while st.pointer < st:len() do
		table.insert(newobj.subRecords, espParser.SubRecord:create(st) )
	end

	return newobj
end
function espParser.Record:getSubRecordsByName(name)
	local out = {}
	for _, subrecord in pairs(self.subRecords) do
		if subrecord.name == name then
			table.insert(out, subrecord)
		end
	end
	return out
end

--has to be global so Record can access it
espParser.SubRecord = {}
espParser.SubRecord.__index = espParser.SubRecord
function espParser.SubRecord:create(stream)
	local newobj = {}
	setmetatable(newobj, espParser.SubRecord)
	newobj.name = stream:read(4)
	newobj.size = struct.unpack( "i", stream:read(4) )
	newobj.data = stream:read(newobj.size)
	--print("Creating subrecord with name: " .. tostring(newobj.name))
	return newobj
end

--helper functions
espParser.getAllRecords = function(recordName)
	local out = {}
	for filename,records in pairs(espParser.files) do
		for _,record in pairs(records) do
			if record.name == recordName then
				table.insert(out, record)
			end
		end
	end
	return out
end

espParser.getAllSubRecords = function(recordName, subRecordName)
	local out = {}
	for filename,records in pairs(espParser.files) do
		for _,record in pairs(records) do
			if record.name == recordName then
				for _, subrecord in pairs(record.subRecords) do
					if subrecord.name == subRecordName then
						table.insert(out, subrecord)
					end
				end
			end
		end
	end
	return out
end


espParser.files = {} --contains each .esp file as a key

espParser.addEsp = function(filename)
	local currentFile = filename
	
	--print(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile)
	local f = io.open(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile, "rb") --open file handler
	if f == nil then
		return
	end
	
	local mainStream = espParser.Stream:create(f:read("*a")) --read all
	espParser.files[currentFile] = {}
	while mainStream.pointer < mainStream:len() do
		local r = espParser.Record:create(mainStream)
		table.insert(espParser.files[currentFile], r)
		
	end
	tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loaded: " .. currentFile) 
end

-- Load all the files in the config
tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loading files...") 
for i,name in pairs(files) do
	espParser.addEsp(name)
end
tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Finished!") 




