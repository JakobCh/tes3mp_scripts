--[[
Version: 0.7 for 0.7-alpha
Requires kanaHousing basically

Install:
	Put this file in server/scripts/custom/
	Put [ require("custom.jcMarketplace") ] in customScripts.lua

Commands:
    /market: info on the current market

    /marketadd
    /market add
    /marketcreate
    /market create: Set the current cell as your market

    /marketremove
    /market remove
    /marketdelete
    /market delete: Remove your market from the current cell

    /marketlog
    /market log
    /marketmessages
    /market messages: List all your sales

    /marketclearlog
    /market clearlog: Clear your message log
	
	/marketjcinfo: will give you some debug info

Good to know:
    When you're inside a cell you own you can crouch+activate a droped item to set it's price.
    When a guest is inside a cell that's owned by someone they can't pick up anything that's been droped.
    When a guest tries to activate a droped item and that item has a price set they can buy it.
    Money will be transfered to the owned ever if they're offline.
]]

local Config = {}
Config.kanaHouseIntergration = true --if you have this of anyone can create a market in any interior cell
Config.GUIMain = 1190
Config.GUIItem = 1191
Config.GUIPrice = 1192

--all ref ids that the script wont block in market cells
--keep in mind this uses string.match/contains
Config.NonBlockedRedIds = {
    "door", --doors 
    "player_note_", --custom notes
	"$custom_book_", --new custom notes
    "scamp_creeper", --creeper
    "mudcrab_unique", --mudcrap mechant
	
	--all books
	"BookSkill_Enchant1", "BookSkill_Enchant2", "bookskill_enchant3", "bookskill_enchant4", "bookskill_enchant5", "bookskill_destruction1", "bookskill_destruction2", "bookskill_destruction3", "bookskill_destruction4", "BookSkill_Destruction5", "BookSkill_Alteration1", "BookSkill_Alteration2", "BookSkill_Alteration3", "BookSkill_Alteration4", "BookSkill_Alteration5", "bookskill_illusion1", "bookskill_illusion2", "bookskill_illusion3", "bookskill_illusion4", "bookskill_illusion5", "BookSkill_Conjuration1", "BookSkill_Conjuration2", "BookSkill_Conjuration3", "BookSkill_Conjuration4", "bookskill_conjuration5", "bookskill_mysticism1", "BookSkill_Mysticism2", "BookSkill_Mysticism3", "BookSkill_Mysticism4", "BookSkill_Mysticism5", "bookskill_restoration1", "bookskill_restoration2", "bookskill_restoration3", "BookSkill_Restoration4", "BookSkill_Restoration5", "BookSkill_Alchemy1", "BookSkill_Alchemy2", "BookSkill_Alchemy3", "BookSkill_Alchemy4", "BookSkill_Alchemy5", "bookskill_unarmored1", "bookskill_unarmored2", "bookskill_unarmored3", "bookskill_unarmored4", "bookskill_unarmored5", "BookSkill_Block1", "bookskill_block2", "BookSkill_Block3", "BookSkill_Block4", "BookSkill_Block5", "BookSkill_Armorer1", "BookSkill_Armorer2", "BookSkill_Armorer3", "BookSkill_Armorer4", "BookSkill_Armorer5", "bookskill_medium armor1", "BookSkill_Medium Armor2", "BookSkill_Medium Armor3", "bookskill_medium armor4", "bookskill_medium armor5", "bookskill_heavy armor1", "BookSkill_Heavy Armor2", "BookSkill_Heavy Armor3", "bookskill_heavy armor4", "bookskill_heavy armor5", "bookskill_blunt weapon1", "BookSkill_Blunt Weapon2", "bookskill_blunt weapon3", "BookSkill_Blunt Weapon4", "BookSkill_Blunt Weapon5", "BookSkill_Long Blade1", "BookSkill_Long Blade2", "bookskill_long blade3", "bookskill_long blade4", "bookskill_long blade5", "BookSkill_Axe1", "bookskill_axe2", "BookSkill_Axe3", "BookSkill_Axe4", "BookSkill_Axe5", "bookskill_spear1", "BookSkill_Spear2", "bookskill_spear3", "bookskill_spear4", "bookskill_spear5", "BookSkill_Athletics1", "BookSkill_Athletics2", "BookSkill_Athletics3", "BookSkill_Athletics4", "BookSkill_Athletics5", "bookskill_security1", "bookskill_security2", "BookSkill_Security3", "bookskill_security4", "bookskill_security5", "bookskill_sneak1", "BookSkill_Sneak2", "BookSkill_Sneak3", "bookskill_sneak4", "bookskill_sneak5", "bookskill_acrobatics1", "BookSkill_Acrobatics2", "BookSkill_Acrobatics3", "BookSkill_Acrobatics4", "BookSkill_Acrobatics5", "BookSkill_Light Armor1", "BookSkill_Light Armor2", "bookskill_light armor3", "bookskill_light armor4", "bookskill_light armor5", "bookskill_short blade1", "BookSkill_Short Blade2", "BookSkill_Short Blade3", "BookSkill_Short Blade4", "BookSkill_Short Blade5", "bookskill_marksman1", "BookSkill_Marksman2", "bookskill_marksman3", "bookskill_marksman4", "bookskill_marksman5", "bookskill_mercantile1", "bookskill_mercantile2", "BookSkill_Mercantile3", "bookskill_mercantile4", "bookskill_mercantile5", "BookSkill_Speechcraft1", "bookskill_speechcraft2", "BookSkill_Speechcraft3", "bookskill_speechcraft4", "bookskill_speechcraft5", "bookskill_hand to hand1", "bookskill_hand to hand2", "bookskill_hand to hand3", "bookskill_hand to hand4", "bookskill_hand to hand5", "bk_LivesOfTheSaints", "bk_SaryonisSermons", "bk_HomiliesOfBlessedAlmalexia", "bk_PilgrimsPath", "bk_HouseOfTroubles_o", "bk_DoorsOfTheSpirit", "bk_MysteriousAkavir", "bk_spiritofnirn", "bk_vivecandmephala", "bk_istunondescosmology", "bk_firmament", "bk_manyfacesmissinggod", "bk_frontierconquestaccommodat", "bk_truenatureoforcs", "bk_varietiesoffaithintheempire", "bk_tamrielicreligions", "bk_fivesongsofkingwulfharth", "bk_wherewereyoudragonbroke", "bk_nchunaksfireandfaith", "bk_vampiresofvvardenfell1", "bk_reflectionsoncultworship...", "bk_galerionthemystic", "bk_madnessofpelagius", "bk_realbarenziah2", "bk_realbarenziah3", "bk_realbarenziah4", "bk_OverviewOfGodsAndWorship", "bk_fragmentonartaeum", "bk_onoblivion", "bk_InvocationOfAzura", "bk_Mysticism", "bk_OriginOfTheMagesGuild", "bk_specialfloraoftamriel", "bk_oldways", "bk_wildelves", "bk_PigChildren", "bk_redbookofriddles", "bk_yellowbookofriddles", "bk_guylainesarchitecture", "bk_progressoftruth", "bk_easternprovincesimpartial", "bk_vampiresofvvardenfell2", "bk_gnisiseggmineledger", "bk_fortpelagiadprisonerlog", "bk_MixedUnitTactics", "bk_gnisiseggminepass", "bk_HouseOfTroubles_c", "bk_truenoblescode", "bk_NGastaKvataKvakis_c", "bk_legionsofthedead", "bk_darkestdarkness", "bk_NGastaKvataKvakis_o", "bk_hanginggardenswasten", "bk_itermerelsnotes", "bk_tiramgadarscredentials", "bk_corpsepreperation1_c", "bk_corpsepreperation1_o", "bk_sharnslegionsofthedead", "bk_SamarStarloversJournal", "bk_SpiritOfTheDaedra", "bk_VagariesOfMagica", "bk_WatersOfOblivion", "bk_LegendaryScourge", "bk_PostingOfTheHunt", "bk_TalMarogKersResearches", "bk_seniliasreport", "bk_graspingfortune", "bk_notefromsondaale", "bk_shishireport", "bk_galtisguvronsnote", "bk_sottildescodebook", "bk_NoteFromJ'Zhirr", "bk_eastempirecompanyledger", "bk_nemindasorders", "bk_ordersforbivaleteneran", "bk_treasuryreport", "bk_treasuryorders", "bk_BlasphemousRevenants", "bk_ConsolationsOfPrayer", "bk_BookDawnAndDusk", "bk_CantatasOfVivec", "bk_Anticipations", "bk_AncestorsAndTheDunmer", "bk_AedraAndDaedra", "bk_AnnotatedAnuad", "bk_ChildrensAnuad", "bk_ArcturianHeresy", "bk_ChangedOnes", "bk_ChildrenOfTheSky", "bk_AntecedantsDwemerLaw", "bk_ChroniclesNchuleft", "bk_BiographyBarenziah1", "bk_BiographyBarenziah2", "bk_BiographyBarenziah3", "bk_BriefHistoryEmpire1", "bk_BriefHistoryEmpire2", "bk_BriefHistoryEmpire3", "bk_BriefHistoryEmpire4", "bk_BrothersOfDarkness", "bk_BlackGlove", "bk_BlueBookOfRiddles", "bk_BoethiahPillowBook", "bk_a1_1_directionscaiuscosades", "bk_a1_2_antabolistocosades", "bk_a1_2_introtocadiusus", "bk_a1_4_sharnsnotes", "bk_a1_v_vivecinformants", "bk_A1_7_HuleeyaInformant", "bk_BookOfDaedra", "bk_ArcanaRestored", "bk_BookOfLifeAndService", "bk_BookOfRestAndEndings", "bk_AffairsOfWizards", "bk_CalderaRecordBook1", "bk_CalderaRecordBook2", "bk_AuraneFrernis1", "bk_auranefrernis2", "bk_auranefrernis3", "bk_6thhouseravings", "bk_CalderaMiningContract", "bk_ABCs", "bk_a1_11_zainsubaninotes", "note to hrisskar", "chargen statssheet", "bk_notetocalderaslaves", "bk_notetoinorra", "bk_notetocalderaguard", "bk_notetocalderamages", "bk_falanaamonote", "bk_notetovalvius", "bk_notefromirgola", "bk_notefrombildren", "bk_notesoldout", "bk_notefromferele", "bk_Dren_Hlevala_note", "bk_Dren_shipping_log", "bk_saryonisermonsmanuscript", "bk_messagefrommasteraryon", "bk_responsefromdivaythfyr", "bk_honorthieves", "bk_redbook426", "bk_yellowbook426", "bk_BrownBook426", "bk_orderfrommollismo", "bk_BlightPotionNotice", "bk_propertyofjolda", "bk_joldanote", "bk_eggorders", "bk_notefromradras", "bk_thesevencurses", "bk_thelostprophecy", "bk_kagrenac'stools", "bk_NoteToAmaya", "bk_vivecs_plan", "bk_vivec_murders", "bk_saryoni_note", "bk_vivec_no_murder", "bk_Dagoth_Urs_Plans", "bk_notefromberwen", "bk_varoorders", "bk_storagenotice", "bk_notetomenus", "bk_notefrombugrol", "bk_notefrombashuk", "bk_notebyaryon", "bk_BeramJournal1", "bk_BeramJournal2", "bk_BeramJournal3", "bk_BeramJournal4", "bk_BeramJournal5", "bk_impmuseumwelcome", "bk_dwemermuseumwelcome", "bk_pillowinvoice", "bk_ravilamemorial", "bk_fishystick", "bk_kagrenac'splans_excl", "bk_miungei", "bk_ynglingledger", "bk_ynglingletter", "bk_indreledeed", "bk_BriefHistoryEmpire1_oh", "bk_BriefHistoryEmpire2_oh", "bk_BriefHistoryEmpire3_oh", "bk_BriefHistoryEmpire4_oh", "bk_dispelrecipe_tgca", "bk_a1_1_caiuspackage", "bk_Ashland_Hymns", "bk_words_of_the_wind", "bk_five_far_stars", "bk_provinces_of_tamriel", "bk_galur_rithari's_papers", "bk_kagrenac'sjournal_excl", "bk_notes-kagouti mating habits", "bk_notefromnelos", "bk_notefromernil", "bk_enamor", "bk_wordsclanmother", "bk_corpsepreperation2_c", "bk_corpsepreperation3_c", "bk_ArkayTheEnemy", "bk_poisonsong1", "bk_poisonsong2", "bk_poisonsong3", "bk_poisonsong4", "bk_poisonsong5", "bk_poisonsong6", "bk_poisonsong7", "bk_Confessions", "bk_hospitality_papers", "bk_uleni's_papers", "bk_redorancookingsecrets", "bk_widowdeed", "bk_guide_to_vvardenfell", "bk_guide_to_vivec", "bk_guide_to_balmora", "bk_guide_to_ald_ruhn", "bk_guide_to_sadrithmora", "text_paper_roll_01", "bk_seydaneentaxrecord", "bk_a1_1_packagedecoded", "bk_a2_1_sevenvisions", "bk_a2_1_thestranger", "sc_hellfire", "sc_ninthbarrier", "sc_restoration", "sc_blackstorm", "sc_balefulsuffering", "sc_bloodthief", "sc_mindfeeder", "sc_psychicprison", "sc_lesserdomination", "sc_greaterdomination", "sc_supremedomination", "sc_argentglow", "sc_redsloth", "sc_reddeath", "sc_redmind", "sc_redfate", "sc_redscorn", "sc_redweakness", "sc_reddespair", "sc_manarape", "sc_elevramssty", "sc_fadersleadenflesh", "sc_dedresmasterfuleye", "sc_golnaraseyemaze", "sc_didalasknack", "sc_daerirsmiracle", "sc_daydenespanacea", "sc_salensvivication", "sc_vaerminaspromise", "sc_blackdeath", "sc_blackdespair", "sc_blackfate", "sc_blackmind", "sc_blackscorn", "sc_blacksloth", "sc_blackweakness", "sc_tendilstrembling", "sc_feldramstrepidation", "sc_reynosbeastfinder", "sc_mageseye", "sc_tevralshawkshaw", "sc_radrenesspellbreaker", "sc_alvusiaswarping", "sc_corruptarcanix", "sc_greydeath", "sc_greydespair", "sc_greyfate", "sc_greymind", "sc_greyscorn", "sc_greysloth", "sc_greyweakness", "sc_ulmjuicedasfeather", "sc_taldamsscorcher", "sc_elementalburstfire", "sc_selisfieryward", "sc_dawnsprite", "sc_bloodfire", "sc_vigor", "sc_vitality", "sc_insight", "sc_gamblersprayer", "sc_heartwise", "sc_celerity", "sc_mageweal", "sc_savagemight", "sc_oathfast", "sc_gonarsgoad", "sc_mondensinstigator", "sc_illneasbreath", "sc_radiyasicymask", "sc_brevasavertedeyes", "sc_tinurshoptoad", "sc_uthshandofheaven", "sc_princeovsbrightball", "sc_lordmhasvengeance", "sc_elementalburstfrost", "sc_windform", "sc_stormward", "sc_purityofbody", "sc_warriorsblessing", "sc_galmsesseal", "sc_mark", "sc_llirosglowingeye", "sc_ondusisunhinging", "sc_sertisesporphyry", "sc_toususabidingbeast", "sc_telvinscourage", "sc_leaguestep", "sc_tranasasspelltrap", "sc_flameguard", "sc_shockguard", "sc_healing", "sc_firstbarrier", "sc_secondbarrier", "sc_thirdbarrier", "sc_fourthbarrier", "sc_fifthbarrier", "sc_sixthbarrier", "sc_inaschastening", "sc_elementalburstshock", "sc_nerusislockjaw", "sc_fphyggisgemfeeder", "sc_tranasasspellmire", "sc_reynosfins", "sc_inasismysticfinger", "sc_daynarsairybubble", "sc_selynsmistslippers", "sc_flamebane", "sc_frostbane", "sc_shockbane", "bk_BriefHistoryofWood", "bk_RealBarenziah1", "bk_RealBarenziah5", "sc_divineintervention", "sc_messengerscroll", "sc_cureblight_ranged", "sc_summondaedroth_hto", "sc_summongoldensaint", "bk_bartendersguide", "bk_NerevarineNotice", "bk_Warehouse_log", "sc_invisibility", "sc_windwalker", "sc_tranasasspelltwist", "sc_tevilspeace", "bk_red_mountain_map", "bk_arrilles_tradehouse", "sc_FiercelyRoastThyEnemy_unique", "bk_talostreason", "bk_a2_2_dagoth_message", "bk_EggOfTime", "bk_DivineMetaphysics", "bk_a1_1_elone_to_Balmora", "bk_note", "writ_yasalmibaal", "writ_oran", "writ_saren", "writ_sadus", "writ_vendu", "writ_guril", "writ_galasa", "writ_mavon", "writ_belvayn", "writ_bemis", "writ_brilnosu", "writ_navil", "writ_varro", "writ_baladas", "writ_bero", "writ_therana", "bk_great_houses", "sc_summonskeletalservant", "sc_summonflameatronach", "sc_summonfrostatronach", "bk_charterMG", "bk_charterFG", "bk_Ibardad_Elante_notes", "BookSkill_Destruction5_open", "BookSkill_Axe5_open", "bk_Boethiah's Glory_unique", "bk_Aedra_Tarer_Unique", "bk_ocato_recommendation", "bk_Ajira1", "bk_Ajira2", "Cumanya's Notes", "sc_Malaki", "sc_drathissoulrot", "sc_drathiswinterguest", "sc_Vulpriss", "bk_BriefHistoryofWood_01", "bk_landdeed_hhrd", "bk_landdeedfake_hhrd", "bk_stronghold_c_hlaalu", "bk_stronghold_ld_hlaalu", "bk_V_hlaaluprison", "bk_Hlaalu_Vaults_Ledger", "sc_Indie", "bk_Nerano", "sc_Tyronius", "bk_shalitjournal_deal", "bk_shalit_note", "bk_drenblackmail", "bk_notetomalsa", "bk_Redoran_Vaults_Ledger", "bk_ILHermit_Page", "note_Peke_Utchoo", "bk_clientlist", "bk_contract_ralen", "bk_letterfromllaalam", "bk_letterfromjzhirr", "bk_letterfromllaalam2", "bk_letterfromgadayn", "bk_leaflet_false", "bk_Telvanni_Vault_Ledger", "sc_almsiviintervention", "bk_Yagrum's_Book", "bk_lustyargonianmaid", "bk_AlchemistsFormulary", "bk_SecretsDwemerAnimunculi", "sc_icarianflight", "bk_fellowshiptemple", "bk_formygodsandemperor", "bk_ordolegionis", "bk_bartendersguide_01", "bookskill_mystery5", "bk_notetotelvon", "bk_WaroftheFirstCouncil", "bk_OnMorrowind", "bk_RealNerevar", "bk_NerevarMoonandStar", "bk_SaintNerevar", "bk_ShortHistoryMorrowind", "bk_falljournal_unique", "sc_ekashslocksplitter", "sc_frostguard", "sc_paper plain", "sc_paper_plain_01_canodia", "BookSkill_Alchemy1", "bookskill_speechcraft2", "bk_LivesOfTheSaints", "bk_SaryonisSermons", "bk_MysteriousAkavir", "bk_firmament", "bk_tamrielicreligions", "bk_easternprovincesimpartial", "bk_HouseOfTroubles_c", "bk_legionsofthedead", "bk_graspingfortune", "bk_ConsolationsOfPrayer", "bk_BookDawnAndDusk", "bk_Anticipations", "bk_AncestorsAndTheDunmer", "bk_AnnotatedAnuad", "bk_ChildrensAnuad", "bk_ArcturianHeresy", "bk_ChildrenOfTheSky", "bk_ChroniclesNchuleft", "bk_BookOfDaedra", "bk_bartendersguide", "bk_Yagrum's_Book", "bk_AlchemistsFormulary", "bk_commontongue", "bk_commontongue_irano", "bk_Irano_note", "bk_Alen_note", "writ_Berano", "writ_Hloggar", "writ_Alen", "bk_playscript", "bk_ahnia", "bk_nermarcnotes", "bk_custom_armor", "book_dwe_pipe00", "book_dwe_cogs00", "book_dwe_mach00", "book_dwe_water00", "book_dwe_power_con00", "book_dwe_metal_fab00", "bk_Teran_invoice", "book_dwe_boom00", "bk_diary_sailor", "bk_dbcontract", "sc_chridittepanacea", "bk_Adren", "bk_suicidenote", "bk_Artifacts_Tamriel", "BookSkill_Acrobatics2", "bk_HouseOfTroubles_o", "bk_MixedUnitTactics", "bk_HouseOfTroubles_c", "bk_BlasphemousRevenants", "bk_a1_1_directionscaiuscosades", "bk_five_far_stars", "sc_paper plain", "sc_Erna", "bk_snowprince", "bk_BMtrial_unique", "bk_ThirskHistory", "bk_Airship_Captains_Journal", "sc_GrandfatherFrost", "sc_Erna01", "sc_Chappy_sniper_test", "bk_Sovngarde", "bk_BM_Aevar", "bk_BM_StoneMap", "sc_unclesweetshare", "bk_fur_armor", "sc_jeleen", "bk_colonyreport", "sc_savagetyranny", "bk_carniusnote", "bk_BM_Stockcert", "sc_piratetreasure", "bk_ThirskHistory_revised_m", "bk_ThirskHistory_revised_f", "sc_fur_armor", "sc_fjellnote", "sc_sjobalnote", "sc_frosselnote", "sc_fjaldingnote", "bk_fryssajournal", "bk_necrojournal", "bk_leggejournal", "sc_bodily_restoration", "sc_bloodynote_s", "bk_colony_Toralf", "sc_hiddenkiller", "sc_lycanthropycure", "sc_witchnote", "sc_rumornote_bm"
}
Config.BlockDefaultObjects = false --if this is true the script also blocks all normaly present objects from being interacted with, by default the script only blocks player placed items
Config.BlockInventoryAdd = false --this prevents players from adding stuff to there inventory inside shops, used for fixing people being able to pick stuff up from there inventory.

