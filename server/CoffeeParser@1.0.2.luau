--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser

    CoffeeParser
    Copyright © 2025 Coffilhg (Roblox UserId 517222346)
    
    

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser
    Module Version: 1.0.2
--]]--
--!strict

-- Standalone CoffeeParser for Roblox datatypes

-- Customizable constants (FEEL FREE TO MODIFY)
local debugEnabled : boolean = false
local debugSeverity : number = 0
local precision : number = 3
local encodePrefix : string = "_C-"
-- Precalculated constants (DO NOT MODIFY)

-- encodePrefix:gsub("([^%w])", "%%%1") is needed to escape functions of the magical characters
-- though this actually escapes EVERY non-alphanumeric character automatically
local prefixMatchPattern : string = `^{encodePrefix:gsub("([^%w])", "%%%1")}.%(`
-- Calculation: prefix length + 1 for the "."
-- then + 1 for the "(" and + 1 to skip over "("
local decodeSubLengthBase : number = #encodePrefix + 1
local decodeSubLength : number = decodeSubLengthBase + 2
local precisionFormatter : string = "%."..(type(precision) == "number" and precision or 3).."f"

--[=[--
--	Minified Roblox Datatype prefix codes:

	Axes					->	A	(No Support Yet)
	BrickColor				->	B
	CFrame					->	C
	CatalogSearchParams		->	D	(No Support Yet)
	Color3					->	c
	ColorSequence			->	e
	ColorSequenceKeypoint	->	E
	Content					->	F
	DateTime				->	G	(No Support Yet)
	EnumItem				->	H
	Faces					->	f	(No Support Yet)
	FloatCurveKey			->	k	(No Support Yet)
	Font					->	g
	NumberRange				->	n
	NumberSequence			->	s
	NumberSequenceKeypoint	->	S
	PhysicalProperties		->	P	(No Support Yet)
	Ray						->	y
	Rect					->	m
	Region3					->	R	(No Support Yet)
	Region3int16			->	r	(No Support Yet)
	RotationCurveKey		->	K	(No Support Yet)
	TweenInfo				->	T	(No Support Yet)
	UDim					->	u
	UDim2					->	U
	ValueCurveKey			->	v	(No Support Yet)
	Vector2					->	2
	Vector2int16			->	1	(No Support Yet)
	Vector3					->	V
	Vector3int16			->	3	(No Support Yet)

	boolean -> none, it's a default Datatype (already handled by HttpService:JSONEncode)!
	buffer 	-> none, it's a default Datatype (already handled by HttpService:JSONEncode)!
	number 	-> none, it's a default Datatype (already handled by HttpService:JSONEncode)!
	string 	-> none, it's a default Datatype (already handled by HttpService:JSONEncode)!
	
--	HttpService:JSONEncode is used automatically before saving to datastore:
--	https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits#data-limits
--	"
--	The data (key value) is also stored as a string, regardless of its initial type. You can check the size
--	of the data with the `JSONEncode()` function, which converts Luau data into a serialized JSON table.
--	"
--]=]--



-- Types for internal use and exports
export type SupportedTypesList = string | number | boolean | buffer |
BrickColor | CFrame | Color3 |
ColorSequence | Content | EnumItem |
Font | NumberRange | NumberSequence |
Ray | Rect | UDim | UDim2 | Vector2 | Vector3 |
ColorSequenceKeypoint | NumberSequenceKeypoint

-- Supported Types: 17 Roblox Datatypes; 4 Default Datatypes (string | number | boolean | buffer)

export type SupportedTypesStringList = "string" | "number" | "boolean" | "buffer" |
"BrickColor" | "CFrame" | "Color3" |
"ColorSequence" | "Content" | "EnumItem" |
"Font" | "NumberRange" | "NumberSequence" |
"Ray" | "Rect" | "UDim" | "UDim2" | "Vector2" | "Vector3" |
"ColorSequenceKeypoint" | "NumberSequenceKeypoint"

-- Do we actually ever use Roblox Datatypes for keying datastore data?
-- I think that's unconventional and does not need further handling, or does it?
export type TableIndex = string | number
-- With Roblox Datatypes (all of the supported by this parser)
export type RuntimeBasicTable = {[TableIndex]: SupportedTypesList | RuntimeBasicTable}
-- Only JSONAcceptable (but no buffer yet!)
export type PrimitiveBasicTable = {[TableIndex]: string | number | boolean | buffer | PrimitiveBasicTable}

export type TypeofTypeResult = "number" | "string" | "boolean" | "buffer" | "userdata" | typeof(type(nil))

export type CoffeeParser = {
	Encode: (data : RuntimeBasicTable, recursion : boolean?) -> PrimitiveBasicTable,
	Decode: (data : PrimitiveBasicTable, recursion : boolean?) -> RuntimeBasicTable,
}


-- Warns with the given message if debugging is enabled and the severity meets the threshold.
-- Severity levels: 0 = info (e.g., out-of-range warnings), 1 = warning (e.g., invalid input), 2+ = error (e.g., critical failures).
local function doWarn(warningSeverity : number, ...)
	if not debugEnabled then
		return
	end
	if warningSeverity < debugSeverity then
		return
	end
	warn(...)
end

-- Required for non-pcall, error proof, Enum[EnumItemName] lookup
local EnumItemLookup = {} :: {[string]: Enum}

