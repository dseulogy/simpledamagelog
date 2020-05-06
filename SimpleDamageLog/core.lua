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
-- PRE LOADING -----------------------------------------------------------------------
--------------------------------------------------------------------------------------
if not ZZLibrary then
	DEFAULT_CHAT_FRAME:AddMessage("|cffff0000WARNING: SimpleDamageLog needs ZZLibrary to run! Loading aborted...")
	return
end


local VERSION = string.match("2.0-b02", "v?[%d+.]+....$") or DEV_VERSION or "Alpha r2013-01-26T14:51:52Z"
local BUILD = tonumber("20130126145152") or DEV_BUILD
local ROOT = "Interface/Addons/SimpleDamageLog"

--------------------------------------------------------------------------------------
-- NAMESPACE DEFINITIONS -------------------------------------------------------------
--------------------------------------------------------------------------------------
SDL = {
	Manifest = {
		Name = "SimpleDamageLog",
		Author = "Noguai, Aulid",
		Source = "http://rom.curseforge.com/addons/simpledamagelog/",
		Root = ROOT,
		Icon = ROOT.."/graphics/icon",
		Licence = "Creative Commons BY-NC-SA 3.0",
		Build = BUILD,
		Version = VERSION,
		Debug = true,
	},
	Locale = {
		Locales = {};
	},
	Core = {},
}
local Lib = ZZLibrary
local SDL = SDL
local Manifest = SDL.Manifest
local Core = SDL.Core
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
local ADDON_LOADED = false
local COMMAND = "/sdl"
g_UIPanelAnchorFrameDefaults.SDL_In = {
	x = -75,
	y = 0,
	point = "BOTTOMRIGHT",
	relativePoint = "CENTER",
	relativeTo = "UIParent",
}
g_UIPanelAnchorFrameDefaults.SDL_Out = {
	x = 75,
	y = 0,
	point = "BOTTOMLEFT",
	relativePoint = "CENTER",
	relativeTo = "UIParent",
}

function Loc.Get(key)
	return Loc.Locales[key] or key
end
function Loc.Load()
	local load, err = loadfile(ROOT.."/locales/"..string.lower(string.sub(GetLanguage(),1,2))..".lua")
	if err then
		load, err = loadfile(ROOT.."/locales/en.lua")
	end
	assert(load, err)
	Loc.Locales = load()
end

function Core.Init()
	if not ADDON_LOADED then
		Lib.Print("Begin loading...", Manifest, true);
		Loc.Load()

		SDL_In_HeaderLeft:SetText(Loc.Get("HeaderIn"))
		SDL_In_HeaderRight:SetText(Loc.Get("HeaderIn"))
		SDL_Out_HeaderLeft:SetText(Loc.Get("HeaderOut"))
		SDL_Out_HeaderRight:SetText(Loc.Get("HeaderOut"))
		SDL.Config.Init()
		SDL.Log.Init()
		Core.RegSlashCommand()
		Core.RegAddonManager()
		Core.RegZZInfoBar()

		ADDON_LOADED = true
		Lib.Print(Loc.Get("InitDone"):gsub("<NAME>", Manifest.Name):gsub("<VERSION>", Manifest.Version), Manifest)
		Lib.Event.Trigger("SDL_INITDONE")
	end
end
function Core.RegAddonManager()
	if AddonManager then
		AddonManager.RegisterAddonTable({
			name = Manifest.Name,
			version = Manifest.Version,
			author = Manifest.Author,
			description = Loc.Get("Description"),
			slashCommand = COMMAND,
			icon = Manifest.Icon,
			category = "Interface",
			configFrame = SDL_Config,
		})
		SDL_MinimapButton:Hide()
	end
end
function Core.RegZZInfoBar()
	if ZZIB then
		ZZIB.Plugins.Add(
			Manifest.Name,
			Manifest.Icon,
			function() ToggleUIFrame(SDL_Config); ZZIB.Dropdown.Frame:Hide() end,
			{
				Loc.Get("Description"),
				"|cffaaaaaaWritten by: "..Manifest.Author.."|r",
			}
		)
		SDL_MinimapButton:Hide()
	end
end
function Core.RegSlashCommand()
	SLASH_SimpleDamageLog1 = COMMAND
	SlashCmdList["SimpleDamageLog"] = function(frame, txt)
		ToggleUIFrame(SDL_Config)
	end
end

Lib.Event.Register("LOADING_END", Core.Init, "SDL_Init")