------------------------------------------------------------
-- ZZLIBRARY -----------------------------------------------
-- WRITTEN BY NOGUAI ---------------------------------------
------------------------------------------------------------
-- RELEASED UNDER CREATIVE COMMONS BY-NC-ND 3.0 ------------
-- http://www.creativecommons.org/licenses/by-nc-nd/3.0/ ---
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
local VERSION = 6


--------------------------------------------------------------------------------------
-- PRE LOADING CHECKS ----------------------------------------------------------------
--------------------------------------------------------------------------------------
if ZZLibrary then
	if ZZLibrary.System.Version >= VERSION then return end
end


--------------------------------------------------------------------------------------
-- NAMESPACE DEFINITIONS -------------------------------------------------------------
--------------------------------------------------------------------------------------
local Lib = {
	System = {
		Name = "ZZLibrary",
		Version = VERSION,
		Debug = false,
	},
	Printer = {
		Name = "print",
		Version = 0,
		Debug = false,
	},
	Table = {},
	Math = {},
	String = {},
	Classes = {},
	Hash = {},
	Colors = {},
	Anim = {
		List = {},
	},
	Story = {
		List = {},
	},
	Event = {
		Output = false,
		List = {},
	},
	Timer = {
		Output = false,
		List = {},
	},
}
ZZLibrary = Lib
ZZLibrary_EventList = ZZLibrary_EventList or {}
ZZLibrary_AnimList = ZZLibrary_AnimList or {}
ZZLibrary_StoryList = ZZLibrary_StoryList or {}
ZZLibrary_TimerList = ZZLibrary_TimerList or {}
local CompiledStrings = {}


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
local loadstring = loadstring
local bit

local Table = Lib.Table
local Math = Lib.Math
local String = Lib.String
local Classes = Lib.Classes
local Colors = Lib.Colors
local Anim = Lib.Anim
local Story = Lib.Story
local Event = Lib.Event
local Timer = Lib.Timer


--------------------------------------------------------------------------------------
-- INTERNAL TOOLS --------------------------------------------------------------------
--------------------------------------------------------------------------------------
local ExecString = RunScript
local function RunScript(script, ...)
	local Type = type(script)
	if Type == "string" then
		if CompiledStrings[script] then
			CompiledStrings[script]()
		else
			local func, err = loadstring(script)
			assert(func, err)
			CompiledStrings[script] = func
			func()
		end
	elseif Type == "function" then
		script(...)
	end
end
local function throw(msg, level, ...)
	for i, v in ipairs(arg) do
		msg = string.format("%s\n%d: %s", msg, i, tostring(v))
	end
	error(msg, level + 1)
end
local function catch(test, msg, ...)
	if not test then throw(msg, 2, ...) end
end
local function println(msg, sender)
	if sender and sender.Name then
		msg = msg or "" -- for string.format
		if sender.Version then
			DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000%s (v. %s):|r %s", sender.Name, sender.Version, msg))
		else
			DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000%s:|r %s", sender.Name, msg))
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end
function print(...)
	for _, msg in ipairs(arg) do
		println(msg)
	end
end
local print = print

function Lib.ReregisterEvents()
	for event in pairs(ZZLibrary_EventList) do
		ZZLibrary_Frame:RegisterEvent(event)
	end