for _, enum : Enum in ipairs(Enum:GetEnums()) do
	local enumItems = enum:GetEnumItems()
	-- uncomment to see what Enums are empty
	--local used = false
	for _, enumItem : EnumItem in ipairs(enumItems) do
		--used = true
		EnumItemLookup[`{enumItem.EnumType}`] = enum
		break
	end
	--if not used then
	--	warn(enum, "not used")
	--end
end



--- Parser Main ---
local function round(v : number) : string
	local stringR = string.format(precisionFormatter, v)
	for i = 0, precision-1 do
		local number = math.round(v*10^i)/10^i
		if number == tonumber(stringR) then
			return tostring(number)
		end
	end

	return stringR
	--return tonumber(string.format("%."..precision.."f", v))
end



--- tostring (encode) reusables ---

function tostringVector3(v : Vector3, hideWrap : boolean?) : string
	local x = round(v.X)
	local y = round(v.Y)
	local z = round(v.Z)

	local base = `{x}|{y}|{z}`
	return hideWrap and base or `V({base}`
end

function tostringVector2(v : Vector2, hideWrap : boolean?) : string
	local x = round(v.X)
	local y = round(v.Y)
	
	local base = `{x}|{y}`
	return hideWrap and base or `2({base}`
end

function tostringEnumItem(v : EnumItem) : string
	-- decode via Enum.EasingDirection:FromValue(v.Value)
	return `H({v.EnumType}|{v.Value}`
end

function tostringColor3(v : Color3, hideWrap : boolean?) : string
	local base = v:ToHex()
	return hideWrap and base or `c({base}`
end
function fromstringColor3(v : string) : (Color3?, boolean)
	if not v:match("^%x%x%x%x%x%x$") then
		doWarn(1, `Invalid Color3 hex value, expected 6-digit hexadecimal: {v}`)
		return nil, false
	end

	local success, color = pcall(Color3.fromHex, v)
	if not (success and color) then
		doWarn(1, `Failed to decode Color3 from hex: {v}`)
		return nil, false
	end

	return color, true
end

function tostringColorSequenceKeypoint(v : ColorSequenceKeypoint, hideWrap : boolean?) : string
	local base = `{round(v.Time)}|{tostringColor3(v.Value, true)}`
	return hideWrap and base or `E({base}`
end
function fromstringColorSequenceKeypoint(keypointTime : string, hexColor : string) : (ColorSequenceKeypoint?, boolean)
	local keypointTime : number? = tonumber(keypointTime)
	if not keypointTime then
		doWarn(1, `Invalid time value in ColorSequenceKeypoint, expected a valid number: {keypointTime}`)
		return nil, false
	end
	
	local color, success = fromstringColor3(hexColor)
	if not success then
		doWarn(1, `Failed to decode Color3 from hex in ColorSequenceKeypoint: {hexColor}`)
		return nil, false
	end
	
	return ColorSequenceKeypoint.new(
		keypointTime,
		color :: Color3
	), true
end

function tostringNumberSequenceKeypoint(v : NumberSequenceKeypoint, hideWrap : boolean?) : string
	local tim = round(v.Time)
	local val = round(v.Value)
	local env = round(v.Envelope)
	
	local base = `{tim}|{val}|{env}`
	return hideWrap and base or `S({base}`
end
function fromstringNumberSequenceKeypoint(keypointTime : string, keypointValue : string, keypointEnvelope : string) : (NumberSequenceKeypoint?, boolean)
	local keypointTime = tonumber(keypointTime)
	local keypointValue = tonumber(keypointValue)
	local keypointEnvelope = tonumber(keypointEnvelope)

	if 
		not (
			keypointTime and
			keypointValue and
			keypointEnvelope
		) then
		doWarn(1, `Invalid NumberSequenceKeypoint values, expected numbers, got: time={keypointTime}, value={keypointValue}, envelope={keypointEnvelope}`)
		return nil, false
	end

	return NumberSequenceKeypoint.new(
		keypointTime,
		keypointValue,
		keypointEnvelope
	), true
end


