--
-- GlobalCompany - utils - GC_DebugUtils
--
-- @Interface: --
-- @Author: LS-Modcompany / kevink98 / GtX
-- @Date: 27.01.2019
-- @Version: 1.1.0.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
-- 	v1.1.0.0 (27.01.2019):
--		- update to GC_DebugUtils for fs19.
--
-- 	v1.0.0.0 (17.12.2017):
-- 		- initial fs17 [Debug] (kevink98)
--
-- Notes:
--		- Loaded before all scripts from 'GlobalCompany.lua'
--		- Global instance is 'g_company.debug'
--
-- ToDo:
--

GC_DebugUtils = {};
local GC_DebugUtils_mt = Class(GC_DebugUtils);
InitObjectClass(GC_DebugUtils, "GC_DebugUtils");

GC_DebugUtils.setDevLevelMax = true; -- Override isDev maxLevel loading to 'false' if needed. (LSMC DEV ONLY)

GC_DebugUtils.defaultLevel = 4; -- Default level used on load.

GC_DebugUtils.numLevels = 6; -- This is starting at `GC_DebugUtils.INFORMATIONS` as we do not disable 'ERROR' or 'WARNING'.
GC_DebugUtils.maxLevels = 20;

GC_DebugUtils.BLANK = -2; -- No 'PREFIX' and can not be disabled in console. (Used for main loading)
GC_DebugUtils.ERROR = -1;
GC_DebugUtils.WARNING = 0;
GC_DebugUtils.INFORMATIONS = 1;
GC_DebugUtils.LOAD = 2;
GC_DebugUtils.ONCREATE = 3;
GC_DebugUtils.TABLET = 4;
GC_DebugUtils.MODDING = 5;
GC_DebugUtils.DEV = 6;

function GC_DebugUtils:new(customMt)
	if g_company.debug ~= nil then
		print("  [LSMC - GlobalCompany > GC_DebugUtils] - Class already registered! Use 'g_company.debug' to access debug manager.");
		return;
	end;

	if customMt == nil then
		customMt = GC_DebugUtils_mt;
	end;

	local self = {};
	setmetatable(self, customMt);

	self.isDev = GC_DebugUtils:getIsDev();
	local setMax = self.isDev and GC_DebugUtils.setDevLevelMax;

	self.registeredScriptNames = {};

	self.registeredScripts = {};
	self.registeredScriptsCount = 0;

	self.registeredMods = {};
	self.registeredModsCount = 0;

	self.printLevel = {};
	self.printLevelPrefix = {};

	-- Set print levels.
	for i = -2, GC_DebugUtils.numLevels + 3 do
		if i <= GC_DebugUtils.defaultLevel or setMax then
			self.printLevel[i] = true;
		else
			self.printLevel[i] = false;
		end;

		self.printLevelPrefix[i] = "";
	end;

	-- Set print levels prefix.
	self.printLevelPrefix[GC_DebugUtils.BLANK] = "";
	self.printLevelPrefix[GC_DebugUtils.ERROR] = "ERROR: ";
	self.printLevelPrefix[GC_DebugUtils.WARNING] = "WARNING: ";
	self.printLevelPrefix[GC_DebugUtils.INFORMATIONS] = "INFORMATIONS: ";
	self.printLevelPrefix[GC_DebugUtils.LOAD] = "LOAD: ";
	self.printLevelPrefix[GC_DebugUtils.ONCREATE] = "ONCREATE: ";
	self.printLevelPrefix[GC_DebugUtils.TABLET] = "TABLET: ";
	self.printLevelPrefix[GC_DebugUtils.MODDING] = "MODDING: ";
	self.printLevelPrefix[GC_DebugUtils.DEV] = "DEVELOPMENT: ";

	return self;
end;

-- Standard formatted printing for 'unregistered' scripts. This has no 'level' or 'data' requirement.
function GC_DebugUtils:printToLog(prefix, message, ...)
	if prefix ~= nil then
		prefix = string.format("%s:  ", prefix:upper());
	else
		prefix = "WARNING:  ";
	end;
	
	print("  [LSMC - GlobalCompany] - " .. prefix .. string.format(message, ...));
end;

function GC_DebugUtils:getLevelFromName(levelName, printError)
	local level = GC_DebugUtils[levelName:upper()];

	if printError == true and level == nil then
		print("  [LSMC - GlobalCompany > GC_DebugUtils] - 'printLevel' with name '" .. levelName:upper() .. "' does not exist!");
	end;

	return level;
end;

function GC_DebugUtils:setLevel(level, value)
	if value == nil or type(value) ~= "boolean" then
		value = false;
	end;

	if level ~= nil and level > 0 and level < GC_DebugUtils.maxLevels then
		self.printLevel[level] = value;
		return true;
	end;

	return false;
end;