jcMarketplace = {} --Global


local DATA = jsonInterface.load("custom/marketplaceData.json")
if DATA == nil then
    DATA = {}
end

local save = function()
	jsonInterface.save("custom/marketplaceData.json", DATA)
end

local SELECTED = {} --items selected by players


local msg = function(pid, text)
    if text == nil then --Apparently this has happened once
        text = "Msg Error, please report what you were doing to Kneg."
        tes3mp.LogMessage(enumerations.log.ERROR, "[Marketplace] msg called with nil text") 
        tes3mp.LogMessage(enumerations.log.ERROR, debug.traceback())
    end
    if pid == nil then
        tes3mp.LogMessage(enumerations.log.ERROR, "[Marketplace] msg called with nil pid") 
        tes3mp.LogMessage(enumerations.log.ERROR, debug.traceback())
        return
    end
	tes3mp.SendMessage(pid, color.GreenYellow .. "[Marketplace] " .. color.Default .. text .. "\n" .. color.Default)
end


local split = function(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local name2pid = function(name)
	local name = name:lower()
	for pid,_ in pairs(Players) do
		if string.lower(Players[pid].accountName) == name then
			return pid
		end
	end
	return nil
end

local checkMarketAndOwn = function(cell, name)
    if DATA[cell] == nil then
        msg(pid, "There's not a market here.")
        return false
    end

    if DATA[cell]["owner"] ~= name then
        msg(pid, "You dont own this market.")
        return false
    end
    return true
end

local ownsCell = function(name, cell)
    if DATA[cell] == nil then return false end

    if DATA[cell]["owner"] == name then
        return true
    else
        return false
    end
end

local name2cell = function(name)
    for key,_ in pairs(DATA) do
        if DATA[key]["owner"] == name then
            return key
        end
    end
    return nil
end

--Returns the amount of gold in a player's inventory
local getPlayerGold = function(pid)
	local goldLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, "gold_001", -1)
	
	if goldLoc then
		return Players[pid].data.inventory[goldLoc].count
	else
		return 0
	end
