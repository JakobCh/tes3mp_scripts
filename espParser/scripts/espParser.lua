--[[
	espParser 0.2
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

local Stream = {}
Stream.__index = Stream
function Stream:create(data)
	local newobj = {}
	setmetatable(newobj, Stream)
	newobj.data = data
	newobj.pointer = 1
	return newobj
end
function Stream:len()
	return string.len(self.data)
end
function Stream:read(amount)
	local temp = string.sub(self.data, self.pointer, self.pointer+amount-1)
	self.pointer = self.pointer + amount
	return temp
end
function Stream:sub(start, send)
	local temp = string.sub(self.data, start, send)
	return temp
end

local Record = {}
Record.__index = Record
function Record:create(stream)
	--[[
Record
	4 bytes: char Name[4]
		4-byte record name string (not null-terminated)
	4 bytes: long Size    
		Size of the record not including the 16 bytes of header data.
	4 bytes: long Header1
		Unknown value, usually 0 (deleted/ignored flag?).
	4 bytes: long Flags
		Record flags.
			 0x00002000 = Blocked
			 0x00000400 = Persistant
	? bytes: SubRecords[]
		All records are composed of a variable number of sub-records. There
		is no sub-record count, just use the record Size value to determine
		when to stop reading a record.
	]]

	local newobj = {}
	setmetatable(newobj, Record)
	newobj.name = stream:read(4) 
	newobj.size = struct.unpack( "i", stream:read(4) )
	--print("EEEE1")
	newobj.header1 = struct.unpack( "i", stream:read(4) )
	newobj.flags = struct.unpack( "i", stream:read(4) )
	newobj.data = stream:read(newobj.size)
	newobj.subRecords = {}
	--print("OOO")

	--get subrecords
	local st = Stream:create(newobj.data)
	while st.pointer < st:len() do
		table.insert(newobj.subRecords, espParser.SubRecord:create(st) )
	end

	return newobj
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

espParser.files = {}

espParser.addEsp = function(filename)
	local currentFile = filename
	
	--print(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile)
	local f = io.open(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile, "rb") --open file handler
	if f == nil then
		return
	end
	
	local mainStream = Stream:create(f:read("*a")) --read all
	espParser.files[currentFile] = {}
	while mainStream.pointer < mainStream:len() do
		local r = Record:create(mainStream)
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