function GC_DebugUtils:setAllLevels(value)
	if value == nil or type(value) ~= "boolean" then
		value = false;
	end;

	local count = 0
	for i = -1, GC_DebugUtils.maxLevels do
		if i > 0 then
			self.printLevel[i] = value;
			count = count + 1;
		end;
	end;

	return count;
end;

function GC_DebugUtils:registerScriptName(scriptName)
	if type(scriptName) ~= "string" then
		print("  [LSMC - GlobalCompany > GC_DebugUtils] - 'registerScriptName' failed! '" .. tostring(scriptName) .. "' is not a string value.");
		return;
	end;

	if self.registeredScriptNames[scriptName] == nil then
		self.registeredScriptsCount = self.registeredScriptsCount + 1;

		self.registeredScripts[self.registeredScriptsCount] = scriptName;
		self.registeredScriptNames[scriptName] = self.registeredScriptsCount;

		return self.registeredScriptsCount;
	else
		print(string.format("  [LSMC - GlobalCompany > GC_DebugUtils] - Script name %s is already registered! Registered Script Id = %d", scriptName, self.registeredScriptNames[scriptName]));
	end;
end;

function GC_DebugUtils:getDebugData(scriptId, target, customEnvironment)
	local parentScriptId, modName = nil, "";

	if target ~= nil then
		parentScriptId = target.debugIndex;

		if customEnvironment ~= nil then
			modName = " - [" .. tostring(customEnvironment) .. "]"; -- Optional to overwrite modName.
		elseif target.debugModName ~= nil then
			modName = " - [" .. tostring(target.debugModName) .. "]"; -- Optional value for any script to store 'loading mod name'.
		elseif target.customEnvironment ~= nil then
			modName = " - [" .. tostring(target.customEnvironment) .. "]"; -- As given by any 'Object' Class script.
		end;
	else
		if customEnvironment ~= nil then
			modName = " - [" .. tostring(customEnvironment) .. "]";  -- Optional to show modName in header if no target is given.
		end;
	end;

	local scriptName = self:getScriptNameFromIndex(scriptId);
	if scriptName ~= "" then
		local parentScriptName = self:getScriptNameFromIndex(parentScriptId);
		if parentScriptName ~= "" then
			scriptName =  parentScriptName .. " > " .. scriptName;
		end;

		local header = "  [LSMC - GlobalCompany] - [" .. scriptName .. "]" .. modName;

		return {scriptId = scriptId,
				header = header,
				modName = modName,
				BLANK = -2,
				ERROR = -1,
				WARNING = 0,
				INFORMATIONS = 1,
				LOAD = 2,
				ONCREATE = 3,
				TABLET = 4,
				MODDING = 5,
				DEV = 6};
	end;

	return nil;
end;

-- Print to log without header.
function GC_DebugUtils:singleLogWrite(data, level, message, ...)
	if self.printLevel[level] == true then
		if data ~= nil then
			local registeredScriptName, header;

			if type(data) == "table" then
				registeredScriptName = self.registeredScripts[data.scriptId];
			else
				registeredScriptName = self.registeredScripts[data];
			end;

			if registeredScriptName ~= nil then
				print("  [LSMC - GlobalCompany] - " .. self.printLevelPrefix[level] .. string.format(message, ...));
			else
				print("  [LSMC - GlobalCompany > GC_DebugUtils] - Illegal mod!");
			end;
		end;
	end;
end;

-- Print to log with header.
function GC_DebugUtils:logWrite(data, level, message, ...)
	if self.printLevel[level] == true then
		if data ~= nil then
			local registeredScriptName, header;

			if type(data) == "table" then
				registeredScriptName = self.registeredScripts[data.scriptId];
				header = data.header;
			else
				registeredScriptName = self.registeredScripts[data];
				header = "  [LSMC - GlobalCompany] - [" .. registeredScriptName .. "]";
			end;

			if registeredScriptName ~= nil then
				if header ~= nil then
					print(header, "    " .. self.printLevelPrefix[level] .. string.format(message, ...));
				else
					print("  [LSMC - GlobalCompany] - " .. self.printLevelPrefix[level] .. string.format(message, ...));
				end;
			else
				print("  [LSMC - GlobalCompany > GC_DebugUtils] - Illegal mod!");
			end;
		end;
	end;
end;

-- Direct print functions (With Header Only).
function GC_DebugUtils:writeBlank(data, message, ...)
	self:logWrite(data, -2, message, ...);
end;

function GC_DebugUtils:writeError(data, message, ...)
	self:logWrite(data, -1, message, ...);
end;

function GC_DebugUtils:writeWarning(data, message, ...)
	self:logWrite(data, 0, message, ...);
end;

function GC_DebugUtils:writeInformations(data, message, ...)
	self:logWrite(data, 1, message, ...);
end;

function GC_DebugUtils:writeLoad(data, message, ...)
	self:logWrite(data, 2, message, ...);