end

--fake player so I can give them money when they're offline
local fakePlayer = function(name)
    local player = {}
    local accountName = fileHelper.fixFilename(name)
    player.accountFile = tes3mp.GetCaseInsensitiveFilename(tes3mp.GetModDir() .. "/player/", accountName .. ".json")

    if player.accountFile == "invalid" then
        tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] WARNING fakePlayer called with invalid name!")
        return
    end

    player.data = jsonInterface.load("player/" .. player.accountFile)

    function player:Save()
        local config = require("config")
        jsonInterface.save("player/" .. self.accountFile, self.data, config.playerKeyOrder)
    end

    return player
end

--add the purchased item to the player
local addItem = function(pid, refIndex)
    local cell = tes3mp.GetCell(pid)
    local _refId = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]
    local amount = LoadedCells[cell]["data"]["objectData"][refIndex]["count"]
	local _soul = LoadedCells[cell]["data"]["objectData"][refIndex]["soul"]
	
    if amount == nil then
        amount = 1
    end
    local item = LoadedCells[cell]["data"]["objectData"][refIndex]

    --msg(pid, "BUYING " .. _refId .. ": " .. tostring(amount) .. "!!")

    local itemLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, _refId, -1) --find the item in the players inventory
    --local itemLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, _refId, item["charge"], item["enchantmentCharge"], item["soul"]) --find the item in the players inventory
	if itemLoc then --if the player already has that item in there inventory
        Players[pid].data.inventory[itemLoc].count = Players[pid].data.inventory[itemLoc].count + amount --add to there already existing item stack
    else
        table.insert(Players[pid].data.inventory, {refId = _refId, count = amount, soul = _soul}) --add new item to players inventory
		--table.insert(Players[pid].data.inventory, item) --add new item to players inventory
    end
	
	-- Lear edit start	-	Correct purchasing of enchanted items.
	local recordStore = logicHandler.GetRecordStoreByRecordId(_refId)

	if recordStore ~= nil then
		Players[pid]:AddLinkToRecord(recordStore.storeType, _refId)
	end
	-- Lear edit end.
	
    --remove the item from the cell
    local uniqueIndexes = { refIndex }
    for pid, ply in pairs(Players) do
        if ply:IsLoggedIn() then
            LoadedCells[cell]:LoadObjectsDeleted(pid, LoadedCells[cell]["data"]["objectData"], uniqueIndexes)
        end
    end
    LoadedCells[cell]["data"]["objectData"][refIndex] = nil
    LoadedCells[cell]:Save()

    --remove the item from out data
    DATA[cell]["items"][refIndex] = nil

    --the player should always be logged in 
	Players[pid]:Save()
	Players[pid]:LoadInventory()
    Players[pid]:LoadEquipment()
    Players[pid]:LoadQuickKeys()
