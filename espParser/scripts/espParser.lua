--[[
	espParser 0.4
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

--Stream class
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

--Record class
espParser.Record = {}
espParser.Record.__index = espParser.Record
function espParser.Record:create(stream)
	local newobj = {}
	setmetatable(newobj, espParser.Record)
	newobj.name = stream:read(4) 
	newobj.size = struct.unpack( "i", stream:read(4) )
	newobj.header1 = struct.unpack( "i", stream:read(4) )
	newobj.flags = struct.unpack( "i", stream:read(4) )
	newobj.data = stream:read(newobj.size)
	newobj.subRecords = {}

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

--SubRecord class
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
espParser.getRecords = function(filename, recordName)
	local out = {}
	for i,record in pairs(espParser.rawFiles[filename]) do
		if record.name == recordName then
			table.insert(out, record)
		end
	end
	return out
end

espParser.getSubRecords = function(filename, recordName, subRecordName)
	local out = {}
	for _,record in pairs(espParser.rawFiles[filename]) do
		if record.name == recordName then
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == subRecordName then
					table.insert(out, subrecord)
				end
			end
		end
	end
	return out
end

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


espParser.rawFiles = {} --contains each .esp file as a key (raw Records and subrecords)
espParser.files = {} --contains each .esp file as a key

espParser.parseCells = function(filename) --filename already loaded in espParser.rawFiles
	local records = espParser.getRecords(filename, "CELL")

	if espParser.files[filename] == nil then
		espParser.files[filename] = {}
	end
	espParser.files[filename].cells = {}

	local lenTable = {
		i = 4,
		f = 4,
	}

	local dataTypes = {
		Unique = {
			{"NAME", "s", "id"},
			{"DATA", {
				{"i", "flags"},
				{"i", "gridX"},
				{"i", "gridY"}
			}},
			{"RGNN", "s", "region"},
			{"NAM0", "i", "NAM0"},
			{"NAM5", "i", "mapColor"},
			{"WHGT", "f", "waterHeight"},
			{"AMBI", {
				{"i", "ambientColor"},
				{"i", "sunlightColor"},
				{"i", "fogColor"},
				{"f", "fogDensity"}
			}}
		},
		Multi = {
			{"NAME", "s", "refId"},
			{"XSCL", "f", "scale"},
			{"DELE", "i", "deleted"},
			{"DNAM", "s", "doorExitName"},
			{"FLTV", "i", "lockLevel"},
			{"KNAM", "s", "doorKey"},
			{"TNAM", "s", "trapName"},
			{"UNAM", "B", "referenceBlocked"},
			{"ANAM", "s", "owner"},
			{"BNAM", "s", "id"}, -- Global variable/rank ID string
			{"INTV", "i", "uses"},
			{"NAM9", "i", "NAM9"}, --?
			{"XSOL", "s", "soul"}
		}
	}

	for _, record in pairs(records) do
		local cell = {}
		
		for _, dType in pairs(dataTypes.Unique) do
			local tempData = record:getSubRecordsByName(dType[1])[1]
			if tempData ~= nil then
				if type(dType[2]) == "table" then
					local stream = espParser.Stream:create( tempData.data )
					for _, ddType in pairs(dType[2]) do
						cell[ddType[2]] = struct.unpack( ddType[1], stream:read(4) )
					end
				else
					--print(dType[2], tempData.data)
					cell[dType[3]] = struct.unpack( dType[2], tempData.data )
				end
			end
		end

		if cell.id == "" then --its a external cell
			cell.isExternal = true
			cell.id = cell.gridX .. ", " .. cell.gridY

		else --its a internal cell
			cell.isExternal = false
		end

		cell.objects = {}

		local currentIndex = nil

		for _, subrecord in pairs(record.subRecords) do
			if subrecord.name == "FRMR" then
				currentIndex = struct.unpack( "i", subrecord.data )
				cell.objects[currentIndex] = {}
				cell.objects[currentIndex].scale = 1
			end

			if subrecord.name == "DODT" and currentIndex ~= nil then
				local stream = espParser.Stream:create( subrecord.data )
				cell.objects[currentIndex].doorLocation = {
					XPos = struct.unpack( "f", stream:read(4) ),
					YPos = struct.unpack( "f", stream:read(4) ),
					ZPos = struct.unpack( "f", stream:read(4) ),
					XRot = struct.unpack( "f", stream:read(4) ),
					YRot = struct.unpack( "f", stream:read(4) ),
					ZRot = struct.unpack( "f", stream:read(4) )
				}
			end

			if subrecord.name == "DATA" and currentIndex ~= nil then
				local stream = espParser.Stream:create( subrecord.data )
				cell.objects[currentIndex].location = {
					XPos = struct.unpack( "f", stream:read(4) ),
					YPos = struct.unpack( "f", stream:read(4) ),
					ZPos = struct.unpack( "f", stream:read(4) ),
					XRot = struct.unpack( "f", stream:read(4) ),
					YRot = struct.unpack( "f", stream:read(4) ),
					ZRot = struct.unpack( "f", stream:read(4) )
				}
			end

			for _, type in pairs(dataTypes.Multi) do
				if subrecord.name == type[1] and currentIndex ~= nil then
					cell.objects[currentIndex][type[3]] = struct.unpack( type[2], subrecord.data )
				end
			end
		end

		espParser.files[filename].cells[cell.id] = cell
	end
end

espParser.addEsp = function(filename)
	local currentFile = filename
	
	--print(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile)
	local f
	f = io.open(tes3mp.GetDataPath() .. "\\custom\\esps\\" .. currentFile, "rb") --open file handler (windows)
	if f == nil then
		f = io.open(tes3mp.GetDataPath() .. "/custom/esps/" .. currentFile, "rb") --open file handler (linux)
	end

	if f == nil then return false end --could not open the file
	
	local mainStream = espParser.Stream:create(f:read("*a")) --read all
	espParser.rawFiles[currentFile] = {}
	while mainStream.pointer < mainStream:len() do
		local r = espParser.Record:create(mainStream)
		table.insert(espParser.rawFiles[currentFile], r)
	end

	espParser.parseCells(currentFile)

	--tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loaded: " .. currentFile) 
	return true
end

-- Load all the files in the config
tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loading files...") 
for i,name in pairs(files) do
	if espParser.addEsp(name) then
		tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loaded: " .. name) 
	else
		tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Failed to load: " .. name) 
	end
end
tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Finished!") 




