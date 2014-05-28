-----------------------------------------------------------------------------------------------
-- Client Lua Script for GuildRosterTools
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GuildLib"
require "Apollo"
require "GameLib"
require "ChatSystemLib"
 
-----------------------------------------------------------------------------------------------
-- GuildRosterTools Module Definition
-----------------------------------------------------------------------------------------------
local GuildRosterTools = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function GuildRosterTools:new(o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self 

		-- initialize variables here
	self.troster = nil
	self.TimeLastExported = nil
		return o
end

function GuildRosterTools:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	
	}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function GuildRosterTools:OnSave(eLevel)
	-- We save at a character level in case of alts in different guilds
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end

	tSave = {}
	self.TimeLastExported = TimeLastExported
	
	
	local nTimeLastExported = self.TimeLastExported
	local tHeaders = {strHeaders}
	local strGuild = strGuildName
	local tRosterData = tDataExport
	local strPlayerName = strPlayerName
	
	--local tSavedExportValues = {nTimeLastExported,strGuild,tHeaders,tRosterData}
	tSave["nTimeLastExported"] = nTimeLastExported
	tSave["strGuild"] = strGuild
	tSave["tHeaders"] = tHeaders
	tSave["tRosterData"] = tRosterData
	tSave["strPlayerName"] = strPlayerName
	
	--local tSave = tSavedExportValues

	return tSave
end

function GuildRosterTools:OnRestore(eLevel,tSavedData)
	if tSavedData.nTimeLastExported ~= nil then
		self.TimeLastExported = tSavedData.nTimeLastExported
	else
		self.TimeLastExported = 0
	end
	if tSavedData.strGuild ~= nil then
		self.strGuild = tSavedData.strGuild
	else
		self.strGuild = ""
	end
	if tSavedData.tHeaders ~= nil then
		self.tHeaders = tSavedData.tHeaders
	else
		self.tHeaders = {}
	end
	if tSavedData.tRosterData ~= nil then
		self.tRosterData = tSavedData.tRosterData
	else
		self.tRosterData = {}
	end
	if tSavedData.strPlayerName ~= nil then 
		self.strPlayerName = tSavedData.strPlayerName
	else
		self.strPlayerName = ""
	end
end  

-----------------------------------------------------------------------------------------------
-- GuildRosterTools OnLoad
-----------------------------------------------------------------------------------------------
function GuildRosterTools:OnLoad()
		-- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("GuildRosterTools.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	end

-----------------------------------------------------------------------------------------------
-- GuildRosterTools OnDocLoaded
-----------------------------------------------------------------------------------------------
function GuildRosterTools:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "GuildRosterToolsForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return Apollo.AddonLoadStatus.LoadingError
		end
		
		self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("grt", "OnGuildRosterToolsOn", self)
		Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self)
		Apollo.RegisterSlashCommand("grtResetTime", "ResetTime",self)

		-- Do additional Addon initialization here
		if self.TimeLastExported == nil then
			TimeLastExported = 0
		else
			TimeLastExported = self.TimeLastExported
		end
		if self.strGuild == nil then
			strGuildName = ""
		else
			strGuildName = self.strGuild
		end
		if self.tHeaders == nil then
			strHeaders = ""
		else
			strHeaders = table.concat(self.tHeaders,",")
		end
		if self.tRosterData == nil then
			tDataExport = {}
		else
			tDataExport = self.tRosterData
		end
		if self.strPlayerName == nil then
			strPlayerName = ""
		else
			strPlayerName = self.strPlayerName
		end
				
		bExportDelayOverride = false

		ChatSystemLib.PostOnChannel(2,"GuildRosterTools: GuildRosterTools loaded. \nUse /grt to open the Roster Export Window.  \nUse /grtResetTime to reset last export time.")
	end
end

-----------------------------------------------------------------------------------------------
-- GuildRosterTools Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/guildtools"
function GuildRosterTools:OnGuildRosterToolsOn()
	self.wndMain:Show(true) -- show the window
end