end

local addGold = function(name, amount)
    local pid = name2pid(name)
    local accountFile = ""
    local player = {}
    if pid == nil then -- if the player isn't logged in 
        player = fakePlayer(name)
    else
        player = logicHandler.GetPlayerByName(name) --tecnicaly you can use this for offline players aswell but the save function doesn't work see: https://github.com/TES3MP/CoreScripts/pull/73
    end
    

	local goldLoc = inventoryHelper.getItemIndex(player.data.inventory, "gold_001", -1) --get the location of gold in the players inventory
	
	if goldLoc then --if the player already has gold in there inventory
		player.data.inventory[goldLoc].count = player.data.inventory[goldLoc].count + amount --add the new gold onto his already existing stack
	else
		table.insert(player.data.inventory, {refId = "gold_001", count = amount, charge = -1}) --create a new stack of gold
    end
    
    
    player:Save()
    if pid ~= nil then --if the player is online
        player:LoadInventory()
        player:LoadEquipment()
        player:LoadQuickKeys()
    end
end

--the menu when you activate an item
local GUIItem = function(pid, refIndex)
    if Players[pid] == nil then return end --HOW DOES THIS HAPPEN

    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local isOwner = ownsCell(name, cell)
    if LoadedCells[cell] == nil then return end
    if LoadedCells[cell]["data"]["objectData"][refIndex] == nil then return end
    local itemName = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]

    local message = "Item: " .. itemName
    local currentPrice = DATA[cell]["items"][refIndex]
    if currentPrice ~= nil then
        message = message .. "\nCurrent price: " .. tostring(currentPrice)
    end

    if isOwner then
        tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Set Price;Clear Price;Exit")
    else
        if DATA[cell]["items"][refIndex] ~= nil then --if the activated item is for sale
            local price = DATA[cell]["items"][refIndex]
            message = message .. "\nPrice: " .. tostring(price)
            tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Buy;Exit")
        end
    end

    --if DATA[cell]["items"][refIndex] ~= nil then
    
    --tes3mp.CustomMessageBox(pid, Config.GUIItem, message, "Buy;Exit")
