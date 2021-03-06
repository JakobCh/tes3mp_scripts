# tes3mp_scripts

My tes3mp(0.7-alpha) scripts, most of the readme stuff will be in the top of the script files.

## autoDataFiles
Will automaticaly make the server use the datafiles from your openmw config.

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

## customSkills
NOT DONE

Library for making custom skills

## customSpells
Just like a proof of concept tbh

Have a lua function get called when someone casts a specific spell.

## doorLinks
Library that generates all cell connections using espParser, HAVEN'T TESTED WITH LATEST ESPPARSER

## espParser
Helper file for other scripts to get data from esp/esm files.

REQUIRES https://github.com/iryont/lua-struct

Usage: See espParserTest.lua

## jcMarketplace
Allows you to set a price on items and sell them, also blocks other people from picking stuff up.

Supposed to be used with kanaHousing.

Usage: see the scriptfile

## JCMining
Runescape like mining 

## jsonCellLoader
Load a json file into the current cell.

See the top of the script file for a readme

## loadtxt2esp
Load TXT2ESP4 files into a cell

Usage: type "/loadtxt2esp 'filename'" were filename is the file in mp-stuff/data/txt2esp without the .txt

Example: I've included the default example file from TXT2ESP4 and you should be able to spawn it with "/loadtxt2esp room_source3"

Problems: There are no admin checks so anyone can run the command. Doors dont work

## memoryInfo
Commands for interacting with the lua garbage collector

## openmwcfg
Library for using values from the openmw.cfg file

## PlayerSkillResetFix
Prevents players base skills from decreasing