end
local function UpdateAnims(this, elapsedTime)
	for name, anim in pairs(ZZLibrary_AnimList) do
		if anim.Curr == anim.Total then
			Lib.Anim.Remove(name)
		else
			anim.Next = anim.Next - elapsedTime
			if anim.Next <= 0 then
				local Increase = 1 + math.floor(-anim.Next/anim.Delay)
				anim.Curr = anim.Curr + Increase
				anim.Next = anim.Next + (Increase * anim.Delay)

				anim.Curr = (anim.Curr > 0) and anim.Curr or 1
				anim.Curr = (anim.Curr < #anim.Frames) and anim.Curr or #anim.Frames

				if anim.Frames[anim.Curr].Width then
					anim.Object:SetWidth(anim.Frames[anim.Curr].Width)
				end
				if anim.Frames[anim.Curr].Height then
					anim.Object:SetHeight(anim.Frames[anim.Curr].Height)
				end
				if anim.Frames[anim.Curr].Scale then
					anim.Object:SetScale(anim.Frames[anim.Curr].Scale)
				end
				if anim.Frames[anim.Curr].Alpha then
					anim.Object:SetAlpha(anim.Frames[anim.Curr].Alpha)
				end
				if anim.Frames[anim.Curr].Pos then
					anim.Object:SetPos(anim.Frames[anim.Curr].Pos[1], anim.Frames[anim.Curr].Pos[2])
				end

				if anim.StartScript then
					-- Move Script into local variable; If script fails, it won't be executed again
					local script = anim.StartScript
					anim.StartScript = nil
					-- Finally execute script
					RunScript(script, name)
				end
			end
		end
	end
end
local function UpdateStory(this, elapsedTime)
	for Name, Animation in pairs(ZZLibrary_StoryList) do
		local NumFrames = #Animation.Frames
		local CurrFrame = Animation.Curr
		local Frames = Animation.Frames
		local Delay = Animation.Delay
		local Next = Animation.Next

		if CurrFrame == NumFrames then
			Story.Remove(Name)
		else
			Next = Next - elapsedTime
			if Next <= 0 then
				local Increase = 1 + math.floor(-Next / Delay)
				local NextForcedFrame = Animation.ForceFrames[1]
				CurrFrame = CurrFrame + Increase
				CurrFrame = (CurrFrame > 0) and CurrFrame or 1
				CurrFrame = (CurrFrame < NumFrames) and CurrFrame or NumFrames
				CurrFrame = (CurrFrame < (NextForcedFrame or math.huge)) and CurrFrame or NextForcedFrame
				if CurrFrame == NextForcedFrame then
					table.remove(Animation.ForceFrames, 1)
				end

				Animation.Curr = CurrFrame

				Next = Next + (Increase * Animation.Delay)
				Story.ApplyFrame(Frames, CurrFrame, Name)
			end
			Animation.Next = Next
		end
	end
end
local function UpdateTimers(this, elapsedTime)
	for key, timer in pairs(ZZLibrary_TimerList) do
		timer.Time = timer.Time - elapsedTime

		if timer.Time <= 0 then
			--dbg(string.format("tick timer: |cff00ff00%s|r", tostring(key)), Lib.Timer.Output)
			if not timer.Delay or timer.Delay <= 0 then
				Lib.Timer.Remove(key)
			else
				timer.Time = timer.Time + timer.Delay
				timer.NumFired = timer.NumFired + 1
			end

			RunScript(timer.Script, timer)
		end
	end
end
local function TriggerEvents(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	--dbg(string.format("receive: |cffff0000%s|r", tostring(event)), Lib.Event.Output)
	for key, script in pairs(ZZLibrary_EventList[event]) do
		--dbg(string.format(" > |cff00ff00%s|r > |cff00ffff%s|r", key, tostring(script)), Lib.Event.Output)
		RunScript(script, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	end
end
function Lib.OnUpdate(frame, elapsedTime)
	UpdateAnims(frame, elapsedTime)
	UpdateStory(frame, elapsedTime)
	UpdateTimers(frame, elapsedTime)
end
function Lib.OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	TriggerEvents(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end
local function CheckOnUpdateNeeded()
	if Lib.Table.IsEmpty(ZZLibrary_AnimList) and Lib.Table.IsEmpty(ZZLibrary_TimerList) and Lib.Table.IsEmpty(ZZLibrary_StoryList) then
		ZZLibrary_Frame:Hide()
	else
		ZZLibrary_Frame:Show()
	end
end
local function CheckEventRegister(event)
	if not ZZLibrary_EventList[event] then
		ZZLibrary_EventList[event] = {}
		ZZLibrary_Frame:RegisterEvent(event)
	end
end
local function CheckEventUnRegister(event)
	if Lib.Table.IsEmpty(ZZLibrary_EventList[event]) then
		ZZLibrary_EventList[event] = nil
		ZZLibrary_Frame:UnregisterEvent(event)
	end
end

local GameTooltipShowAnim = {
	{
		_Frame = GameTooltip,
		_Start = function() GameTooltip:Show() end,
		_Time = 0.125,
		SetScale = {
			From = {0.8},
			To = {1},
		},
		SetAlpha = {
			From = {0.1},
			To = {1},
		},
	},
}
local GameTooltipHideAnim = {
	{
		_Frame = GameTooltip,
		_End = function()
			local GameTooltip = GameTooltip
			GameTooltip:Hide()
			GameTooltip:SetScale(1)
			GameTooltip:SetAlpha(1)
		end,
		_Time = 0.1,
		SetAlpha = {
			From = {1},
			To = {0},
		},
	},
}

local SIPrefixes = {
	[-8] = " y",
	[-7] = " z",
	[-6] = " a",
	[-5] = " f",
	[-4] = " p",
	[-3] = " n",
	[-2] = " µ",
	[-1] = " m",
	[0]  = "",
	[1]  = " k",
	[2]  = " M",
	[3]  = " G",
	[4]  = " T",
	[5]  = " P",
	[6]  = " E",
	[7]  = " Z",
	[8]  = " Y",
}

--------------------------------------------------------------------------------------
-- GENERAL STUFF ---------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Prints a preformatted message to the chat frame.
-- @param msg (string) The message that is printed
-- @param sender (table) Table with information about the sender (see <a href="#PrintSender">PrintSender</a>)
-- @param debug (bool) A switch to print only when sender has Debug-flag set
-- @param force (bool) A switch to force print a message
--
function Lib.Print(msg, sender, debug, force)
	if not (msg and sender) then return end
	if debug and sender.Debug or force == true then
		local l, r = string.match(GetTime(), "(%d*)(.%d%d%d)")
		l = string.rep("0", 6-string.len(tostring(l)))..tostring(l)
		println("|cFFFFFFFF[t: "..l..tostring(r).."] "..tostring(msg), sender)
	elseif not debug and force == nil then
		println(msg, sender)
	end
end
local function dbg(msg, forceswitch)
	Lib.Print(msg, Lib.System, true, forceswitch)
end
local function mdbg(forceswitch, ...)
	for _, msg in ipairs(arg) do
		Lib.Print(msg, Lib.System, true, forceswitch)
	end
end
--- Prints the contents of a table to the chat frame.
-- @param table (table) The table that gets printed
-- @param layer (number) Internal, used for subvalue depth
-- @param message (string) A message to be printed before the table
--
function Lib.PrintTable(table, layer, message)
	if not table then throw("Cannot print table without table", 2, table, layer, message) end
	layer = layer or 1
	print(message)
	if layer == 1 then
		print("|cffffff00tbl = {")
	end
	for k, v in pairs(table) do
		if type(v) == "table" then
			print(string.format("%s|cffffff00%s = {", string.rep("  ", layer), k))
			Lib.PrintTable(nil, v, layer + 1)
		else
			print(string.format("%s|cff00ff00%s|cffffffff = |cff00ffff%s", string.rep("  ", layer), k, tostring(v)))
		end
	end
	print(string.format("%s|cffffff00}", string.rep("  ", layer-1)))
end
--- Checks whether a table is a valid frame.
-- @param table The table to check
-- @return isValid (bool)
function Lib.IsValidFrame(table)
	if type(table) == "table" and table["_uilua.lightuserdate"] then
		return true
	end
	return false
end
--- Displays a GameTooltip with the given template.
-- @param frame (frame) The owner frame of the tooltip
-- @param title (string) The title of the tooltip
-- @param content (array) The contents of the tooltip. See <a href="#TooltipContents">TooltipContents</a>
-- @param anchor (string, optional) The position of the tooltip around the owner.
-- @param hide (bool, optional) Whether the tooltip is initially hidden
--
function Lib.Tooltip(frame, title, content, anchor, hide)
	local GameTooltip = GameTooltip
	GameTooltip:ClearLines()

	local IsSame = GameTooltip:IsVisible() and GameTooltipTextLeft1:GetText() == title
	GameTooltip:SetText(title)
	if not IsSame then
		GameTooltip:Hide()
	end

	if content then
		GameTooltip:AddSeparator()
		for i = 1, #content do
			if content[i] == true then
				GameTooltip:AddSeparator()
			elseif type(content[i]) == "table" then
				GameTooltip:AddDoubleLine(content[i][1] or "-", content[i][2], 1.00, 0.82, 0, 1, 1, 1)
			elseif type(content[i]) == "string" then
				GameTooltip:AddDoubleLine(content[i], "", 1.00, 0.82, 0, 1, 1, 1)
			end
		end
	end

	if anchor then
		GameTooltip:SetOwner(frame, anchor)
	else
		local a1, a2 = "TOP", "LEFT"
		GameTooltip:SetOwner(frame, "ANCHOR_"..a1..a2)
		local x, y = GameTooltip:GetPos()
		a1 = (y < 0) and "BOTTOM" or "TOP"
		a2 = (x < 0) and "RIGHT" or "LEFT"
		GameTooltip:SetOwner(frame, "ANCHOR_"..a1..a2)
	end

	if not IsSame then
		--Lib.Anim.New("ZZLib_Tooltip", GameTooltip, GameTooltipShowAnim, 60, GameTooltipShowFinished)
		Lib.Story.Remove("ZZLib_Tooltip")
		Lib.Story.New("ZZLib_Tooltip", {
			{
				_Frame = GameTooltip,
				_Start = function() GameTooltip:Show() end,
				_Time = 0.125,
				SetScale = {
					From = {0.8},
					To = {1},
				},
				SetAlpha = {
					From = {0.1},
					To = {1},
				},
			},
		}, 36)
	end
end
--- (depracted) Hides the GameTooltip (used to be animated).
--
function Lib.TooltipHide()
	Lib.Story.Remove("ZZLib_Tooltip")
	GameTooltip:Hide()
end
--- Hides the GameTooltip animated.
--
function Lib.TooltipAnimHide()
	local GameTooltip = GameTooltip
	if GameTooltip:IsVisible() then
		Lib.Story.Remove("ZZLib_Tooltip")
		Lib.Story.New("ZZLib_Tooltip", {
			{
				_Frame = GameTooltip,
				_End = function()
					local GameTooltip = GameTooltip
					GameTooltip:Hide()
					GameTooltip:SetScale(1)
					GameTooltip:SetAlpha(1)
				end,
				_Time = 0.1,
				SetAlpha = {
					From = {1},
					To = {0},
				},
			},
		}, 36)
	end
end
--- Used to import the library into a variable.
-- @return (table) The library
--
function Lib.Import()
	return Lib
end


--------------------------------------------------------------------------------------
-- TABLE LIBRARY ---------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Checks whether a table is empty.
-- @param tbl (table) The table to check
-- @return (bool) isEmpty
function Lib.Table.IsEmpty(tbl)
	for _, _ in pairs(tbl) do return false end
	return true
end
--- Turns a table into an array without blank fields. (Deletes alphanumeric indecies)
-- @param self
--
function Lib.Table.Shrink(self)
	local tbl = self
	self = {}
	for k, v in pairs(tbl) do
		if type(k) == "number" then
			table.insert(self, v)
		end
	end
end
--- Checks whether a table contains a value.
-- @param tbl (table) The table that is checked
-- @param value (var) The value to search for
-- @return (bool) containsValue
function Lib.Table.ContainsValue(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return false
end
--- Searches for a value and deletes it.
-- @param self (table) The table to search in
-- @param value The value that gets searched for
--
function Lib.Table.RemoveByValue(self, value)
	for i, v in pairs(self) do
		if v == value then
			table.remove(self, i)
			return self
		end
	end
end
--- Gets a subvalue of a table.
-- @param valuePath (string) A "path" to the value. (e.g "Layer1.ChildLayer.Value")
-- @param tblSource (table, optional) The table to search in (default: _G)
--
function Lib.Table.GetSubValue(valuePath, tblSource)
	local SourceType = type(tblSource)
	assert(type(valuePath) == "string" and (SourceType == "table" or SourceType == "nil"), "Cannot get table Value with invalid parameters!")
	local Value = tblSource or _G
	for SubValue in string.gmatch(valuePath, "%w+") do
		Value = Value[SubValue]
	end
	return Value
end
--- Moves a value from the global environment.
-- @param self (var) The variable the value gets stored in
-- @param global (var/string) The variable to move
--
function Lib.Table.Move(self, global)
	if type(global) == "string" then
		self = _G[global]
		_G[global] = nil
	else
		self = global
		global = nil
	end
end
--- Merges two tables into the first one.
-- @param self (table) The first table to merge in.
-- @param table2 (table) The other table.
--
function Lib.Table.Merge(self, table2)
	for k, v in pairs(table2) do
		if type(v) == "table" then
			if type(self[k] or false) == "table" then
					Lib.Table.Merge(self[k] or {}, table2[k] or {})
			else
					self[k] = v
			end
		else
			self[k] = v
		end
	end
	return self
end
--- Returns the greatest numeric index in a table. Supports nil values inbetween.
-- @param tbl (table) The table to search in
-- @return (number) The greatest index found
function Lib.Table.GreatestKey(tbl)
	max = 0
	for k, _ in pairs(tbl) do
		local key = tonumber(k)
		max = (key > max) and key or max
	end
	return max
end
--- Appends a variable amount of arrays into a new one.
-- @param ... (table) Arrays to append
-- @return (table) An array containing each value of the input arrays
function Lib.Table.AppendMultiple(...)
	-- http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
	local t = {}

	for i = 1, arg.n do
		local array = arg[i]
		if (type(array) == "table") then
			for j = 1, #array do
				t[#t+1] = array[j]
			end
		else
			t[#t+1] = array
		end
	end

	return t
end
--- Appends a array to the first one.
-- @param self (table) The array to append to
-- @param array2 (table) The array to append
--
function Lib.Table.Append(self, array2)
	for i = 1, #array2 do
		self[#self + 1] = array2[i]
	end
	return self
end

--------------------------------------------------------------------------------------
-- MATH LIBRARY ----------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Formats a number 'n' to have thousand seperators.
-- @author RichardWarburton (edit by Noguai)
-- @param n (number, string) The number to format
-- @return (string) A string with the formatted number
function Lib.Math.Clean(n)
	local left,digits,decimals,right = string.match(tostring(n),"^([^%d]*%d)(%d*)%.?(%d*)(.-)$")
	digits = digits and digits:reverse():gsub("(%d%d%d)","%1."):reverse() or ""
	decimals = (decimals or "") ~= "" and ","..(decimals:gsub("(%d%d%d)", "%1."):gsub("(.*)%.$", "%1")) or ""
	return (left or "")..digits..decimals..(right or "")
end
--- Provides extended formatting capabilities for raw numbers.
-- @param num (number) The number to be formatted
-- @param dec (number, optional) The number of decimals to round to (Default: 2)
-- @param rank (number, optional) A exponent from <a href="#SIPrefixes">SIPrefixes</a> (Use 0 to disable automatic rank calculation)
-- @param base (number, optional) A base to apply the exponent on. (Default: 1000)
-- @return (string) The formatted number
--
function Lib.Math.Format(num, dec, rank, base)
	assert(type(num) == "number")

	base = base or 1000
	rank = rank or math.floor(Lib.Math.Log(num, base))
	rank = (rank > #SIPrefixes) and #SIPrefixes or (rank < -8) and -8 or rank
	num = Lib.Math.Round(num / math.pow(base, rank), dec or 2)

	local Digits, Decimals = string.match(tostring(num),"^(%d*)%.?(%d*)$")
	Digits = Digits and Digits:reverse():gsub("(%d%d%d)","%1."):reverse():gsub("^%.(.*)", "%1") or ""
	Decimals = (Decimals and Decimals ~= "") and ","..(Decimals:gsub("(%d%d%d)", "%1."):gsub("(.*)%.$", "%1")) or ""

	return Digits..Decimals..SIPrefixes[rank]
end
--- Calculates the logarithm for a custom base
-- @param n (number) The number
-- @param b (number) The base
--
function Lib.Math.Log(n, b)
	return math.log(n) / math.log(b)
end
--- Rounds a number to a defined number of decimals.
-- @param num (number) The number to round
-- @param dec (number) The number of decimals to round to
--
function Lib.Math.Round(num, dec)
	return tonumber(string.format("%."..dec.."f",tonumber(num) or 0))
end
--- Abbreviates a number to a short form (e.g 12,5 k).
-- @param num (number/string) The number to short.
-- @param active (bool, optional) A switch to activate shortening (default: true)
-- @return (string) A shortened, cleaned form of the number
--
function Lib.Math.Shorten(num, active)
	num = tonumber(num) or 0
	if active == nil then active = true end

	if active then
		if math.abs(num) >= 1000000 then
			num = Lib.Math.Clean(Lib.Math.Round(num / 1000000, 2)).." M"
		elseif math.abs(num) >= 1000 then
			num = Lib.Math.Clean(Lib.Math.Round(num / 1000, 2)).." k"
		end
	else
		num = Lib.Math.Clean(num)
	end
	return tostring(num)
end
--- Conerts a decimal number into its hexadecimal representation.
-- @param int (number) The decimal to convert
-- @param digits (number) The mininum amount of digits to print
-- @return (string) The hexadecimal representation of int
--
function Lib.Math.ToHex(int, digits)
	return string.format("%0"..digits.."x", int)
end
--- Converts a hexadecimal number into its decimal representation.
-- @param hex (string) The hexadecimal to convert
-- @return (number) The resulting decimal
--
function Lib.Math.ToDec(hex)
	return tonumber(hex, 16)
end


--------------------------------------------------------------------------------------
-- STRING LIBRARY --------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Splits a string with delimiter and returns an array with the parts.
-- @param str (string) The string to split.
-- @param delim (string) The delimiter at which the string is split
-- @return (table) An array of the delimited parts
--
function Lib.String.Split(str, delim)
	local parts = {}
	for part in string.gmatch(str, "[^"..delim.."]+") do
		table.insert(parts, part)
	end
	return parts
end
--- Removes leading and trailing space characters (if 'chars' = nil), or the given ones from a string.
-- @param str (string) The string to trim
-- @param chars (string) A set of characters (and special chars) that shall be trimmed
-- @return (string) The trimmed string
function Lib.String.Trim(str, chars)
	chars = chars or "%s"
	return string.match(str, "["..chars.."]*(.*)["..chars.."]*")
end
--- Checks whether a string starts with another one.
-- @param str (string) The string to test
-- @param test (string) The comparison string to test with
--
function Lib.String.StartsWith(str, test)
	return test == "" or string.sub(str, 1, string.len(test or "")) == test
end
--- Checks whether a string ends with another one.
-- @param str (string) The string to test
-- @param test (string) The comparison string to test with
--
function Lib.String.EndsWith(str, test)
	return test == "" or string.sub(str, -string.len(test or "")) == test
end
--- Returns the index of the last occurance of 'test' in a string.
-- @param str (string) The string to search in
-- @param test (string) The string to search for
function Lib.String.Lastindex(str, test)
	if not test or test == "" then return end
	local i = string.find(string.reverse(str), string.reverse(test))
	if i then
		return string.len(str) - i - string.len(test) + 2
	end
end
--- Wraps a string after 'width' characters.
-- Inserts new line characters after width characters.
-- @param text (string) The string to wrap
-- @param width (number) The the maximum number of chars in a line
-- @return The wrapped string
--
function Lib.String.Wrap(text, width)
	local wrapped, lines = "", 0
	for line in string.gmatch(text, string.rep(".", width).."[.]*") do
		lines = lines + 1
		wrapped = wrapped..line.."\n"
	end
	return wrapped..string.sub(text, lines*width+1)
end
--- Does the string matching with additional matching of RoM localization markers.
-- @param str (string) The string to search for matches in
-- @param format (string) A format string
-- @param replaceLoca (bool) Switch activating the matching of RoM loca markers
-- @return (strings) A variable amount of strings, which are the results of matching
--
function Lib.String.MatchFormat(str, format, replaceLoca)
	if replaceLoca then
		format = format:gsub("%b<>", "%%s")
		format = format:gsub("%b[]", "%%s")
	end
	format = format:gsub("%%.", "(.*)")
	return string.match(str, format)
end
--- Fills the leading spaces of a string until it reaches a given length.
-- @param str (string) The string to fill in
-- @param fill (character) The character to fill in
-- @param len (number) The width to fill to
-- @return (string) A string of given length with leading spaces filled
--
function Lib.String.FillLeading(str, fill, len)
	if not (str and fill and len) then return end
	return string.rep(fill, len-string.len(str))..str
end


--------------------------------------------------------------------------------------
-- CLASSES LIBRARY -------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Converts a class token to it's hexadecimal color.
-- @param class (string) Class token to convert
-- @return (string) Hexadecimal representaion of the class color
--
function Lib.Classes.ToColor(class)
	for i = -1, GetClassCount() do
		local name, token = GetClassInfoByID(i)
		if class == name and g_ClassColors[token] then
			return Lib.Colors.RGBAToHEX(g_ClassColors[token].r, g_ClassColors[token].g, g_ClassColors[token].b)
		end
	end
	return "|cffffffff"
end
--- Converts a class token to it's icon.
-- @param class (string) A class token to convert to
-- @return (string) The path to the class token
--
function Lib.Classes.ToIcon(class)
	for i = -1, GetClassCount() do
		local name, token = GetClassInfoByID(i)
		if class == name then
			return "Interface/TargetFrame/TargetFrameIcon-"..token..".tga"
		end
	end
	return ""
end


--------------------------------------------------------------------------------------
-- HASH LIBRARY ----------------------------------------------------------------------
--------------------------------------------------------------------------------------

local consts = { 0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7, 0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59, 0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433, 0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65, 0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9, 0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F, 0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1, 0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B, 0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D, 0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777, 0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45, 0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9, 0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D }
--- Calculates the CRC32 hash sum of a given string.
-- @author Allara (http://forums.curseforge.com/showpost.php?p=252484&postcount=8)
-- @param s (string) The string to calculate the hash from
-- @return (number) The hash sum
function Lib.Hash.CRC32(s)
	local crc, l, i = 0xFFFFFFFF, string.len(s)
	for i = 1, l, 1 do
		crc = bit.bxor(bit.rshift(crc, 8), consts[bit.band(bit.bxor(crc, string.byte(s, i)), 0xFF) + 1])
	end
	return bit.bxor(crc, -1)
end


--------------------------------------------------------------------------------------
-- COLORS LIBRARY --------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Converts the RGB (with optional Alpha) color into it's hexadecimal representation.
-- @param r (number) Red channel (0 - 1)
-- @param g (number) Green channel (0 - 1)
-- @param b (number) Blue channel (0 - 1)
-- @param a (number, optional) Alpha channel (0 - 1)
-- @return (string) The hexadecimal representation of the color
--
function Lib.Colors.RGBAToHEX(r, g, b, a)
	a = a or 1
	return string.format("|c%02x%02x%02x%02x", a*255, r*255, g*255, b*255)
end
--- Converts the HEX ([AA]RRGGBB) color into it's RGB representation.
-- @param str (string) The HEX color
-- @return (number) Red channel (0 - 1)
-- @return (number) Green channel (0 - 1)
-- @return (number) Blue channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.HEXToRGBA(str)
	local cols = {}
	for col in string.gmatch(string.gsub(str, "|c", ""), "..") do
		table.insert(cols, tonumber(col, 16) / 255)
	end

	if #cols == 3 then
		return cols[1], cols[2], cols[3], 1
	else
		return cols[2], cols[3], cols[4], cols[1]
	end
end
--- Converts a color in HSV format to RGB.
-- @param h (number) Hue channel (0 - 1)
-- @param s (number) Saturation channel (0 - 1)
-- @param v (number) Value channel (0 - 1)
-- @param a (number, optional) Alpha channel (0 - 1)
-- @return (number) Red channel (0 - 1)
-- @return (number) Green channel (0 - 1)
-- @return (number) Blue channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.HSVToRGB(h, s, v, a)
	local r, g, b

	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	local switch = i % 6
	if switch == 0 then
		r = v g = t b = p
	elseif switch == 1 then
		r = q g = v b = p
	elseif switch == 2 then
		r = p g = v b = t
	elseif switch == 3 then
		r = p g = q b = v
	elseif switch == 4 then
		r = t g = p b = v
	elseif switch == 5 then
		r = v g = p b = q
	end

	return r, g, b, a
end
--- Converts a color in HSL format to RGB.
-- @param h (number) Hue channel (0 - 1)
-- @param s (number) Saturation channel (0 - 1)
-- @param l (number) Luminance channel (0 - 1)
-- @param a (number, optional) Alpha channel (0 - 1)
-- @return (number) Red channel (0 - 1)
-- @return (number) Green channel (0 - 1)
-- @return (number) Blue channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.HSLToRGB(h, s, l, a)
	local r, g, b

	local c = (1 - math.abs(2 * l - 1)) * s
	h = (h * 360) / 60
	local x = c * (1 - math.abs(h % 2 - 1))
	local m = l - (0.5 * c)

	if 0 <= h and h <= 1 then
		r = c g = x b = 0
	elseif 1 <= h and h <= 2 then
		r = x g = c b = 0
	elseif 2 <= h and h <= 3 then
		r = 0 g = c b = x
	elseif 3 <= h and h <= 4 then
		r = 0 g = x b = c
	elseif 4 <= h and h <= 5 then
		r = x g = 0 b = c
	elseif 5 <= h and h <= 6 then
		r = c g = 0 b = x
	end

	return r + m, g + m, b + m, a
end
--- Converts a color in RGB format to HSV.
-- @param r (number) Red channel (0 - 1)
-- @param g (number) Green channel (0 - 1)
-- @param b (number) Blue channel (0 - 1)
-- @param a (number, optional) Alpha channel (0 - 1)
-- @return (number) Hue channel (0 - 1)
-- @return (number) Saturation channel (0 - 1)
-- @return (number) Value channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.RGBToHSV(r, g, b, a)
	local h, s, v
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)

	if r == g == b then
		h = 0
	elseif r == max then
		h = 60 * (0 + ((g - b) / (max - min)))
	elseif g == max then
		h = 60 * (2 + ((b - r) / (max - min)))
	elseif b == max then
		h = 60 * (4 + ((r - g) / (max - min)))
	end

	if h < 0 then
		h = h + 360
	end

	if max == 0 then
		s = 0
	else
		s = (max - min) / max
	end
	v = max

	return h / 360, s, v, a
end
--- Converts a color in RGB format to HSL.
-- @param r (number) Red channel (0 - 1)
-- @param g (number) Green channel (0 - 1)
-- @param b (number) Blue channel (0 - 1)
-- @param a (number, optional) Alpha channel (0 - 1)
-- @return (number) Hue channel (0 - 1)
-- @return (number) Saturation channel (0 - 1)
-- @return (number) Luminance channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.RGBToHSL(r, g, b, a)
	local h, s, l
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)

	if r == g == b then
		h = 0
	elseif r == max then
		h = 60 * (0 + ((g - b) / (max - min)))
	elseif g == max then
		h = 60 * (2 + ((b - r) / (max - min)))
	elseif b == max then
		h = 60 * (4 + ((r - g) / (max - min)))
	end

	if h < 0 then
		h = h + 360
	end

	if max == 0 then
		s = 0
	else
		s = (max - min) / (1 - math.abs(max + min - 1))
	end
	l = (max + min) / 2

	return h / 360, s, l, a
end
--- Calculates the color from a gradient with a value.
-- @param val (number) The value to pick from the gradient
-- @param gradient (table) An array of gradient stops (RGBA); See: <a href="#RGBAGradientStop">RGBAGradientStop</a>
-- @return (number) Red channel (0 - 1)
-- @return (number) Green channel (0 - 1)
-- @return (number) Blue channel (0 - 1)
-- @return (number) Alpha channel (0 - 1)
--
function Lib.Colors.RGBAGradient(val, gradient)
	if not val or not gradient then return 1, 1, 1, 1 end
	table.sort(gradient, function(a,b) return a[1] < b[1] end)
	if val <= gradient[1][1] then return gradient[1][2], gradient[1][3], gradient[1][4], gradient[1][5] end
	if val >= gradient[#gradient][1] then return gradient[#gradient][2], gradient[#gradient][3], gradient[#gradient][4], gradient[#gradient][5] end

	for i = 1, #gradient-1 do
		if val >= gradient[i][1] and val <= gradient[i+1][1] then
			local temp = {}
			for j = 1, 5 do
				temp[j] = gradient[i+1][j] - gradient[i][j]
			end

			local pct = (val - gradient[i][1]) / temp[1]
			for j = 2, 5 do
				temp[j] = gradient[i][j] + (temp[j] * pct)
			end
			return temp[2], temp[3], temp[4], temp[5]
		end
	end
end
--- Calculates the color from a gradient with a value.
-- @param val (number) The value to pick from the gradient
-- @param gradient (table) An array of gradient stops (HEX); See: <a href="#HEXGradientStop">HEXGradientStop</a>
-- @return (string) HEX color (AARRGGBB)
--
function Lib.Colors.HEXGradient(val, gradient)
	if not val or not gradient then return "|cffffffff" end
	table.sort(gradient, function(a,b) return a[1] < b[1] end)
	if val <= gradient[1][1] then return gradient[1][2] end
	if val >= gradient[#gradient][1] then return gradient[#gradient][2] end

	for i = 1, #gradient-1 do
		if val >= gradient[i][1] and val <= gradient[i+1][1] then
			temp = {}
			temp[1], temp[2], temp[3], temp[4] = Lib.Colors.HEXToRGBA(gradient[i+1][2])
			temp[5], temp[6], temp[7], temp[8] = Lib.Colors.HEXToRGBA(gradient[i][2])
			local pct = (val - gradient[i][1]) / (gradient[i+1][1] - gradient[i][1])

			for j = 1, 4 do
				temp[j] = temp[j+4] + ((temp[j] - temp[j+4]) * pct)
			end
			return Lib.Colors.RGBAToHEX(temp[1], temp[2], temp[3], temp[4])
		end
	end
end


--------------------------------------------------------------------------------------
-- ANIMATION LIBRARY------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Registers a new animation to be played
-- @param name (string) An animation identifer
-- @param object (frame) The frame the animation gets applied on
-- @param anim (table) An array consisting of animation keyframes; See: <a href="#">AnimationStoryboard</a>
-- @param fps (number) The fps to render the animation at
-- @param startscript (string/function) A script to be executed on animation start
-- @param endscript (string/funcion) A script to be executed on animation end
--
function Lib.Anim.New(name, object, anim, fps, startscript, endscript)
	if not (name and object and anim) then return end

	fps = fps or 30
	if type(object) == "string" then
		object = Lib.Table.GetSubValue(object)
	end

	local frames = {}
	local frame, width, height, scale, alpha, posx, posy
	for i = 1, #anim do
		if not anim[i].Duration then return end
		if anim[i].Width then
			anim[i].Width[2] = anim[i].Width[2] or object:GetWidth()
			width = anim[i].Width[1] - anim[i].Width[2]
			width = width / (anim[i].Duration * fps)
		end
		if anim[i].Height then
			anim[i].Height[2] = anim[i].Height[2] or object:GetHeight()
			height = anim[i].Height[1] - anim[i].Height[2]
			height = height / (anim[i].Duration * fps)
		end
		if anim[i].Scale then
			anim[i].Scale[2] = anim[i].Scale[2] or object:GetScale()
			scale = anim[i].Scale[1] - anim[i].Scale[2]
			scale = scale / (anim[i].Duration * fps)
		end
		if anim[i].Alpha then
			anim[i].Alpha[2] = anim[i].Alpha[2] or object:GetAlpha()
			alpha = anim[i].Alpha[1] - anim[i].Alpha[2]
			alpha = alpha / (anim[i].Duration * fps)
		end
		if anim[i].Pos then
			local x, y = object:GetPos()
			anim[i].Pos[2][1] = anim[i].Pos[2][1] or x
			anim[i].Pos[2][2] = anim[i].Pos[2][2] or y
			posx = anim[i].Pos[1][1] - anim[i].Pos[2][1]
			posy = anim[i].Pos[1][2] - anim[i].Pos[2][2]
			posx = posx / (anim[i].Duration * fps)
			posy = posy / (anim[i].Duration * fps)
		end
		for j = 1, anim[i].Duration * fps do
			frame = {}
			if width then
				frame.Width = anim[i].Width[2] + j * width
			end
			if height then
				frame.Height = anim[i].Height[2] + j * height
			end
			if scale then
				frame.Scale = anim[i].Scale[2] + j * scale
			end
			if alpha then
				frame.Alpha = anim[i].Alpha[2] + j * alpha
			end
			if posx and posy then
				frame.Pos = {anim[i].Pos[2][1] + j * posx, anim[i].Pos[2][2] + j * posy}
			end
			table.insert(frames, frame)
		end
		frame = {}
		if width then
			frame.Width = anim[i].Width[1]
		end
		if height then
			frame.Height = anim[i].Height[1]
		end
		if scale then
			frame.Scale = anim[i].Scale[1]
		end
		if alpha then
			frame.Alpha = anim[i].Alpha[1]
		end
		if posx and posy then
			frame.Pos = {anim[i].Pos[1][1], anim[i].Pos[1][2]}
		end
		table.insert(frames, frame)
	end
	ZZLibrary_AnimList[name] = {
		Next = 0,
		Delay = 1/fps,
		Object = object,
		Curr = 0,
		Frames = frames,
		Total = #frames,
		FinishScript = endscript,
		StartScript = startscript,
	}
	CheckOnUpdateNeeded()
end
--- Unregisters a animation from being played
-- @param name (string) The animation identifer
--
function Lib.Anim.Remove(name)
	if ZZLibrary_AnimList[name] then
		local anim = ZZLibrary_AnimList[name]
		if anim.Frames[anim.Total].Width then
			anim.Object:SetWidth(anim.Frames[anim.Total].Width)
		end
		if anim.Frames[anim.Total].Height then
			anim.Object:SetHeight(anim.Frames[anim.Total].Height)
		end
		if anim.Frames[anim.Total].Scale then
			anim.Object:SetScale(anim.Frames[anim.Total].Scale)
		end
		if anim.Frames[anim.Total].Alpha then
			anim.Object:SetAlpha(anim.Frames[anim.Total].Alpha)
		end
		if anim.Frames[anim.Total].Pos then
			anim.Object:SetPos(anim.Frames[anim.Total].Pos[1], anim.Frames[anim.Total].Pos[2])
		end

		if anim.FinishScript then
			RunScript(anim.FinishScript, name)
		end

		ZZLibrary_AnimList[name] = nil
		CheckOnUpdateNeeded()
	end
end

--------------------------------------------------------------------------------------
-- ANIMATION LIBRARY------------------------------------------------------------------
--------------------------------------------------------------------------------------

---
--
--[[
	StoryBoard = {
		{
			_Frame = "frame",
			_Start = "startscript",
			_End = "endscript",
			_Time = "t in sec",
			SetAlpha = {
				From = {},
				To = {},
			},
		},
	}
	 ]]
function Lib.Story.New(name, storyboard, fps)
	local Frames = {}
	local ForceFrames = {}
	for Step, Animation in pairs(storyboard) do
		local Target = Animation._Frame
		local StartScript = Animation._Start
		local EndScript = Animation._End
		local Time = Animation._Time
		local NumFrames = math.floor(fps * Time)

		local Transitions = {};
		for Setter, Trans in pairs(Animation) do
			if Target[Setter] then
				if #Trans.From == #Trans.To then
					Transitions[Setter] = {}
					for Param = 1, #Trans.From do
						if type(Trans.From[Param]) == "number" then
							Transitions[Setter][Param] = function(progress) return Trans.From[Param] + (progress * (Trans.To[Param] - Trans.From[Param]))end
						else
							Transitions[Setter][Param] = function(progress) return (progress <= 0.5) and Trans.From[Param] or Trans.To[Param] end
					    end
					end
				end
			end
		end

		for CurrFrame = 1, NumFrames do
			local Frame = {
				Values = {}
			}
			for Setter, ValGetter in pairs(Transitions) do
				Frame.Values[Setter] = {}
				for Param = 1, #ValGetter do
					local Value = ValGetter[Param](CurrFrame / NumFrames)
					Frame.Values[Setter][Param] = Value
				end
			end
			if CurrFrame == 1 then
				table.insert(ForceFrames, #Frames + 1)
				Frame.Script = StartScript
			elseif CurrFrame == NumFrames then
				Frame.Script = EndScript
				table.insert(ForceFrames, #Frames + 1)
			end
			Frame.Target = Target
			table.insert(Frames, Frame)
		end
	end
	ZZLibrary_StoryList[name] = {
		Delay = 1 / fps,
		Next = 0,
		Curr = 0,
		Frames = Frames,
		ForceFrames = ForceFrames,
	}
end
function Lib.Story.ApplyFrame(frames, num, name)
	local Frame = frames[num]
	--catch(type(frames) == "table" and type(num) == "number" and frames[num], "Trying to apply storyboard frame with invalid arguments", tostring(frames), tostring(num))

	local Script = Frame.Script
	local Target = Frame.Target
	for Setter, Value in pairs(Frame.Values) do
		if not pcall(Target[Setter], Target, Value[1], Value[2], Value[3], Value[4], Value[5], Value[6], Value[7]) then
			print(string.format([[|cffff0000WARNING: Error while processing '%s' on animation '%s'! (Frame: %s / %s)|r
				t: %s | p1: %s | p2: %s | p3: %s | p4: %s]],
				tostring(Setter), tostring(name), tostring(num), tostring(#frames), tostring(Target),
				tostring(Value[1]), tostring(Value[2]), tostring(Value[3]), tostring(Value[4]))
			)
		end
		--Target[Setter](Target, Value[1], Value[2], Value[3], Value[4], Value[5], Value[6], Value[7])
	end
	if Script then
		RunScript(Script)
	end
end
function Lib.Story.Remove(name)
	if ZZLibrary_StoryList[name] then
		local Animation = ZZLibrary_StoryList[name]
		for Index, FrameNum in pairs(Animation.ForceFrames) do
			Story.ApplyFrame(Animation.Frames, FrameNum, name)
		end
		ZZLibrary_StoryList[name] = nil
		CheckOnUpdateNeeded()
	end
end


--------------------------------------------------------------------------------------
-- EVENT HANDLING LIBRARY-------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Registers a script for execution on event.
-- @param event (string) A event identifier; Custom ones for library internal events are allowed.
-- @param script (string/function) A script to be executed on event
-- @param key (string) A event specific registration identifer
--
function Lib.Event.Register(event, script, key)
	if not (event and script and key) then throw("Trying to register for event with invalid arguments", 2, event, script, key) end

	dbg(string.format("register: |cffffff00%s|r > |cff00ff00%s|r > |cff00ffff%s|r", event, key, tostring(script)), Lib.Event.Output)
	CheckEventRegister(event)
	ZZLibrary_EventList[event][key] = script
end
--- Unregisteres/Removes a script for execution on event.
-- @param event (string) The event identifer that has ben registerd for
-- @param key (string) The event specific registration identifer
--
function Lib.Event.Unregister(event, key)
	if not (event and key) then throw("Trying to unregister for event with invalid arguments", 2, event, key) end

	dbg(string.format("unregister: |cffffff00%s|r > |cff00ff00%s|r", event, key), Lib.Event.Output)
	if ZZLibrary_EventList[event] then
		ZZLibrary_EventList[event][key] = nil
		CheckEventUnRegister(event)
	end
end
--- Triggers an library internal event.
-- @param event (string) The event identifer
-- @param arg1 (var) A event parameter
-- @param arg2 (var) A event parameter
-- @param arg3 (var) A event parameter
-- @param arg4 (var) A event parameter
-- @param arg5 (var) A event parameter
-- @param arg6 (var) A event parameter
-- @param arg7 (var) A event parameter
-- @param arg8 (var) A event parameter
-- @param arg9 (var) A event parameter
--
function Lib.Event.Trigger(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if not event then throw("Trying to trigger event with invalid arguments", 2, event) end

	dbg(string.format("trigger: |cffff00ff%s|r", tostring(event)), Lib.Event.Output)
	if ZZLibrary_EventList[event] then
		TriggerEvents(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	end
end


--------------------------------------------------------------------------------------
-- TIMING LIBRARY --------------------------------------------------------------------
--------------------------------------------------------------------------------------

--- Registers a new timer.
-- @param delay (number, table) Measured in seconds. For numbers: Synchronous delay. For tables see <a href="#TimerDelay">TimerDelay</a>
-- @param script (string, functions) The script that gets executed each tick
-- @param key (string) A identifer for the timer
--
function Lib.Timer.Add(delay, script, key)
	if not (delay and script and key) then throw("Trying to add timer with invalid arguments", 2, delay, script, key) end

	local initdelay
	if type(delay) == "table" then
		initdelay = delay[1]
		delay = delay[2]
	else
		initdelay = delay
	end

	--dbg(string.format("add timer: |cffffff00%s|r > |cff00ff00%s|r > |cff00ffff%s|r", tostring(delay), tostring(key), tostring(script)), Lib.Timer.Output)
	ZZLibrary_TimerList[key] = {
		Time = initdelay,
		Delay = delay,
		NumFired = 0,
		Script = script,
	}

	CheckOnUpdateNeeded()
end
--- Removes and stops a timer.
-- @param key The timer to be removed
--
function Lib.Timer.Remove(key)
	--dbg(string.format("del timer: |cff00ff00%s|r", tostring(key)), Lib.Timer.Output)
	ZZLibrary_TimerList[key] = nil
	CheckOnUpdateNeeded()
end


local function import_bit_library()
---
--LUA MODULE
--
--  https://github.com/davidm/lua-bit-numberlua/
--  bit.numberlua - Bitwise operations implemented in pure Lua as numbers,
--	with Lua 5.2 'bit32' and (LuaJIT) LuaBitOp 'bit' compatibility interfaces.
--
--SYNOPSIS
--
--  local bit = require 'bit.numberlua'
--  print(bit.band(0xff00ff00, 0x00ff00ff)) --> 0xffffffff
--
--  -- Interface providing strong Lua 5.2 'bit32' compatibility
--  local bit32 = require 'bit.numberlua'.bit32
--  assert(bit32.band(-1) == 0xffffffff)
--
--  -- Interface providing strong (LuaJIT) LuaBitOp 'bit' compatibility
--  local bit = require 'bit.numberlua'.bit
--  assert(bit.tobit(0xffffffff) == -1)
--
--LICENSE
--
--  (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.

	local M = {_TYPE='module', _NAME='bit.numberlua', _VERSION='0.3.1.20120131'}

	local floor = math.floor

	local MOD = 2^32
	local MODM = MOD-1

	local function memoize(f)
		local mt = {}
		local t = setmetatable({}, mt)
		function mt:__index(k)
			local v = f(k); t[k] = v
			return v
		end
		return t
	end

	local function make_bitop_uncached(t, m)
		local function bitop(a, b)
			local res,p = 0,1
			while a ~= 0 and b ~= 0 do
				local am, bm = a%m, b%m
				res = res + t[am][bm]*p
				a = (a - am) / m
				b = (b - bm) / m
				p = p*m
			end
			res = res + (a+b)*p
			return res
		end
		return bitop
	end

	local function make_bitop(t)
		local op1 = make_bitop_uncached(t,2^1)
		local op2 = memoize(function(a)
			return memoize(function(b)
				return op1(a, b)
			end)
		end)
		return make_bitop_uncached(op2, 2^(t.n or 1))
	end

	-- ok?  probably not if running on a 32-bit int Lua number type platform
	function M.tobit(x)
		return x % 2^32
	end

	M.bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}
	local bxor = M.bxor

	function M.bnot(a)   return MODM - a end
	local bnot = M.bnot

	function M.band(a,b) return ((a+b) - bxor(a,b))/2 end
	local band = M.band

	function M.bor(a,b)  return MODM - band(MODM - a, MODM - b) end
	local bor = M.bor

	local lshift, rshift -- forward declare

	function M.rshift(a,disp) -- Lua5.2 insipred
		if disp < 0 then return lshift(a,-disp) end
		return floor(a % 2^32 / 2^disp)
	end
	rshift = M.rshift

	function M.lshift(a,disp) -- Lua5.2 inspired
		if disp < 0 then return rshift(a,-disp) end
		return (a * 2^disp) % 2^32
	end
	lshift = M.lshift

	function M.tohex(x, n) -- BitOp style
		n = n or 8
		local up
		if n <= 0 then
			if n == 0 then return '' end
			up = true
			n = - n
		end
		x = band(x, 16^n-1)
		return ('%0'..n..(up and 'X' or 'x')):format(x)
	end
	local tohex = M.tohex

	function M.extract(n, field, width) -- Lua5.2 inspired
		width = width or 1
		return band(rshift(n, field), 2^width-1)
	end
	local extract = M.extract

	function M.replace(n, v, field, width) -- Lua5.2 inspired
		width = width or 1
		local mask1 = 2^width-1
		v = band(v, mask1) -- required by spec?
		local mask = bnot(lshift(mask1, field))
		return band(n, mask) + lshift(v, field)
	end
	local replace = M.replace

	function M.bswap(x)  -- BitOp style
		local a = band(x, 0xff); x = rshift(x, 8)
		local b = band(x, 0xff); x = rshift(x, 8)
		local c = band(x, 0xff); x = rshift(x, 8)
		local d = band(x, 0xff)
		return lshift(lshift(lshift(a, 8) + b, 8) + c, 8) + d
	end
	local bswap = M.bswap

	function M.rrotate(x, disp)  -- Lua5.2 inspired
		disp = disp % 32
		local low = band(x, 2^disp-1)
		return rshift(x, disp) + lshift(low, 32-disp)
	end
	local rrotate = M.rrotate

	function M.lrotate(x, disp)  -- Lua5.2 inspired
		return rrotate(x, -disp)
	end
	local lrotate = M.lrotate

	M.rol = M.lrotate  -- LuaOp inspired
	M.ror = M.rrotate  -- LuaOp insipred


	function M.arshift(x, disp) -- Lua5.2 inspired
		local z = rshift(x, disp)
		if x >= 0x80000000 then z = z + lshift(2^disp-1, 32-disp) end
		return z
	end
	local arshift = M.arshift

	function M.btest(x, y) -- Lua5.2 inspired
		return band(x, y) ~= 0
	end

	--
	-- Start Lua 5.2 "bit32" compat section.
	--

	M.bit32 = {} -- Lua 5.2 'bit32' compatibility


	local function bit32_bnot(x)
		return (-1 - x) % MOD
	end
	M.bit32.bnot = bit32_bnot

	local function bit32_bxor(a, b, c, ...)
		local z
		if b then
			a = a % MOD
			b = b % MOD
			z = bxor(a, b)
			if c then
				z = bit32_bxor(z, c, ...)
			end
			return z
		elseif a then
			return a % MOD
		else
			return 0
		end
	end
	M.bit32.bxor = bit32_bxor

	local function bit32_band(a, b, c, ...)
		local z
		if b then
			a = a % MOD
			b = b % MOD
			z = ((a+b) - bxor(a,b)) / 2
			if c then
				z = bit32_band(z, c, ...)
			end
			return z
		elseif a then
			return a % MOD
		else
			return MODM
		end
	end
	M.bit32.band = bit32_band

	local function bit32_bor(a, b, c, ...)
		local z
		if b then
			a = a % MOD
			b = b % MOD
			z = MODM - band(MODM - a, MODM - b)
			if c then
				z = bit32_bor(z, c, ...)
			end
			return z
		elseif a then
			return a % MOD
		else
			return 0
		end
	end
	M.bit32.bor = bit32_bor

	function M.bit32.btest(...)
		return bit32_band(...) ~= 0
	end

	function M.bit32.lrotate(x, disp)
		return lrotate(x % MOD, disp)
	end

	function M.bit32.rrotate(x, disp)
		return rrotate(x % MOD, disp)
	end

	function M.bit32.lshift(x,disp)
		if disp > 31 or disp < -31 then return 0 end
		return lshift(x % MOD, disp)
	end

	function M.bit32.rshift(x,disp)
		if disp > 31 or disp < -31 then return 0 end
		return rshift(x % MOD, disp)
	end

	function M.bit32.arshift(x,disp)
		x = x % MOD
		if disp >= 0 then
			if disp > 31 then
				return (x >= 0x80000000) and MODM or 0
			else
				local z = rshift(x, disp)
				if x >= 0x80000000 then z = z + lshift(2^disp-1, 32-disp) end
				return z
			end
		else
			return lshift(x, -disp)
		end
	end

	function M.bit32.extract(x, field, ...)
		local width = ... or 1
		if field < 0 or field > 31 or width < 0 or field+width > 32 then error 'out of range' end
		x = x % MOD
		return extract(x, field, ...)
	end

	function M.bit32.replace(x, v, field, ...)
		local width = ... or 1
		if field < 0 or field > 31 or width < 0 or field+width > 32 then error 'out of range' end
		x = x % MOD
		v = v % MOD
		return replace(x, v, field, ...)
	end


	--
	-- Start LuaBitOp "bit" compat section.
	--

	M.bit = {} -- LuaBitOp "bit" compatibility

	function M.bit.tobit(x)
		x = x % MOD
		if x >= 0x80000000 then x = x - MOD end
		return x
	end
	local bit_tobit = M.bit.tobit

	function M.bit.tohex(x, ...)
		return tohex(x % MOD, ...)
	end

	function M.bit.bnot(x)
		return bit_tobit(bnot(x % MOD))
	end

	local function bit_bor(a, b, c, ...)
		if c then
			return bit_bor(bit_bor(a, b), c, ...)
		elseif b then
			return bit_tobit(bor(a % MOD, b % MOD))
		else
			return bit_tobit(a)
		end
	end
	M.bit.bor = bit_bor

	local function bit_band(a, b, c, ...)
		if c then
			return bit_band(bit_band(a, b), c, ...)
		elseif b then
			return bit_tobit(band(a % MOD, b % MOD))
		else
			return bit_tobit(a)
		end
	end
	M.bit.band = bit_band

	local function bit_bxor(a, b, c, ...)
		if c then
			return bit_bxor(bit_bxor(a, b), c, ...)
		elseif b then
			return bit_tobit(bxor(a % MOD, b % MOD))
		else
			return bit_tobit(a)
		end
	end
	M.bit.bxor = bit_bxor

	function M.bit.lshift(x, n)
		return bit_tobit(lshift(x % MOD, n % 32))
	end

	function M.bit.rshift(x, n)
		return bit_tobit(rshift(x % MOD, n % 32))
	end

	function M.bit.arshift(x, n)
		return bit_tobit(arshift(x % MOD, n % 32))
	end

	function M.bit.rol(x, n)
		return bit_tobit(lrotate(x % MOD, n % 32))
	end

	function M.bit.ror(x, n)
		return bit_tobit(rrotate(x % MOD, n % 32))
	end

	function M.bit.bswap(x)
		return bit_tobit(bswap(x % MOD))
	end

	return M
end
bit = import_bit_library()
Lib.Bit = bit
Lib.ReregisterEvents()
return Lib

--- The representation of a addon used for print functions.
-- @class table
-- @name PrintSender
-- @field Name The name of the addon sending a message
-- @field Version The version of the addon sending a message
-- @field Debug (optional) The debug flag

--- An array of arrays that template the tooltip contents.<br/>
-- It consits of an array of arrays. An array length of 1 builds a single column line, where as 2 builds a double column line.
-- @class table
-- @name TooltipContents

--- An array that configures a timer.
-- @class table
-- @name TimerDelay
-- @field 1 The initial delay
-- @field 2 The normal delay; If 0 the timer is triggered only once.

--- An array that represents a hexadecimal gradient stop.
-- @class table
-- @name HEXGradientStop
-- @field 1 The value to place the stop at
-- @field 2 The color at this gradient stop

--- An array that represents a hexadecimal gradient stop.
-- @class table
-- @name RGBAGradientStop
-- @field 1 The value to place the stop at
-- @field 2 The red channel of the color at this gradient stop
-- @field 3 The green channel of the color at this gradient stop
-- @field 4 The blue channel of the color at this gradient stop
-- @field 5 The alpha channel of the color at this gradient stop