end

--the price setting menu
local GUIPrice = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local refIndex = SELECTED[name]
    local itemName = LoadedCells[cell]["data"]["objectData"][refIndex]["refId"]

    local message = "Item: " .. itemName .. "\nSet price too:"
    tes3mp.InputDialog(pid, Config.GUIPrice, message, "")
end

--when you remove the price from an item
--originaly I didn't have this cus you can just pick up the item and place it down again but I thought it would probably be a good idea
local clearItemPrice = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)

    if SELECTED[name] == nil then return end

    DATA[cell]["items"][SELECTED[name]] = nil
    msg(pid, "Item " .. SELECTED[name] .. "'s price has been cleared.")
    SELECTED[name] = nil
end

--When you click the buy item button 
local buyItem = function(pid)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local playerGold = getPlayerGold(pid)
    local cost = DATA[cell]["items"][SELECTED[name]]
-- Lear edit start to resolve nil crash.
	if cost == nil then return end
	if playerGold == nil then return end
-- Lear edit end to resolve nil crash.
    if cost > playerGold then
        msg(pid, "You dont have enoght gold to buy this item.")
        return
    end
-- Lear edit start to resolve nil crash.
	if cell == nil then return end
	if LoadedCells[cell]["data"]["objectData"][SELECTED[name]]["refId"] == nil then return end
