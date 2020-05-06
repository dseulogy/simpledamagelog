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
local Config = {
	Apply = {},
	Click = {},
	Dropdown = {},
	VarCache = {
		AddProfile = "",
	},
	Defaults = {
		Enabled = true,
		Locked = false,
		NumLines = 10,

		Backdrop = false,
		BackColor = "|c7f000000",

		FilterActive = false,

		PetInDamage = true,
		PetOutDamage = true,
		PetInHeal = true,
		PetOutHeal = true,

		InVisible = true,
		InLeft = false;
		InDamage = true,
		InHeal = true,
		DamageSource = true,
		HealSource = true,

		OutVisible = true,
		OutLeft = true;
		OutDamage = true,
		OutHeal = true,
		DamageTarget = true,
		HealTarget = true,
	},
	CharDefaults = {
		Profile = "Default",
	},
	CurrProfile = {};
}
SDL.Config = Config
local SDL = SDL
local Lib = ZZLibrary
local Apply = Config.Apply
local Click = Config.Click
local Dropdown = Config.Dropdown
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

--------------------------------------------------------------------------------------
-- LOCAL VARS, CONSTANTS, ... --------------------------------------------------------
--------------------------------------------------------------------------------------
local EVENTS_REGISTERED = false
local PROFILE_DEFAULT = "Default"

function Config.Init()
	SDL_Cfg = SDL_Cfg or {}
	SDL_Cfg.Profiles = SDL_Cfg.Profiles or {}
	SDL_CharCfg = SDL_CharCfg or {}

	if SDL_Cfg.Profiles then
		for Profile in pairs(SDL_Cfg.Profiles) do
			Config.CheckGlobal(Profile)
		end
	end
	Config.CheckGlobal(PROFILE_DEFAULT)
	Config.CheckChar()
	SaveVariables("SDL_Cfg")
	SaveVariablesPerCharacter("SDL_CharCfg")

	Config.SetProfile(SDL_CharCfg.Profile)
	Config.ApplyAll()
end
function Config.CheckGlobal(profile)
	local Profile = profile and SDL_Cfg.Profiles[profile] or Config.CurrProfile
	catch(Profile, "Selected profile does not exist", profile)
	for Key, Value in pairs(Config.Defaults) do
		if Profile[Key] == nil then
			Profile[Key] = Value
		end
	end
end
function Config.CheckChar()
	for Key, Value in pairs(Config.CharDefaults) do
		if SDL_CharCfg[Key] == nil then
			SDL_CharCfg[Key] = Value
		end
	end
end
function Config.ApplyAll()
	for Name, Func in pairs(Apply) do
		Func()
	end
end
function Config.SetProfile(name)
	name = name or PROFILE_DEFAULT
	SDL_Cfg.Profiles[name] = SDL_Cfg.Profiles[name] or {}
	Config.CheckGlobal(name)
	Config.CurrProfile = SDL_Cfg.Profiles[name]
	SDL_CharCfg.Profile = name
	Config.ApplyAll()
	if SDL_Config:IsVisible() then
		SDL_Config:Hide()
		Lib.Timer.Add({0.01}, function() SDL_Config:Show() end, "SDL_RedrawConfig")
	end
end
function Config.SetValue(frameName, newValue)
	local Setting = string.match(frameName, "^.*_(.*)$")
	local SettingSource = string.find(frameName, "^.*__(.*)$") and SDL_CharCfg or Config.CurrProfile
	if SettingSource[Setting] == nil then SettingSource = Config.VarCache end

	local OldType = type(SettingSource[Setting])
	if OldType == "number" then
		newValue = tonumber(newValue) or newValue
	end
	if OldType == "string" then
		newValue = tostring(newValue) or newValue
	end
	local NewType = type(newValue)

	catch(OldType == NewType, "Type mismatch on updating setting: "..Setting)

	SettingSource[Setting] = newValue
	if Apply[Setting] then
		Apply[Setting]()
	end
end
function Config.GetValue(frameName)
	local Setting = string.match(frameName, "^.*_(.*)$")
	local SettingSource = string.find(frameName, "^.*__(.*)$") and SDL_CharCfg or Config.CurrProfile
	if SettingSource[Setting] == nil then SettingSource = Config.VarCache end
	return SettingSource[Setting]
end
function Config.GetLabel(frameName)
	local Setting = string.match(frameName, "^.*_(.*)$")
	return Loc.Get("Config_"..Setting)
end
function Config.ClickButton(frameName)
	local Setting = string.match(frameName, "^.*_(.*)$")
	if Click[Setting] then
		Click[Setting]()
	end
end
function Config.ClickDropdown(frameName)
	local Setting = string.match(frameName, "^.*_(.*)$")
	if Dropdown[Setting] then
		Dropdown[Setting](_G[frameName])
	end
end
function Config.ClickColorPicker(frameName)
	local Setting = string.match(frameName, "^.*_(.*)$")
	local UpdateFN = function()
		local CP = ColorPickerFrame
		Config.SetValue(frameName, Lib.Colors.RGBAToHEX(CP.r, CP.g, CP.b, CP.a))
		_G[frameName.."_Texture"]:SetColor(CP.r, CP.g, CP.b)
		_G[frameName.."_Texture"]:SetAlpha(CP.a)
	end
	local cr, cg, cb, ca = Lib.Colors.HEXToRGBA(Config.GetValue(frameName))
	OpenColorPickerFrameEx({
		parent = SDL_COnfig,
		alphaMode = 1,
		r = cr,
		g = cg,
		b = cb,
		a = ca,
		callbackFuncOkay = UpdateFN,
		callbackFuncUpdate = UpdateFN,
		callbackFuncCancel = UpdateFN,
	})