--- tostring (encode) all ---
-- typeofResult = function(v: typeofResult): string
local RobloxDatatypeCallbacksEncode = {
	--Axes = function(v : Axes) -- hard to compress, rarely used for player data / game data / admin settings
	--	return `Axes({v})`
	--end,
	EnumItem = tostringEnumItem,
	BrickColor = function(v : BrickColor) : string
		return `B({v.Number}` --- do BrickColor.new(v.Number) to decode
	end,
	CFrame = function(v : CFrame) : string
		local pos = tostringVector3(v.Position, true)
		local right = tostringVector3(v.RightVector, true)
		local up = tostringVector3(v.UpVector, true)
		--local look = v.LookVector -- unnecessary/not required for replication
		--- CFrame.fromMatrix
		return `C({pos}|{right}|{up}`
	end,
	Color3 = tostringColor3,
	ColorSequenceKeypoint = tostringColorSequenceKeypoint,
	ColorSequence = function(v : ColorSequence) : string
		local splits = v.Keypoints :: {ColorSequenceKeypoint}
		
		-- single color
		if #splits == 2 then
			local split1 = splits[1] :: ColorSequenceKeypoint
			local splitColor1 = split1.Value:ToHex()
			
			local split2 = splits[2] :: ColorSequenceKeypoint
			local splitColor2 = split2.Value:ToHex()
			
			if splitColor1 == splitColor2 then
				return "ColorSequence(" .. splitColor1
			end
		end
		
		-- more complex
		local keypoints = table.create(#splits)
		for i, split : ColorSequenceKeypoint in ipairs(splits) do
			-- ColorSequenceKeypoint.new
			keypoints[i] = tostringColorSequenceKeypoint(split, true)
		end
		
		return "e(" .. table.concat(keypoints, "|")
	end,
	Content = function(v : Content) : string
		if v.SourceType == Enum.ContentSourceType.Uri then
			--.fromUri
			return `F({v.Uri}`
			--elseif v.SourceType == Enum.ContentSourceType.Object then
			--.fromObject
			--	return `Content.O({v.Object})` -- can't parse Object to string
			--elseif v.SourceType == Enum.ContentSourceType.None then
			--	return `Content.none`
		end
		return `F(`
	end,
	--ContentId = function(v) -- wouldn't that classify as a string anyways?
	--	return `{v}`
	--end,
	--Faces = function(v)
	--	return `Faces({v}`
	--end,
	Font = function(v : Font) : string
		return `g({v.Family}|{v.Weight.Value}|{v.Style.Value}`
	end,
	NumberRange = function(v : NumberRange) : string
		local min, max = round(v.Min), round(v.Max)
		if min == max then
			return `n({max}`
		else
			return `n({min}|{max}`
		end
	end,
	NumberSequenceKeypoint = tostringNumberSequenceKeypoint,
	NumberSequence = function(v : NumberSequence) : string
		local splits = v.Keypoints :: {NumberSequenceKeypoint}
		
		-- single number
		if #splits == 2 then
			local split1 = splits[1].Value
			local split2 = splits[2].Value
			if split1 == split2 then
				return `s({round(split1)}`
			end
		end
		
		-- more complex
		local keypoints = table.create(#splits)
		for i, split : NumberSequenceKeypoint in ipairs(splits) do
			-- NumberSequenceKeypoint.new
			keypoints[i] = tostringNumberSequenceKeypoint(split, true)
		end
		
		return "s(" .. table.concat(keypoints, "|")
	end,
	Ray = function(v : Ray) : string
		local origin, direction = tostringVector3(v.Origin, true), tostringVector3(v.Direction, true)
		return `y({origin}|{direction}`
	end,
	Rect = function(v : Rect) : string
		local min, max = tostringVector2(v.Min, true), tostringVector2(v.Max, true)
		return `m({min}|{max}`
	end,
	UDim = function(v : UDim) : string
		return `u({round(v.Scale)}|{math.round(v.Offset)}`
	end,
	UDim2 = function(v : UDim2) : string
		return `U({round(v.X.Scale)}|{math.round(v.X.Offset)}|{round(v.Y.Scale)}|{math.round(v.Y.Offset)}`
	end,
	Vector2 = tostringVector2,
	Vector3 = tostringVector3,
}





-- (Minified Roblox Datatype prefix codes)[typeofResult] = (string): typeofResult?, boolean
local RobloxDatatypeCallbacksDecode = {
	--Axes = function(v : Axes) -- hard to compress, rarely used for player data / game data / admin settings
	--	return `Axes({v})`
	--end,
	
	-- Expects v to be the string after "Enum(" (e.g., "EasingDirection|1" for "_C-Enum(EasingDirection|1" ).
	-- Splits v on "|" to extract enum type and value, then uses Enum[enumTypeName]:FromValue(enumValue) to create an EnumItem.
	-- Returns (EnumItem, true) on success or (nil, false) with a warning on failure.
	["H"] = function(v: string): (EnumItem?, boolean)
		local parts = v:split("|")
		if not parts or #parts < 2 or #parts[1] < 1 or #parts[2] < 1 then
			doWarn(1, `Malformed EnumItem value, expected EnumType|Value: {v}`)
			return nil, false
		end

		local enumTypeName, enumValueStr = parts[1], parts[2]
		local enumValue = tonumber(enumValueStr)
		if not enumValue then
			doWarn(2, `Failed to convert EnumItem value to number: {enumValueStr}`)
			return nil, false -- Shouldn't happen due to digit check, but included for robustness
		end

		local enumType = EnumItemLookup[enumTypeName] :: Enum & {FromValue: (number) -> EnumItem}
		if not enumType then
			doWarn(1, `Invalid Enum type: {enumTypeName}`)
			return nil, false
		end

		local enumItem = enumType:FromValue(enumValue)
		if not enumItem then
			doWarn(1, `Invalid Enum value for {enumTypeName}: {enumValue}`)
			return nil, false
		end

		return enumItem, true
	end,
	
	-- Expects v to be the numeric string after "BrickColor(" (e.g., "194" for "_C-BrickColor(194" ).
	-- Returns BrickColor.new(number) or (nil, false) for invalid inputs.
	["B"] = function(v : string): (BrickColor?, boolean)
		local brickColorValue = tonumber(v)
		if not brickColorValue then
			doWarn(1, `Invalid BrickColor value, expected a number: {v}`)
			return nil, false -- Brick Color Value is not a number
		end

		if brickColorValue < 0 or brickColorValue > 1032 then
			doWarn(0, `BrickColor value out of range (0-1032): {brickColorValue}, may default to Medium stone grey`)
		end

		return BrickColor.new(brickColorValue), true
	end,
	
	-- Expects v to be the string after "CFrame(" (e.g., "0|0|0|1|0|0|0|1|0" for "_C-CFrame(0|0|0|1|0|0|0|1|0" ).
	-- Splits v on "|" to extract 9 numbers (x,y,z for Position, x,y,z for RightVector, x,y,z for UpVector).
	-- Uses CFrame.fromMatrix(Position, RightVector, UpVector) to reconstruct the CFrame.
	-- Returns (CFrame, true) on success or (nil, false) with a warning on failure.
	-- Empty input is handled by tryDecode.
	["C"] = function(v: string): (CFrame?, boolean)
		local parts = v:split("|")
		if not parts or #parts ~= 9 then
			doWarn(1, `Malformed CFrame value, expected 9 numbers (x|y|z|x|y|z|x|y|z): {v}`)
			return nil, false
		end

		local posX, posY, posZ = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
		local rightX, rightY, rightZ = tonumber(parts[4]), tonumber(parts[5]), tonumber(parts[6])
		local upX, upY, upZ = tonumber(parts[7]), tonumber(parts[8]), tonumber(parts[9])
		if not (posX and posY and posZ and rightX and rightY and rightZ and upX and upY and upZ) then
			doWarn(1, `Invalid CFrame component values, expected numbers: {v}`)
			return nil, false
		end

		local pos = Vector3.new(posX, posY, posZ)
		local right = Vector3.new(rightX, rightY, rightZ)
		local up = Vector3.new(upX, upY, upZ)

		-- Optional: Warn if right and up are not orthogonal unit vectors
		if math.abs(right.Magnitude - 1) > 0.001 or math.abs(up.Magnitude - 1) > 0.001 or math.abs(right:Dot(up)) > 0.001 then
			doWarn(0, `CFrame vectors may not be orthogonal unit vectors: right={tostring(right)}, up={tostring(up)}`)
		end

		return CFrame.fromMatrix(pos, right, up), true
	end,
	
	-- Expects v to be the string after "Color3(" (e.g., "FF0000" for _C-Color3(FF0000)).
	-- Uses Color3.fromHex to reconstruct the Color3 from the hex string.
	-- Returns (Color3, true) on success or (nil, false) with a warning on failure.
	["c"] = fromstringColor3,
	
	-- Expects v to be the string after "ColorSequenceKeypoint(" (e.g., "0|FF0000")
	["E"] = function(v: string): (ColorSequenceKeypoint?, boolean)
		if not v:find("|") then
			doWarn(1, `Invalid ColorSequenceKeypoint value, expected a "number|hex", got: {v}`)
			return nil, false
		end
		--[[
		-- I dont think this is necessary
		if not v:match("%d|%x%x%x%x%x%x$") then -- even if input is something like "0.123|FF0000" there is a digit before |; never a "."
			doWarn(1, `Placeholder`)
			return nil, false
		end
		--]]
		return fromstringColorSequenceKeypoint(table.unpack(v:split("|")))
	end,
	
	-- Expects v to be the string after "ColorSequence(" (e.g., "FF0000" for "_C-ColorSequence(FF0000" or "0|FF0000|1|00FF00" for "_C-ColorSequence(0|FF0000|1|00FF00").
	-- For simple cases (single hex color), creates a ColorSequence using ColorSequence.new(Color3.fromHex(hex)).
	-- For complex cases, splits v on "|" to extract time|color pairs, validates each time as a number and each color as a 6-digit hex string, and creates ColorSequenceKeypoint objects.
	-- Warns if keypoint times are outside [0,1] or not sorted (severity 0).
	-- Returns (ColorSequence, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (malformed hex, non-numeric time, or incorrect part count).
	["e"] = function(v: string): (ColorSequence?, boolean)
		if not v:find("|") then
			if not v:match("^%x%x%x%x%x%x$") then
				doWarn(1, `Invalid ColorSequence hex value, expected 6-digit hexadecimal: {v}`)
				return nil, false
			end

			local success, color = pcall(Color3.fromHex, v)
			if not success or not color then
				doWarn(1, `Failed to decode Color3 from hex for ColorSequence: {v}`)
				return nil, false
			end

			-- Simple case: two keypoints with the same color at times 0 and 1
			return ColorSequence.new(color), true
		end

		-- Complex case: split by "|" for time|color pairs
		local parts = v:split("|")
		local partsLength = #parts
		
		local length = partsLength / 2
		if length > 20 then
			doWarn(2, `ColorSequence is limited to 20 Keypoints; Tried Setting {length} Keypoints`)
			return nil, false
		end
		
		if partsLength % 2 ~= 0 then
			doWarn(1, `Malformed ColorSequence value, expected even number of parts (time|color pairs): {v}`)
			return nil, false
		end
		
		
		
		local keypoints = {} :: {ColorSequenceKeypoint}
		local lastKeypoint : ColorSequenceKeypoint?
		for i = 1, partsLength, 2 do
			local keypointTime = parts[i] --tonumber(parts[i])
			local hexColor = parts[i + 1]
			
			local colorSequenceKeypoint, success = fromstringColorSequenceKeypoint(keypointTime, hexColor)
			
			if not success then
				doWarn(1, `Invalid ColorSequenceKeypoint in ColorSequence (See all warnings)`)
				return nil, false
			end
			
			
			
			if
				(colorSequenceKeypoint :: ColorSequenceKeypoint).Time < 0 or
				(colorSequenceKeypoint :: ColorSequenceKeypoint).Time > 1
			then
				doWarn(2, `ColorSequence keypoint time out of range [0,1]: {(colorSequenceKeypoint :: ColorSequenceKeypoint).Time}`)
				return nil, false
			end
			if
				lastKeypoint and
				(colorSequenceKeypoint :: ColorSequenceKeypoint).Time < lastKeypoint.Time
			then
				doWarn(2, `ColorSequence keypoints not sorted by time: {v}`)
				return nil, false
			end
			
			
			
			
			lastKeypoint = colorSequenceKeypoint
			table.insert(keypoints, colorSequenceKeypoint :: ColorSequenceKeypoint)
			--[[
			if not keypointTime then
				doWarn(1, `Invalid time value in ColorSequence, expected a number: {parts[i]}`)
				return nil, false
			end
			
			if not hexColor:match("^%x%x%x%x%x%x$") then
				doWarn(1, `Invalid Color3 hex value in ColorSequence, expected 6-digit hexadecimal: {hexColor}`)
				return nil, false
			end

			local success, color = pcall(Color3.fromHex, hexColor)
			if not success or not color then
				doWarn(1, `Failed to decode Color3 from hex in ColorSequence: {hexColor}`)
				return nil, false
			end
			
			table.insert(keypoints, ColorSequenceKeypoint.new(keypointTime, color))
			--]]
		end
		
		--local length = #keypoints
		-- Validate Keypoint Limits
		--if length > 20 then
		--	doWarn(2, `ColorSequence is limited to 20 Keypoints; Tried Setting {#keypoints} Keypoints`)
		--	return nil, false
		--end
		
		if keypoints[1].Time ~= 0 then
			doWarn(2, `ColorSequence must start at time = 0.0: {keypoints[1].Time}`)
			return nil, false
		end
		if keypoints[length].Time ~= 1 then
			doWarn(2, `ColorSequence must end at time = 1.0: {keypoints[1].Time}`)
			return nil, false
		end

		---- Validate keypoints (e.g., times in [0,1], sorted)
		--for i, kp in ipairs(keypoints) do
		--	if kp.Time < 0 or kp.Time > 1 then
		--		doWarn(2, `ColorSequence keypoint time out of range [0,1]: {kp.Time}`)
		--		return nil, false
		--	end
		--	if i > 1 and kp.Time < keypoints[i-1].Time then
		--		doWarn(2, `ColorSequence keypoints not sorted by time: {v}`)
		--		return nil, false
		--	end
		--end

		return ColorSequence.new(keypoints), true
	end,
	
	-- Expects v to be the string after "Content(" (e.g., "rbxassetid://6372755229" for "_C-Content(rbxassetid://6372755229").  
	-- Returns Content.fromUri(v) for non-empty input, assuming a URI string.  
	-- Empty input is handled by tryDecode, which returns Content.none for datatype "Content".
	-- Returns (Content, true) on success or (nil, false) with a warning (severity 1) if Content.fromUri fails.  
	["F"] = function(v: string): (Content?, boolean)
		local success, content = pcall(Content.fromUri, v)
		if not success or not content then
			doWarn(1, `Failed to decode Content from URI: {v}`)
			return nil, false
		end
		return content, true
	end,
	
	--ContentId = function(v) -- wouldn't that classify as a string anyways?
	--	return `{v}`
	--end,
	--Faces = function(v)
	--	return `Faces({v}`
	--end,
	
	-- Expects v to be the string after "Font(" (e.g., "rbxasset://fonts/Arial.ttf|400|Normal" for "_C-Font(rbxasset://fonts/Arial.ttf|400|Normal").
	-- Splits v on "|" to extract Family (string), Weight (number or Enum.FontWeight name), and Style (Enum.FontStyle name).
	-- Uses Font.new(Family, Weight, Style) to reconstruct the Font.
	-- Returns (Font, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (malformed format, invalid weight, or invalid style)
	["g"] = function(v: string): (Font?, boolean)
		local parts = v:split("|")
		if not parts or #parts ~= 3 then
			doWarn(1, `Malformed Font value, expected Family|Weight|Style: {v}`)
			return nil, false
		end

		local family, weightValue, styleValue = parts[1], tonumber(parts[2]), tonumber(parts[3])

		-- Validate Family (non-empty string)
		if #family < 1 then
			doWarn(1, `Invalid Font Family, expected non-empty string: {family}`)
			return nil, false
		end
		if not (weightValue and styleValue) then
			doWarn(1, `Invalid Weight or Style -Font Value, Number expected: weightValue->{weightValue} styleValue->{styleValue}`)
			return nil, false
		end

		-- Validate Weight (number or Enum.FontWeight name)
		local weight = Enum.FontWeight:FromValue(weightValue)
		if not weight then
			doWarn(1, `Invalid Font Weight, expected number or Enum.FontWeight name: {weightValue}`)
			return nil, false
		end

		-- Validate Style (Enum.FontStyle name, e.g., "Normal", "Italic")
		local style = Enum.FontStyle:FromValue(styleValue)
		if not style then
			doWarn(1, `Invalid Font Style, expected Enum.FontStyle name: {styleValue}`)
			return nil, false
		end

		-- Attempt to create Font
		local success, font = pcall(Font.new, family, weight, style)
		if not success or not font then
			doWarn(1, `Failed to create Font with Family={family}, Weight={weightValue}, Style={styleValue}`)
			return nil, false
		end

		return font, true
	end,
	
	-- Expects v to be the string after "NumberRange(" (e.g., "5|10" for "_C-NumberRange(5|10" or "5" for "_C-NumberRange(5").
	-- Splits v on "|" to extract one or two numbers (Min|Max or single Value for Min=Max).
	-- Uses NumberRange.new(Min, Max) or NumberRange.new(Value) to reconstruct the NumberRange.
	-- Returns (NumberRange, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count)
	["n"] = function(v: string): (NumberRange?, boolean)
		local parts = v:split("|")

		-- Handle single value case (Min == Max)
		if #parts == 1 then
			local value = tonumber(parts[1])
			if not value then
				doWarn(1, `Invalid NumberRange value, expected a number: {parts[1]}`)
				return nil, false
			end
			return NumberRange.new(value), true
		end

		-- Handle Min|Max case
		if #parts ~= 2 then
			doWarn(1, `Malformed NumberRange value, expected Value or Min|Max: {v}`)
			return nil, false
		end

		local min = tonumber(parts[1])
		local max = tonumber(parts[2])
		if not min or not max then
			doWarn(1, `Invalid NumberRange component values, expected numbers: {v}`)
			return nil, false
		end

		return NumberRange.new(math.min(min, max), math.max(min, max)), true
	end,
	
	["S"] = function(v: string): (NumberSequenceKeypoint?, boolean)
		if not v:find("|") then
			doWarn(1, `Invalid NumberSequenceKeypoint value, expected a "number|number|number", got: {v}`)
			return nil, false
		end
		
		return fromstringNumberSequenceKeypoint(table.unpack(v:split("|")))
	end,
	-- Expects v to be the string after "NumberSequence(" (e.g., "0.5" for "_C-NumberSequence(0.5)" or "0|0.5|0|1|1|0" for "_C-NumberSequence(0|0.5|0|1|1|0").
	-- For simple cases (single number), creates a NumberSequence with two keypoints at times 0 and 1 with the same value.
	-- For complex cases, splits v on "|" to extract time|value|envelope triplets, validates each as a number, and creates NumberSequenceKeypoint objects.
	-- Warns if keypoint times are outside [0,1] or not sorted (severity 0).
	-- Returns (NumberSequence, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["s"] = function(v: string): (NumberSequence?, boolean)
		if not v:find("|") then
			local value = tonumber(v)
			if not value then
				doWarn(1, `Invalid NumberSequence value, expected a number: {v}`)
				return nil, false
			end
			-- Simple case: two keypoints with the same value at times 0 and 1
			return NumberSequence.new(value), true
		end

		-- Complex case: split by "|" for time|value|envelope triplets
		local parts = v:split("|")
		local partsLength = #parts
		
		local length = partsLength / 3
		-- Validate Sequence Keypoint Amount Length Limit
		if length > 20 then
			doWarn(2, `NumberSequence is limited to 20 Keypoints; Tried Setting {length} Keypoints`)
			return nil, false
		end
		
		if #parts % 3 ~= 0 then
			doWarn(1, `Malformed NumberSequence value, expected triplets (time|value|envelope): {v}`)
			return nil, false
		end

		local keypoints = {} :: {NumberSequenceKeypoint}
		local lastKeypoint : NumberSequenceKeypoint?

		for i = 1, #parts, 3 do
			local keypointTime = parts[i] --tonumber(parts[i])
			local keypointValue = parts[i + 1] --tonumber(parts[i + 1])
			local keypointEnvelope = parts[i + 2] --tonumber(parts[i + 2])
			
			local numberSequenceKeypoint, success = fromstringNumberSequenceKeypoint(keypointTime, keypointValue, keypointEnvelope)
			
			if not success then
				doWarn(1, `Invalid NumberSequenceKeypoint in NumberSequence (See all warnings)`)
				return nil, false
			end
			
			
			
			if
				(numberSequenceKeypoint :: NumberSequenceKeypoint).Time < 0 or
				(numberSequenceKeypoint :: NumberSequenceKeypoint).Time > 1
			then
				doWarn(2, `ColorSequence keypoint time out of range [0,1]: {(numberSequenceKeypoint :: NumberSequenceKeypoint).Time}`)
				return nil, false
			end
			if
				lastKeypoint and
				(numberSequenceKeypoint :: NumberSequenceKeypoint).Time < lastKeypoint.Time
			then
				doWarn(2, `ColorSequence keypoints not sorted by time: {v}`)
				return nil, false
			end
			
			lastKeypoint = numberSequenceKeypoint
			table.insert(keypoints, numberSequenceKeypoint :: NumberSequenceKeypoint)
			
			--if not (keypointTime and keypointValue and keypointEnvelope) then
			--	doWarn(1, `Invalid NumberSequence keypoint values, expected numbers: time={parts[i]}, value={parts[i+1]}, envelope={parts[i+2]}`)
			--	return nil, false
			--end

			--table.insert(keypoints, NumberSequenceKeypoint.new(keypointTime, keypointValue, math.max(0, keypointEnvelope)))
		end

		---- Validate Keypoint Limits
		--if #keypoints > 20 then
		--	doWarn(2, `NumberSequence is limited to 20 Keypoints; Tried Setting {#keypoints} Keypoints`)
		--	return nil, false
		--end

		-- Validate keypoints (e.g., times in [0,1], sorted)
		for i, kp in ipairs(keypoints) do
			if kp.Time < 0 or kp.Time > 1 then
				doWarn(2, `NumberSequence keypoint time out of range [0,1]: {kp.Time}`)
				return nil, false
			end
			if i > 1 and kp.Time < keypoints[i-1].Time then
				doWarn(2, `NumberSequence keypoints not sorted by time: {v}`)
				return nil, false
			end
		end

		return NumberSequence.new(keypoints), true
	end,

	-- Expects v to be the string after "Ray(" (e.g., "1|2|3|4|5|6" for "_C-Ray(1|2|3|4|5|6").
	-- Splits v on "|" to extract 6 numbers (x|y|z for Origin, x|y|z for Direction).
	-- Uses Ray.new(Origin, Direction) to reconstruct the Ray.
	-- Returns (Ray, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["y"] = function(v: string): (Ray?, boolean)
		local parts = v:split("|")
		if #parts ~= 6 then
			doWarn(1, `Malformed Ray value, expected 6 numbers (x|y|z|x|y|z): {v}`)
			return nil, false
		end

		local originX, originY, originZ = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
		local dirX, dirY, dirZ = tonumber(parts[4]), tonumber(parts[5]), tonumber(parts[6])
		if not (originX and originY and originZ and dirX and dirY and dirZ) then
			doWarn(1, `Invalid Ray component values, expected numbers: {v}`)
			return nil, false
		end

		local origin = Vector3.new(originX, originY, originZ)
		local direction = Vector3.new(dirX, dirY, dirZ)
		return Ray.new(origin, direction), true
	end,

	-- Expects v to be the string after "Rect(" (e.g., "1|2|3|4" for "_C-Rect(1|2|3|4)").
	-- Splits v on "|" to extract 4 numbers (minX|minY|maxX|maxY).
	-- Uses Rect.new(minX, minY, maxX, maxY) to reconstruct the Rect.
	-- Returns (Rect, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["m"] = function(v: string): (Rect?, boolean)
		local parts = v:split("|")
		if #parts ~= 4 then
			doWarn(1, `Malformed Rect value, expected 4 numbers (minX|minY|maxX|maxY): {v}`)
			return nil, false
		end

		local minX, minY, maxX, maxY = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
		if not (minX and minY and maxX and maxY) then
			doWarn(1, `Invalid Rect component values, expected numbers: {v}`)
			return nil, false
		end

		return Rect.new(minX, minY, maxX, maxY), true
	end,

	-- Expects v to be the string after "UDim(" (e.g., "0.5|100" for "_C-UDim(0.5|100").
	-- Splits v on "|" to extract 2 numbers (Scale|Offset).
	-- Uses UDim.new(Scale, Offset) to reconstruct the UDim.
	-- Returns (UDim, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["u"] = function(v: string): (UDim?, boolean)
		local parts = v:split("|")
		if #parts ~= 2 then
			doWarn(1, `Malformed UDim value, expected 2 numbers (Scale|Offset): {v}`)
			return nil, false
		end

		local scale, offset = tonumber(parts[1]), tonumber(parts[2])
		if not (scale and offset) then
			doWarn(1, `Invalid UDim component values, expected numbers: {v}`)
			return nil, false
		end

		return UDim.new(scale, offset), true
	end,

	-- Expects v to be the string after "UDim2(" (e.g., "0.5|100|0.25|50" for "_C-UDim2(0.5|100|0.25|50").
	-- Splits v on "|" to extract 4 numbers (xScale|xOffset|yScale|yOffset).
	-- Uses UDim2.new(xScale, xOffset, yScale, yOffset) to reconstruct the UDim2.
	-- Returns (UDim2, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["U"] = function(v: string): (UDim2?, boolean)
		local parts = v:split("|")
		if #parts ~= 4 then
			doWarn(1, `Malformed UDim2 value, expected 4 numbers (xScale|xOffset|yScale|yOffset): {v}`)
			return nil, false
		end

		local xScale, xOffset, yScale, yOffset = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
		if not (xScale and xOffset and yScale and yOffset) then
			doWarn(1, `Invalid UDim2 component values, expected numbers: {v}`)
			return nil, false
		end

		return UDim2.new(xScale, xOffset, yScale, yOffset), true
	end,

	-- Expects v to be the string after "Vector2(" (e.g., "1|2" for "_C-Vector2(1|2").
	-- Splits v on "," to extract 2 numbers (x|y).
	-- Uses Vector2.new(x, y) to reconstruct the Vector2.
	-- Returns (Vector2, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["2"] = function(v: string): (Vector2?, boolean)
		local parts = v:split("|")
		if #parts ~= 2 then
			doWarn(1, `Malformed Vector2 value, expected 2 numbers (x|y): {v}`)
			return nil, false
		end

		local x, y = tonumber(parts[1]), tonumber(parts[2])
		if not (x and y) then
			doWarn(1, `Invalid Vector2 component values, expected numbers: {v}`)
			return nil, false
		end

		return Vector2.new(x, y), true
	end,

	-- Expects v to be the string after "Vector3(" (e.g., "1|2|3" for "_C-Vector3(1|2|3").
	-- Splits v on "|" to extract 3 numbers (x|y|z).
	-- Uses Vector3.new(x, y, z) to reconstruct the Vector3.
	-- Returns (Vector3, true) on success or (nil, false) with a warning (severity 1) for invalid inputs (non-numeric values or incorrect part count).
	["V"] = function(v: string): (Vector3?, boolean)
		local parts = v:split("|")
		if #parts ~= 3 then
			doWarn(1, `Malformed Vector3 value, expected 3 numbers (x|y|z): {v}`)
			return nil, false
		end

		local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
		if not (x and y and z) then
			doWarn(1, `Invalid Vector3 component values, expected numbers: {v}`)
			return nil, false
		end

		return Vector3.new(x, y, z), true
	end,
}


--- those functions below will be refactored later once im done refactoring decode.

local function tryEncode(datatype : string, v : SupportedTypesList?)
	local cb = RobloxDatatypeCallbacksEncode[datatype] -- O(1)
	if not cb then
		return `Unknown_{datatype}` -- such will be defaulted (e.g.: Unknown_Color3 would be decoded as Color3.fromHex("FFFFFF"))
	end
	return `{encodePrefix}{cb(v)}`
end

local function tryDecode(datatype: string, v: string): (SupportedTypesList | nil, boolean)
	if #v < 1 then
		if datatype == "Content" then
			return Content.none, true
		end
		doWarn(1, `Empty {datatype} value: {v}`)
		return nil, false -- Empty string (Malformed input)
	end

	local cb = RobloxDatatypeCallbacksDecode[datatype] -- O(1)
	if not cb then
		return nil, false -- such will be defaulted (e.g.: Unknown_Color3 would be decoded as Color3.fromHex("FFFFFF"))
	end
	return cb(v)
end

local function handleNonTableValuesEncode(
	valueType : TypeofTypeResult,
	resultData : PrimitiveBasicTable,
	key : TableIndex,
	value : (SupportedTypesList)?
)
	-- handle the very primitive value types (number, string and boolean)
	if valueType == "number" then
		if value == math.huge then
			resultData[key] = "math.huge"
			return
		elseif value == -math.huge then
			resultData[key] = "-math.huge"
			return
		elseif value ~= value then  -- NaN check
			resultData[key] = "nan"
			return
		end

		resultData[key] = value :: number
	elseif valueType == "string" or valueType == "boolean" or valueType == "buffer" then
		resultData[key] = value :: string | boolean | buffer
	else
		resultData[key] = tryEncode(typeof(value), value)
	end
end

local function encodeData(
	data : RuntimeBasicTable,
	recursion : boolean?
) : PrimitiveBasicTable
	if debugEnabled and not recursion then
		print("Encoding:", data)
	end

	local resultData = {} :: PrimitiveBasicTable
	for key, value in pairs(data) do
		local valueType = type(value)

		if debugEnabled and not recursion then
			print("Encode:", key, value)
		end

		if valueType == "table" then
			resultData[key] = encodeData(
				value :: RuntimeBasicTable,
				true
			)
		else
			handleNonTableValuesEncode(
				valueType,
				resultData,
				key,
				value :: SupportedTypesList?
			)
		end
	end
	return resultData
end

local function decodeData(
	data : PrimitiveBasicTable,
	recursion : boolean?
) : RuntimeBasicTable
	if debugEnabled and not recursion then
		print("Decoding:", data)
	end
	local resultData = {} :: RuntimeBasicTable
	for key, value in pairs(data) do
		local valueType = type(value)

		if debugEnabled and not recursion then
			print("Decode:", key, value)
		end

		if valueType == "table" then
			resultData[key] = decodeData(value :: PrimitiveBasicTable, true)
		elseif valueType == "number" or valueType == "boolean" or valueType == "buffer" then
			resultData[key] = value
		elseif valueType == "string" then
			if value == "math.huge" then
				resultData[key] = math.huge
				continue
			elseif value == "-math.huge" then
				resultData[key] = -math.huge
				continue
			elseif value == "nan" then
				resultData[key] = 0/0  -- NaN
				continue
			end
			
			--if not string.match(value :: string, prefixMatchPattern) then
			if not (value :: string):match(prefixMatchPattern) then
				-- just a usual string
				resultData[key] = value
				continue
			end
			--[[--
			--string.split(string.sub(value :: string, decodeSubLength), "(")
			local result = value:sub(decodeSubLength)
			if not result then
				resultData[key] = value
				continue
			end

			--- attempt decoding (might also be a user string; not likely, but just handling this would be great)
			local datatype = result[1]
			local encodedValue = result[2]
			--]]--
			
			local datatype : string = (value :: string):sub(decodeSubLengthBase, decodeSubLengthBase)
			local encodedValue : string = (value :: string):sub(decodeSubLength)
			
			--print(datatype, encodedValue)

			local decodeResult, decodeSuccess = tryDecode(datatype, encodedValue)

			if not decodeSuccess then
				resultData[key] = value
				continue
			end

			resultData[key] = decodeResult
		else
			doWarn(2, "Unknown key:", key)
		end
	end
	return resultData
end

local CoffeeParser : CoffeeParser = {
	Encode = encodeData,
	Decode = decodeData,
}

return CoffeeParser