-- Lear edit end to resolve nil crash.
    local itemName = LoadedCells[cell]["data"]["objectData"][SELECTED[name]]["refId"]
    local ownerName = DATA[cell]["owner"]
    local ownerPid = name2pid(ownerName)
    if ownerPid ~= nil then --owner is online
        msg(ownerPid, name .. " bought " .. itemName .. " from you for " .. tostring(cost) .. "!")
    end

    --add message to messages/log
    local time = os.date("%Y-%m-%d %I:%M:%S")
    table.insert(DATA[cell]["messages"], time .. ": " .. name .. " bought " .. itemName .. " from you for " .. tostring(cost) .. " gold!")

    addGold(ownerName, cost) --add gold to the owner
    addGold(name, -cost) --remove gold from the buyer
    addItem(pid, SELECTED[name]) --add the item to the buyers inventory
                
    msg(pid, "You've bought the " .. itemName .. "!")
    SELECTED[name] = nil
    save()
end

--when you type /marketadd/marketcreate
local marketCreate = function(pid)

    if type(pid) ~= "number" then return end
    if Players[pid] == nil then return end

    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    if LoadedCells[cell].isExterior then --dont allow markets in external cells
        msg(pid, "You can't make a market in an exterior cell.")
        return
    end

    if DATA[cell] ~= nil then --we already have data about a market here
        msg(pid, "There already exists a market here.")
        return
    end
    
    --kanaHousing, I really dont see why you would use this whitout it
    if Config.kanaHouseIntergration and kanaHousing ~= nil then --if kanaHousing is installed

        --make sure its a house registered with kanaHousing
        if kanaHousing.GetCellData(cell) == false or kanaHousing.GetCellData(cell).house == nil then
            msg(pid, "This isn't a kanaHouse.")
            return
        end
        
        --check if the house owner is false aka noone owns the house
        if kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house) == false then
            --msg(pid, "You don't own this house. 1")
			msg(pid, "You don't own this house.")
            return
        end

        --check if the current player owns the house
        if kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house) ~= name then
            --msg(pid, "You don't own this house. 2")
			msg(pid, "You don't own this house.")
            return
        end

    end
    --kanaHousing.GetOwnerData(name)

    --create a new market
    DATA[cell] = {}
    DATA[cell]["owner"] = name
    DATA[cell]["items"] = {}
    DATA[cell]["messages"] = {}
    msg(pid, "Market created!")
    save()
    --isExterior