function GuildRosterTools:OnGuildRoster(guildCurr, tGuildRoster)
	
	local currTime = self:GetCurrTime()
	
	
	if (currTime - TimeLastExported) > 900 or bExportDelayOverride == true then 
		--Export Guild Roster
		tDataExport = {}
		local nDate= os.date("%m/%d/%y")
		local nTime= os.date("%H:%M")
		local strRealmName = GameLib.GetRealmName()
		local tGuild = self:GetGuild()
		strPlayerName = GameLib.GetPlayerUnit():GetName()
		strGuildName = tGuild:GetName()
		local tRanks = guildCurr:GetRanks()
		local strPlayerDataRow = ""
		local strPath = "Wildstar Addon Save Data for "..strPlayerName
		local timeStamp = (nTime.. " " ..nDate) 
		strTimeExported = timeStamp
		strHeaders = ("Server"..",".."Guild"..",".."Forum Name"..",".."Player Name"..",".."Level"..",".."Rank"..",".."Class"..",".."Path"..",".."Last Online"..",".."Days Offline")
	

		for key, tCurr in pairs(tGuildRoster) do
			 if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
				strRank = tRanks[tCurr.nRank].strName
				strRank = FixXMLString(strRank)	
			 end
	
			--map tRoster values
			local strRealm = strRealmName
			local strNote = tCurr.strNote
			local strName = tCurr.strName
			local nLevel = tCurr.nLevel
			local strClass = tCurr.strClass
			local strPlayerPath = self:HelperConvertPathToString(tCurr.ePathType)
			local strLastOnline = self:HelperConvertToTime(tCurr.fLastOnline)
			local nRawLastOnline = tCurr.fLastOnline
			strPlayerDataRow = (strRealm .. ", " .. strGuildName.. ", " .. strNote .. ", " .. strName .. ", " .. nLevel .. ", " .. strRank .. ", " .. strClass .. ", " .. strPlayerPath .. ", " .. strLastOnline .. ", " .. nRawLastOnline)     	
			table.insert(tDataExport,strPlayerDataRow)
			self.wndMain:FindChild("DisplayFrame"):SetText("Exporting:"..strName)
		end
		
	TimeLastExported = self:GetCurrTime()
	--Print(TimeLastExported)
	self.wndMain:FindChild("DisplayFrame"):SetText("Last Export processed to: "..strPath.."! (Export time/date: "..timeStamp..")")
	bExportDelayOverride = false
	else
	tDataExport = tDataExport
	strGuildName = strGuildName
	TimeLastExported = TimeLastExported
	strHeaders = strHeaders
	strPlayerName = strPlayerName
	end
	
end

function GuildRosterTools:ExportData()
	bExportDelayOverride = true
	Print("Export Guild Roster manual override processing.")
	local tGuild = self:GetGuild()
		if tGuild then
			tGuild:RequestMembers()
		end
end

function GuildRosterTools:GetGuild()
	local tGuild = nil
	for k,g in pairs(GuildLib.GetGuilds()) do
		if g:GetType() == GuildLib.GuildType_Guild then
		tGuild = g
		end
	end
	return tGuild
end

function GuildRosterTools:ResetTime()
	TimeLastExported = 0
	Print("Last Export time reset.  Guild Roster will auto-update")
end



-----------------------------------------------------------------------------------------------
-- GuildRosterToolsForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function GuildRosterTools:OnOK()
	self.wndMain:Show(false) -- hide the window
end

-- when the Cancel button is clicked
function GuildRosterTools:OnCancel()
	self.wndMain:Show(false) -- hide the window
end

function GuildRosterTools:OnExport()
	GuildRosterTools:ExportData()
end

---------------------------------
--Helper Functions
---------------------------------
function GuildRosterTools:GetCurrTime()
	return os.time()
end

function GuildRosterTools:HelperConvertPathToString(ePath)
	local strResult = ""
	if ePath == PlayerPathLib.PlayerPathType_Soldier then
		strResult = Apollo.GetString("PlayerPathSoldier")
	elseif ePath == PlayerPathLib.PlayerPathType_Settler then
		strResult = Apollo.GetString("PlayerPathSettler")
	elseif ePath == PlayerPathLib.PlayerPathType_Explorer then
		strResult = Apollo.GetString("PlayerPathExplorer")
	elseif ePath == PlayerPathLib.PlayerPathType_Scientist then
		strResult = Apollo.GetString("PlayerPathScientist")
	end
	return strResult
end

function GuildRosterTools:HelperConvertToTime(fDays)
	if fDays == 0 then
		return Apollo.GetString("ArenaRoster_Online")
	end

	if fDays == nil then
		return ""
	end

	local tTimeInfo = {["name"] = "", ["count"] = nil}

	if fDays >= 365 then -- Years
		tTimeInfo["name"] = Apollo.GetString("CRB_Year")
		tTimeInfo["count"] = math.floor(fDays / 365)
	elseif fDays >= 30 then -- Months
		tTimeInfo["name"] = Apollo.GetString("CRB_Month")
		tTimeInfo["count"] = math.floor(fDays / 30)
	elseif fDays >= 7 then
		tTimeInfo["name"] = Apollo.GetString("CRB_Week")
		tTimeInfo["count"] = math.floor(fDays / 7)
	elseif fDays >= 1 then -- Days
		tTimeInfo["name"] = Apollo.GetString("CRB_Day")
		tTimeInfo["count"] = math.floor(fDays)
	else
		local fHours = fDays * 24
		local nHoursRounded = math.floor(fHours)
		local nMin = math.floor(fHours*60)

		if nHoursRounded > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Hour")
			tTimeInfo["count"] = nHoursRounded
		elseif nMin > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = nMin
		else
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = 1
		end
	end

	return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeInfo)
end

-----------------------------------------------------------------------------------------------
-- GuildRosterTools Instance
-----------------------------------------------------------------------------------------------
local GuildRosterToolsInst = GuildRosterTools:new()
GuildRosterToolsInst:Init()
