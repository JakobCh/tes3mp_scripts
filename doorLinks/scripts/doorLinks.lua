--[[
	doorLinks 0.1
	By Jakob https://github.com/JakobCh

	Description:
		Makes a global table of all cell exits and where they lead.
		Basically just a helper library for other scripters.

	Requires:
		espParser 0.3 https://github.com/JakobCh/tes3mp_scripts
		struct https://github.com/iryont/lua-struct (change the require below if you need to)

	Installation:
		1. Put this file in server/scripts/custom
		2. Add "require("custom.doorLinks")" to /server/scripts/customScripts.lua (make sure its below espParser)

	Usage:
		for cellDescription, cellData in pairs(doorLinks.cells) do
			print("This cell: " .. cellDescription)
			print("Has exits to these cells:")
			for _, exitData in pairs(cellData) do
				print("    " .. exitData.cell)
				--exitData.refId -- the refId of the door
				--exitData.location -- a table with XPos, YPos, ZPos, XRotation, YRotation, ZRotation
			end
		end
]]

local config = {}
config.debug = false

require "custom.struct"

local doInfo = function(text)
	tes3mp.LogMessage(enumerations.log.INFO, "[doorLinks] " .. text) 
end

doorLinks = {}
doorLinks.cells = {}

doInfo("Start")

for _,record in pairs(espParser.getAllRecords("CELL")) do --go thru all cell records

	local cellName = record:getSubRecordsByName("NAME")[1].data --get the first cell record

	doorLinks.cells[cellName] = {}

	-- So I need to get each object in the cell which has 
	local skipedFirstName = false

	local _refId = nil
	local _exitData = nil
	local exitName = nil

	for i, subrecord in pairs(record.subRecords) do
		if subrecord.name == "NAME" then
			if skipedFirstName == false then
				skipedFirstName = true
			else
				--and exitName ~= nil
				if _refId ~= nil and _exitData ~= nil then --dont actually need an exitname if they're teleporting to an external cell
					local stream = espParser.Stream:create(_exitData)

					local temp = {
						refId = _refId,
						location = {
							XPos = struct.unpack( "i", stream:read(4) ),
							YPos = struct.unpack( "i", stream:read(4) ),
							ZPos = struct.unpack( "i", stream:read(4) ),
							XRotate = struct.unpack( "i", stream:read(4) ),
							YRotate = struct.unpack( "i", stream:read(4) ),
							ZRotate = struct.unpack( "i", stream:read(4) )
						},
						cell = exitName
					}

					if temp.cell == nil then --if it doesn't have a DNAM record its in an external cell
						temp.cell = tostring(math.ceil(temp.location.XPos / 8192)) .. ", " .. tostring(math.ceil(temp.location.YPos / 8192))
					end

					table.insert(doorLinks.cells[cellName], temp )
				end
				_refId = subrecord.data
				_exitData = nil
				exitName = nil
			end
		end

		if subrecord.name == "DODT" then
			_exitData = subrecord.data
		end
		if subrecord.name == "DNAM" then
			exitName = subrecord.data
		end

	end
end

if config.debug then
	for cellName, cellData in pairs(doorLinks.cells) do
		doInfo(cellName .. ":")
		for i,data in pairs(cellData) do
			for m,n in pairs(data) do
				if type(n) == "table" then
					doInfo("    location:")
					for mm,nn in pairs(n) do
						doInfo("        " .. mm .. " : " .. tostring(nn))
					end
				else
					doInfo("    " .. m .. " : " .. tostring(n))
				end
			end
		end
	end
end