end

--when you use /market delete /market remove
local marketDelete = function(pid)
    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)

    if Players[pid]:IsAdmin() then --if they're an admin they can just delete all markets
        DATA[cell] = nil
        msg(pid, "[Admin] Market removed.")
        save()
        return
    end

    if not checkMarketAndOwn(cell, name) then return end

    DATA[cell] = nil
    msg(pid, "Market removed.")
    save()
end

-- Global function for other scripts to remove markets
jcMarketplace.marketDelete = function(cell)
    DATA[cell] = nil
    save()
end

--just print out all the messages in the logs
local marketLog = function(pid)
	local name = string.lower(Players[pid].accountName)
    local ownedCell = name2cell(name)
    if ownedCell == nil then
        msg(pid, "You don't own a market.")
        return
    end

    --msg(pid, "----START----")
    local outString = ""
    for _,message in pairs(DATA[ownedCell]["messages"]) do
        if message ~= nil then
            local maxLine = 47
            local currentChars = 0
            local wordList = {}

            for w in message:gmatch("%S+") do table.insert(wordList, w) end

            for _, word in pairs(wordList) do
                currentChars = currentChars + word:len()
                if currentChars > maxLine then
                    outString = outString .. "\n    " .. word .. " "
                    currentChars = 5 + word:len() + 1
                else
                    outString = outString .. word .. " "
                    currentChars = currentChars + 1
                end
                --outString = outString .. word .. "\n"
            end
            outString = outString .. "\n" 
            --msg(pid, message:len())
        end
    end
    tes3mp.ListBox(pid, -1, "Market log", outString)
    --msg(pid, "----END----")

end

--clear the log, maybe put a confirmation here
local marketClearLog = function(pid)
    local name = string.lower(Players[pid].accountName)
    local ownedCell = name2cell(name)

    if ownedCell == nil then 
        msg(pid, "You don't own a market.")
        return
    end

    DATA[ownedCell]["messages"] = nil --rip, atleast you still have your money
    msg(pid, "Log cleared.")
end

customCommandHooks.registerCommand("marketadd", marketCreate)
customCommandHooks.registerCommand("marketcreate", marketCreate)

customCommandHooks.registerCommand("marketremove", marketDelete)
customCommandHooks.registerCommand("marketdelete", marketDelete)

customCommandHooks.registerCommand("marketlog", marketLog)
customCommandHooks.registerCommand("marketmessages", marketLog)

customCommandHooks.registerCommand("marketclearlog", marketClearLog)

customCommandHooks.registerCommand("marketjcinfo", function(pid,cmd)

    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    local temp 

    temp = kanaHousing.GetCellData(cell)
    if temp == false then return end
    msg(pid, tostring(temp))

    temp = kanaHousing.GetCellData(cell).house
    if temp == false then return end
    msg(pid, tostring(temp))

    temp = kanaHousing.GetHouseOwnerName(kanaHousing.GetCellData(cell).house)
    if temp == false then return end
    msg(pid, tostring(temp))

    msg(pid, name)

end)

customCommandHooks.registerCommand("market", function(pid, cmd)
    local cell = tes3mp.GetCell(pid)
    local name = string.lower(Players[pid].accountName)
    
    if cmd[2] == nil then
        if DATA[cell] ~= nil then
            msg(pid, "There's a market owned by " .. DATA[cell]["owner"] .. " here.")
        else
            msg(pid, "There's no market here, use /marketcreate or /marketadd to create a market here.")
        end
    elseif cmd[2] == "add" or cmd[2] == "create" then
        marketCreate(pid)
    elseif cmd[2] == "remove" or cmd[2] == "delete" then
        marketDelete(pid)
    elseif cmd[2] == "log" or cmd[2] == "messages" then
        marketLog(pid)
    elseif cmd[2] == "clearlog" then
        marketClearLog(pid)
    end

end)