end;

function GC_DebugUtils:writeOnCreate(data, message, ...)
	self:logWrite(data, 3, message, ...);
end;

function GC_DebugUtils:writeTablet(data, message, ...)
	self:logWrite(data, 4, message, ...);
end;

function GC_DebugUtils:writeModding(data, message, ...)
	self:logWrite(data, 5, message, ...);
end;

function GC_DebugUtils:writeDev(data, message, ...)
	self:logWrite(data, 6, message, ...);
end;

function GC_DebugUtils:getScriptNameFromIndex(index)
	local name = "";

	if index ~= nil and self.registeredScripts[index] ~= nil then
		name = self.registeredScripts[index];
	end;

	return name;
end;

function GC_DebugUtils:getScriptIndexFromName(name)
	return self.registeredScriptNames[name];
end;

function GC_DebugUtils:getPrintLevelFromParamater(level) -- another option we could use, call using printLevel name (string).
	if type(level) == "number" then
		return level;
	elseif type(level) == "string" then
		return GC_DebugUtils[level:upper()] or -10; -- printLevel[-10] does not exist so nothing will print.
	end;
end;

function GC_DebugUtils:getIsDev()
	local isDev = false;
	local devNames = {"kevink98", "GtX", "LSMC", "DEV"};
	if g_mpLoadingScreen ~= nil and g_mpLoadingScreen.missionInfo ~= nil then
		if g_mpLoadingScreen.missionInfo.playerStyle ~= nil and g_mpLoadingScreen.missionInfo.playerStyle.playerName ~= nil then
			for i = 1, #devNames do
				if g_mpLoadingScreen.missionInfo.playerStyle.playerName == devNames[i] then
					isDev = true;
					break;
				end;
			end;
		end;
	end;

	return isDev;
end;


------------------------------
--| Debug Console Commands |--
------------------------------
function GC_DebugUtils:loadConsoleCommands()
	if self.consoleCommandsLoaded == true then
		return;
	end;

	if self.isDev then
		-- Load dev only debug commands when added.
	end;

	addConsoleCommand("gcSetDebugLevelState", "Set the state of the given debug level. [level] [state]", "consoleCommandSetDebugLevel", self);
	addConsoleCommand("gcSetAllDebugLevelsState", "Set the state of all debug levels. [state]", "consoleCommandSetAllDebugLevels", self);

	self.consoleCommandsLoaded = true;
end;

function GC_DebugUtils:deleteConsoleCommands()
	if self.isDev then
		-- Load dev only debug commands when added
	end;

	removeConsoleCommand("gcSetDebugLevelState");
	removeConsoleCommand("gcSetAllDebugLevelsState");
end;

function GC_DebugUtils:consoleCommandSetDebugLevel(level, state)
	if level == nil then
		return "'GlobalCompany' Debug printLevel failed to update!  gcSetDebugLevelState [level] [state]";
	end;

	local newLevel;
	if GC_DebugUtils[level:upper()] ~= nil then
		newLevel = GC_DebugUtils[level:upper()];
	else
		newLevel = tonumber(level);
	end;

	local value = Utils.stringToBoolean(state);
	local success = self:setLevel(newLevel, value);

	if success then
		return "'GlobalCompany' Debug printLevel " .. tostring(newLevel) .. " = " .. tostring(value);
	else
		return "'GlobalCompany' Debug printLevel failed to update!";
	end;
end;

function GC_DebugUtils:consoleCommandSetAllDebugLevels(state)
	local value = Utils.stringToBoolean(state);
	local updated = self:setAllLevels(value);

	return "'GlobalCompany' Updated (" .. tostring(updated) .. ") Debug printLevels to '" .. tostring(value) .. "'.";
end;

------------------------------------
-- Print Debug (For Testing Only) --
------------------------------------
function debugPrint(name, text, depth, referenceText)
	local refName = "debugPrint";
	if referenceText ~= nil then
		refName = tostring(referenceText);
	end;

	if name ~= nil then
		if text == nil then
			if type(name) == "table" then
				print("", "(" .. refName .. ")")
				if depth == nil then
					depth = 2;
				end;
				DebugUtil.printTableRecursively(name, ":", 1, depth);
				print("");
			else
				print("    " .. refName .. " = " .. tostring(name));
			end;
		else
			if type(text) == "table" then
				print("", "(" .. refName .. ")")
				if depth == nil then
					depth = 2;
				end;
				DebugUtil.printTableRecursively(text, name .. " ", 1, depth);
				print("");
			else
				print("    (" .. refName .. ") " .. tostring(name) .. " = " .. tostring(text));
			end;
		end;
	else
		print("    " .. refName .. " = " .. tostring(name));
	end;
end;
getfenv(0)["gc_debugPrint"] = debugPrint; -- Maybe to make global?



