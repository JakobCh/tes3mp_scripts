# tes3mp_scripts

My tes3mp(0.7-alpha) scripts, most of the readme stuff will be in the top of the script files.

## bookWriter
Chat commands for players to make custom books.

Commands:

/book title

/book addtext

/book settext

/book liststyles

/book setstyle

/book done

/book clear



Example usage:

/book title My Cool Book

/book addtext Line 1\<br>

/book addtext \<div align="center"> Centered Line 2 \<br>

/book setstyle 3

/book done

/book clear

## espParser
Helper file for other scripts to get data from esp/esm files.

REQUIRES https://github.com/iryont/lua-struct

Usage: See espParserTest.lua

## jcMarketplace
Allows you to set a price on items and sell them, also blocks other people from picking stuff up.

Supposed to be used with kanaHousing.

Usage: see the scriptfile


## loadtxt2esp
Load TXT2ESP4 files into a cell

Usage: type "/loadtxt2esp 'filename'" were filename is the file in mp-stuff/data/txt2esp without the .txt

Example: I've included the default example file from TXT2ESP4 and you should be able to spawn it with "/loadtxt2esp room_source3"

Problems: There are no admin checks so anyone can run the command. Doors dont work


## jsonCellLoader
Load a json file into the current cell.

See the top of the script file for a readme