-- This should block all object deletes
customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
    local name = string.lower(Players[pid].accountName)

    if DATA[cellDescription] == nil then --its not in a cell we care about
        return
    end

    for n,object in pairs(objects) do
        local temp = split(object.uniqueIndex, "-")
        local RefNum = temp[1]
        local MpNum = temp[2]

        --dont block refIds in the NonBlocked list
        for _, refId in pairs(Config.NonBlockedRedIds) do
            if string.match(object.refId, refId) then
                return
            end
        end

        if DATA[cellDescription]["owner"] == name then --if its the owner of the cell they can do whatever they want
            if tes3mp.GetSneakState(pid) then -- they're crouching, open the item menu
                GUIItem(pid, object.uniqueIndex)
                SELECTED[name] = object.uniqueIndex
                eventStatus.validDefaultHandler = false
                return eventStatus
            end
            return
        end

        if tonumber(RefNum) == 0 then --its a placed item
            GUIItem(pid, object.uniqueIndex)
            SELECTED[name] = object.uniqueIndex
            eventStatus.validDefaultHandler = false
            return eventStatus
        end

        --block default objects
        if Config.BlockDefaultObjects and tonumber(MpNum) == 0 then
            eventStatus.validDefaultHandler = false
            return eventStatus
        end
    end

    return eventStatus
end)

customEventHooks.registerValidator("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)
	local name = string.lower(Players[pid].accountName)
	
	-- Lear edit start	-	Added below for admins to remove stuff.
	if Players[pid].data.settings.staffRank > 1 then return customEventHooks.makeEventStatus(true, false) end
	-- Lear edit end.
	
    if DATA[cellDescription] == nil then --its not in a cell we care about
        return
    end

    for n, object in pairs(objects) do
        local temp = split(object.uniqueIndex, "-")
        local RefNum = temp[1]
        local MpNum = temp[2]
        local refId = object.refId

        if string.match(object.refId, "door") then --if its a door we probably dont want to block it
            return
        end

        if DATA[cellDescription]["owner"] == name then --if its the owner of the cell they can do whatever they want
            return
        end

        if tonumber(RefNum) == 0 then --its a placed item
		
			msg(pid, "Sorry kid not on my watch " .. refId)
			--logicHandler.RunConsoleCommandOnPlayer(pid, "player->removeitem \"" .. object.refId .. "\", 1")
			inventoryHelper.removeClosestItem(Players[pid].data.inventory, object.refId, 1, nil, nil, nil)
			tes3mp.Kick(pid)
			
            return customEventHooks.makeEventStatus(false, false)
        end

        --block default objects
        if Config.BlockDefaultObjects and tonumber(MpNum) == 0 then
            --logicHandler.RunConsoleCommandOnPlayer(pid, "player->removeitem \"" .. object.refId .. "\", 1")
            inventoryHelper.removeClosestItem(Players[pid].data.inventory, object.refId, 1, nil, nil, nil)
            tes3mp.Kick(pid)
            return customEventHooks.makeEventStatus(false, false)
        end
    end

    return eventStatus
end)

if Config.BlockInventoryAdd then
    customEventHooks.registerValidator("OnPlayerInventory", function(eventStatus, pid)
        local name = string.lower(Players[pid].accountName)
        local cell = tes3mp.GetCell(pid)

        if DATA[cell] == nil then --its not in a cell we care about
            return
        end

        if DATA[cell]["owner"] == name then --if its the owner of the cell they can do whatever they want
            return
        end

        local action = tes3mp.GetInventoryChangesAction(pid)
        local itemChangesCount = tes3mp.GetInventoryChangesSize(pid)

        if action == 1 then -- ADD
            --msg(pid, tostring(action))
            --for index = 0, itemChangesCount - 1 do
                --local itemRefId = tes3mp.GetInventoryItemRefId(pid, index)
                --msg(pid, itemRefId)
            --end

            Players[pid]:LoadInventory()
            Players[pid]:LoadEquipment()
            Players[pid]:LoadQuickKeys()
            return customEventHooks.makeEventStatus(false, false)
        end
        
    end)
end


customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
    local name = string.lower(Players[pid].accountName)
    local cell = tes3mp.GetCell(pid)
    local isOwner = ownsCell(name, cell)

    if idGui == Config.GUIItem then
        if isOwner then
            if tonumber(data) == 0 then --set price
                GUIPrice(pid)
            elseif tonumber(data) == 1 then --clear price
                clearItemPrice(pid)
            end
        else
            if tonumber(data) == 0 then -- were buying the item
                buyItem(pid)
            end
        end
    elseif idGui == Config.GUIPrice then -- we've set a price on an item
        if tonumber(data) == nil then
            msg(pid, "You didn't enter a valid number.")
        else
            local newPrice = tonumber(data)

            if newPrice < 0 then
                msg(pid, "You can't set a negative price.")
                return
            end

            if SELECTED[name] == nil then --this really shouldn't happen but apparently it has
                tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] Someone tried to set the price of an item but haven't actually selected an item.")
                return
            end

            if DATA[cell] == nil then --this really shouldn't happen but apparently it has
                tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] Someone tried to set the price of an item in a non market cell.")
                return
            end

            DATA[cell]["items"][SELECTED[name]] = newPrice
            msg(pid, "Item " .. SELECTED[name] .. "'s price has been set to " .. tostring(data) .. ".")
            SELECTED[name] = nil
            save()
        end
    end

end)
