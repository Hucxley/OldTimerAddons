-----------------------------------------------------------------------------------------------
-- Client Lua Script for GuildRosterTools
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GuildLib"
require "Apollo"
require "GuildTypeLib"
require "GameLib"
 
-----------------------------------------------------------------------------------------------
-- GuildRosterTools Module Definition
-----------------------------------------------------------------------------------------------
local GuildRosterTools = {}
local IO
 
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
	self.timeLastExported = nil
    return o
end

function GuildRosterTools:Init()
    Apollo.RegisterAddon(self, false, "", {"GeminiIO-1.0"})
end

function GuildRosterTools:OnSave(eLevel)
	-- We save at a character level in case of alts in different guilds
		if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end

	tSave = {}
	
	self.timeLastExported = timeLastExported
	tSave = {nTimeLastExported = self.timeLastExported}	
	return tSave
end

function GuildRosterTools:OnRestore(eLevel,tSavedData)
	if tSavedData.nTimeLastExported ~= nil then
		self.timeLastExported = tSavedData.nTimeLastExported
	else
		self.timeLastExported = 0
	end
	
	

end  

-----------------------------------------------------------------------------------------------
-- GuildRosterTools OnLoad
-----------------------------------------------------------------------------------------------
function GuildRosterTools:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("GuildRosterTools.xml")
	-- load IO package 
	IO = Apollo.GetPackage("GeminiIO-1.0").tPackage
	
	
end

-----------------------------------------------------------------------------------------------
-- GuildRosterTools GetAsyncLoadStatus
-----------------------------------------------------------------------------------------------
function GuildRosterTools:GetAsyncLoadStatus()

	-- check for external dependencies here
	if g_AddonsLoaded == nil then
		g_AddonsLoaded = {}
	end
	if not g_AddonsLoaded["WhatToLookFor"] and false then
		-- replace 'WhatToLookFor' with the name of the Addon you're waiting on
		-- and remove 'and false'
		return Apollo.AddonLoadStatus.Loading
	end

	if self.xmlDoc:IsLoaded() then
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
		Apollo.RegisterSlashCommand("guildtools", "OnGuildRosterToolsOn", self)
    	Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self)

		-- Do additional Addon initialization here
		if self.timeLastExported == nil then
		  timeLastExported = 0
		else timeLastExported = self.timeLastExported
		end
		bExportDelayOverride = false
		-- register our Addon so others can wait for it if they want
		g_AddonsLoaded["GuildRosterTools"] = true
		
		return Apollo.AddonLoadStatus.Loaded
	end
	return Apollo.AddonLoadStatus.Loading 
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
	--Print(timeLastExported)
  local currTime = self:getCurrTime()
	--Print(currTime)
	
  if (currTime-timeLastExported) > 3600 or bExportDelayOverride == true then	
    local date = os.date("%m/%d/%y")
    local time = os.date("%H:%M")
	local realmName = GameLib.GetRealmName()
    local tGuild = self:GetGuild()
    local guildName = tGuild:GetName()
    local tRanks = guildCurr:GetRanks()
    local strPlayerDataRow = ""
    local IO = Apollo.GetAddon("GeminiIO-1.0")
    local strPath = "c:\\WildStarRosters\\".. realmName .. " " .. guildName .. " Roster.csv"
	IO:BuildFileStreamWriter(strPath)
    local timeStamp = (time .. " " .. date) 
	local strTimeExported = (timeStamp .."\n")
	IO:OpenFile(strPath)
	local headers = ("Server"..",".."Guild"..",".."Forum Name"..",".."Player Name"..",".."Rank"..",".."Class"..",".."Path"..",".."Last Online".."\n")
	IO:WriteToFile(strPath,strTimeExported)
	IO:CloseFile(strPath)
	IO:OpenFile(strPath,true)
    IO:WriteToFile(strPath,headers)

    for key, tCurr in pairs(tGuildRoster) do
  	   if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
    	  strRank = tRanks[tCurr.nRank].strName
    	  strRank = FixXMLString(strRank)	
       end
	
    	--map tRoster values
		local strRealm = realmName
    	local strNote = tCurr.strNote
      	local strName = tCurr.strName
    	local strClass = tCurr.strClass
    	local strPlayerPath = self:HelperConvertPathToString(tCurr.ePathType)
    	local strLastOnline = self:HelperConvertToTime(tCurr.fLastOnline)
     	local strPlayerDataRow = (strRealm .. "," .. guildName .. "," .. strNote .. "," .. strName .. "," .. strRank .. "," .. strClass .. "," .. strPlayerPath .. "," .. strLastOnline .. "\n")     	IO:WriteToFile(strPath, strPlayerDataRow)
    end
  	IO:CloseFile(strPath)
	timeLastExported = self:getCurrTime()  --9:59pm
  else
	Print("Last export was completed less than an hour ago, and will not be completed at this time.")
	end
  
end

function GuildRosterTools:ExportData()
	local tGuild = self:GetGuild()
    	if tGuild then
    tGuild:RequestMembers()
    end
	local bExportDelayOverride = true
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
function GuildRosterTools:getCurrTime()
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
