------------------------------------------------------------
-- SIMPLE DAMAGE LOG ---------------------------------------
-- REWRITTEN BY NOGUAI; ORIGINAL BY AULID ------------------
------------------------------------------------------------
-- RELEASED UNDER CREATIVE COMMONS BY-NC-SA 3.0 ------------
-- http://www.creativecommons.org/licenses/by-nc-sa/3.0/ ---
------------------------------------------------------------
-- DISCLAIMER: ---------------------------------------------
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ---
-- ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT ---------
-- LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS ---
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO -----
-- EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE --
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN ---
-- AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING -------
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE --
-- USE OR OTHER DEALINGS IN THE SOFTWARE. ------------------
------------------------------------------------------------

--------------------------------------------------------------------------------------
-- NAMESPACE DEFINITIONS -------------------------------------------------------------
--------------------------------------------------------------------------------------
local Log = {}
SDL.Log = Log
local SDL = SDL
local Config = SDL.Config
local Lib = ZZLibrary
local Loc = SDL.Locale

--------------------------------------------------------------------------------------
-- PERFORMANCE LOCALS ----------------------------------------------------------------
--------------------------------------------------------------------------------------
local string = string
local math = math
local table = table
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local tonumber = tonumber
local error = error
local assert = assert

local function println(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end
local function print(...)
	for _, msg in ipairs(arg) do
		println(msg)
	end
end
local function printf(format, ...)
	println(string.format(format, ...))
end
local function throw(msg, level, ...)
	for i, v in ipairs(arg) do
		msg = string.format("%s\n%d: %s", msg, i, tostring(v))
	end
	error(msg, level)
end
local function catch(check, msg, ...)
	if not check then
		throw(msg, 3, ...)
	end
end
local function throwSafe(msg, ...)
	for i, v in ipairs(arg) do
		msg = string.format("%s\n%d: %s", msg, i, tostring(v))
	end
	print("|cFFFF0000ERROR: "..msg)
end
local function catchSafe(check, msg, ...)
	if not check then
		throwSafe(msg, ...)
	end
end

--------------------------------------------------------------------------------------
-- LOCAL VARS, CONSTANTS, ... --------------------------------------------------------
--------------------------------------------------------------------------------------
local PLAYER_NAME
local COLORS = {
	Skill = "|cff33ffff",
	DamageSource = "|cffffff4C",
	HealSource = "|cffffff4C",

	Damage = {
		MISS = "|cff7F7F7F",
		DODGE = "|cff7F7F7F",
		ABSORB = "|cff7F7F7F",

		HALF = "|cffff9999",
		NORMAL = "|cffff6666",
		DOUBLE = "|cffff3333",
		CRITIAL = "|cffff1919", -- note the typo
	},

	Heal = {
		HALF = "|cff99ff99",
		NORMAL = "|cff66ff66",
		DOUBLE = "|cff33ff33",
		CRITIAL = "|cff19ff19", -- note the typo
	},
}

-- CombatMeter event uses this global vars: _source, _target, _damage, _heal, _skill, _type

function Log.Init()
	PLAYER_NAME = UnitName("player")
	catch(PLAYER_NAME and PLAYER_NAME ~= "", "SDL: Couldn't read player name")
end

function Log.OnDamage()
	local color = COLORS.Damage[_type] or "|cffffffff"
	local PET_NAME = UnitName("playerpet") or "!no pet"
	local Profile = Config.CurrProfile

	if (Profile.OutDamage and _source == PLAYER_NAME) or (Profile.PetOutDamage and _source == PET_NAME) then
		Log.AddOut(_damage, _skill, false, _type, color, _target)
	elseif (Profile.InDamage and _target == PLAYER_NAME) or (Profile.PetInDamage and _target == PET_NAME) then
		Log.AddIn(_damage, _skill, false, _type, color, _source)
	end
end

function Log.OnHeal()
	local color = COLORS.Heal[_type] or "|cffffffff"
	local PET_NAME = UnitName("playerpet") or "!no pet"
	local Profile = Config.CurrProfile

	if (Profile.OutHeal and _source == PLAYER_NAME) or (Profile.PetOutHeal and _source == PET_NAME) then
		Log.AddOut(_heal, _skill, true, _type, color, _target)
	elseif (Profile.InHeal and _target == PLAYER_NAME) or (Profile.PetInHeal and _target == PET_NAME) then
		Log.AddIn(_heal, _skill, true, _type, color, _source)
	end
end

function Log.GetCombatMsg(hitPoints, skill, isHeal, hitType, hitColor, target, isOut)
	local skillText = (skill ~= "ATTACK") and COLORS.Skill..skill.."|r > " or ""
	local hitPointText = hitColor..Lib.Math.Format(hitPoints, 0, (not Config.CurrProfile.Shorten) and 0).."|r"
	local hitTypeText = hitType ~= "NORMAL" and " > "..hitColor..Loc.Get(hitType).."|r" or ""
	local targetText = ""

	local Profile = Config.CurrProfile
	if target then
		if isOut then
			if isHeal and Profile.HealTarget or not isHeal and Profile.DamageTarget then
				local Color = isHeal and COLORS.HealSource or COLORS.DamageSource
				targetText = " > "..Color..target.."|r"
			end
		else
			if isHeal and Profile.HealSource or not isHeal and Profile.DamageSource then
				local Color = isHeal and COLORS.HealSource or COLORS.DamageSource
				targetText = " > "..Color..target.."|r"
			end
		end
	end

	return skillText..hitPointText..hitTypeText..targetText
end

function Log.AddIn(hitPoints, skill, isHeal, hitType, hitColor, source)
	local msg = Log.GetCombatMsg(hitPoints, skill, isHeal, hitType, hitColor, source, false)
	if Config.CurrProfile.InLeft then
		SDL_In_LogLeft:AddMessage(msg)
	else
		SDL_In_LogRight:AddMessage(msg)
	end
end

function Log.AddOut(hitPoints, skill, isHeal, hitType, hitColor, target)
	local msg = Log.GetCombatMsg(hitPoints, skill, isHeal, hitType, hitColor, target, true)
	if Config.CurrProfile.OutLeft then
		SDL_Out_LogLeft:AddMessage(msg)
	else
		SDL_Out_LogRight:AddMessage(msg)
	end
end

function Log.IsAllowedMsg(skill)
	if Config.CurrProfile.FilterActive then
		local Profile = Config.CurrProfile
	else
		return true
	end
end
