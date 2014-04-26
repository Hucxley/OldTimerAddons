-----------------------------------------------------------------------------------------------
-- Client Lua Script for CustomFoV
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- CustomFoV Module Definition
-----------------------------------------------------------------------------------------------
local CustomFoV = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CustomFoV:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    return o
end

function CustomFoV:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function CustomFoV:OnSave(eLevel)
	-- We save at an account level, so that notes are shared among
	-- all characters
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account) then
		return
	end

	tSave = {}
	
	self.Fov = nFov
	tSave = {nFoV = self.Fov}	
	return tSave
end
 
function CustomFoV:OnRestore(eLevel,tSavedData)
	if tSavedData.nFoV ~= nil then
		nFov = tSavedData.nFoV
	else
		nFov = 50
	end
	
end 
-----------------------------------------------------------------------------------------------
-- CustomFoV OnLoad
-----------------------------------------------------------------------------------------------
function CustomFoV:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CustomFoV.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CustomFoV OnDocLoaded
-----------------------------------------------------------------------------------------------
function CustomFoV:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CustomFoVForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		self.wndTextBox = self.wndMain:FindChild("FoVBox") -- get Text Box window
		
		self.wndMain:FindChild("InstructionsFrame"):SetText("Enter your desired FoV in the box below.  The default value is 50, but many players find 60-75 less fatiguing.")
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("setfov", "OnCustomFoVOn", self)
		Print(nFov)
		if nFov ~= 50 then
			self.wndTextBox:SetText(tostring(nFov))
		else
			nFov = nil
		end

		-- Do additional Addon initialization here
		
	end
end

-----------------------------------------------------------------------------------------------
-- CustomFoV Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function CustomFoV:AdjustFoV()
	local strFov = self.wndTextBox:GetText()
	nFov = tonumber(strFov)
	Print(nFov)
	if nFov == nil then
		print("Default FoV value loaded (50)")
	else
		Apollo.SetConsoleVariable("camera.FovY", nFov)
	end
end

-- on SlashCommand "/setfov"
function CustomFoV:OnCustomFoVOn()
	self.wndMain:Invoke() -- show the window
end


-----------------------------------------------------------------------------------------------
-- CustomFoVForm Functions
-----------------------------------------------------------------------------------------------
-- when the Cancel button is clicked
function CustomFoV:OnCancel()
	self.wndMain:Close() -- hide the window
end

-- when the Apply Changes button is clicked
function CustomFoV:OnApply()
	self:AdjustFoV()	
end


-----------------------------------------------------------------------------------------------
-- CustomFoV Instance
-----------------------------------------------------------------------------------------------
local CustomFoVInst = CustomFoV:new()
CustomFoVInst:Init()