end

function Apply.Enabled()
	Apply.InVisible()
	Apply.OutVisible()

	if Config.CurrProfile.Enabled and not EVENTS_REGISTERED then
		Lib.Event.Register("COMBATMETER_DAMAGE", SDL.Log.OnDamage, "SDL_OnDamage")
		Lib.Event.Register("COMBATMETER_HEAL", SDL.Log.OnHeal, "SDL_OnHeal")
		EVENTS_REGISTERED = true
	elseif not Config.CurrProfile.Enabled and EVENTS_REGISTERED then
		Lib.Event.Unregister("COMBATMETER_DAMAGE", "SDL_OnDamage")
		Lib.Event.Unregister("COMBATMETER_HEAL", "SDL_OnHeal")
		EVENTS_REGISTERED = false
	end
end
function Apply.Locked()
	Apply.InLeft()
	Apply.OutLeft()

	SDL_In_Texture:ClearAllAnchors()
	SDL_Out_Texture:ClearAllAnchors()
	SDL_In_Texture:SetAnchor("TOPLEFT", "TOPLEFT", SDL_In, 0, 0)
	SDL_Out_Texture:SetAnchor("TOPLEFT", "TOPLEFT", SDL_Out, 0, 0)
	if Config.CurrProfile.Locked then
		SDL_In_Texture:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", SDL_In_HeaderRight, 0, 0)
		SDL_Out_Texture:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", SDL_Out_HeaderRight, 0, 0)
	else
		SDL_In_Texture:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", SDL_In, 0, 0)
		SDL_Out_Texture:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", SDL_Out, 0, 0)
	end
end
function Apply.NumLines()
	SDL_In:SetHeight(15 * (Config.CurrProfile.NumLines + 1))
	SDL_Out:SetHeight(15 * (Config.CurrProfile.NumLines + 1))
end
function Apply.Backdrop()
	if Config.CurrProfile.Backdrop then
		SDL_In_Texture:Show()
		SDL_Out_Texture:Show()
	else
		SDL_In_Texture:Hide()
		SDL_Out_Texture:Hide()
	end
end
function Apply.BackColor()
	local cr, cg, cb, ca = Lib.Colors.HEXToRGBA(Config.CurrProfile.BackColor)
	SDL_In_Texture:SetColor(cr, cg, cb)
	SDL_Out_Texture:SetColor(cr, cg, cb)
	SDL_In_Texture:SetAlpha(ca)
	SDL_Out_Texture:SetAlpha(ca)
end
function Apply.InVisible()
	if Config.CurrProfile.InVisible and Config.CurrProfile.Enabled then
		SDL_In:Show()
	else
		SDL_In:Hide()
	end
end
function Apply.OutVisible()
	if Config.CurrProfile.OutVisible and Config.CurrProfile.Enabled then
		SDL_Out:Show()
	else
		SDL_Out:Hide()
	end
end
function Apply.InLeft()
	if Config.CurrProfile.InLeft then
		SDL_In_LogLeft:Show()
		SDL_In_LogRight:Hide()
		SDL_In_HeaderLeft:Show()
		SDL_In_HeaderRight:Hide()
	else
		SDL_In_LogLeft:Hide()
		SDL_In_LogRight:Show()
		SDL_In_HeaderLeft:Hide()
		SDL_In_HeaderRight:Show()
	end
	if Config.CurrProfile.Locked then
		SDL_In_HeaderLeft:Hide()
		SDL_In_HeaderRight:Hide()
	end
end
function Apply.OutLeft()
	if Config.CurrProfile.OutLeft then
		SDL_Out_LogLeft:Show()
		SDL_Out_LogRight:Hide()
		SDL_Out_HeaderLeft:Show()
		SDL_Out_HeaderRight:Hide()
	else
		SDL_Out_LogLeft:Hide()
		SDL_Out_LogRight:Show()
		SDL_Out_HeaderLeft:Hide()
		SDL_Out_HeaderRight:Show()
	end
	if Config.CurrProfile.Locked then
		SDL_Out_HeaderLeft:Hide()
		SDL_Out_HeaderRight:Hide()
	end
end
function Apply.AddProfile()
	local Value = Config.VarCache.AddProfile
	if Value ~= "" and Value ~= nil then
		Config.VarCache.AddProfile = ""
		Config.SetProfile(Value)
	end
end

function Click.OpenFilterList()

end

function Dropdown.Profile(frame)
	for Name, Settings in pairs(SDL_Cfg.Profiles) do
		UIDropDownMenu_AddButton({
			text = Name,
			func = function(button)
				UIDropDownMenu_SetSelectedName(frame, Name)
				Config.SetValue(frame:GetName(), Name)
				Config.SetProfile(Name)
			end,
		})
	end
end
function Click.DeleteProfile()
	local CurrProfileName = SDL_CharCfg.Profile
	if CurrProfileName == PROFILE_DEFAULT then
		Lib.Print(Loc.Get("CantDeleteProfile"), SDL.Manifest)
	else
		SDL_Cfg.Profiles[CurrProfileName] = nil
		Config.SetProfile(PROFILE_DEFAULT)
	end
end