--!strict

local SSS = game:GetService(`ServerScriptService`)
local ProfileStore = require(SSS.Server.ProfileStore)
local CoffeeParserV1_0_2 = require(SSS.Server[`CoffeeParser@1.0.2`])

local function CustomDeepCopy(t: {} | any, recursion: boolean?)
	local copy = {}
	
	for k, v in pairs(t) do
		if type(v) == `table` then
			copy[k] = CustomDeepCopy(v, true)
			continue
		end
		
		copy[k] = v
	end
	
	if not recursion then
		--print(`{table.concat(table.create(6, "\n"))}Making a Deep Copy of table:`, t, copy)
	end
	
	return copy
end

local function CustomReconcile(
	target, -- current Data
	template--, -- template Data
	--profile -- only actually useful for the built in ReconcileTable,
	-- so that it is capable of calling the CustomDeepCopy out of the box
	--
	-- that means this function as it is, IS NOT NECESSARY, and is here
	-- solely for example purposes
	--
	-- this function can be completely COMMENTED OUT
	-- and the test will still be passed
)
	for k, v in pairs(template) do
		if type(k) ~= "string" then -- Only string keys will be reconciled
			continue
		end
		
		if target[k] == nil then
			if type(v) == "table" then
				target[k] = CustomDeepCopy(v)
			else
				target[k] = v
			end
		elseif type(target[k]) == "table" and type(v) == "table" then
			CustomReconcile(target[k], v) --, profile) -- only if you need the profile
		end
	end
end

local function DecodeProxy(data)
	local decoded = CoffeeParserV1_0_2.Decode(data)
	--print(`{table.concat(table.create(6, "\n"))}Decoding a table:\n\tInput:`, data, "\n\tOutput:", decoded)
	return decoded
end

local function EncodeProxy(data)
	local encoded = CoffeeParserV1_0_2.Encode(data)
	--print(`{table.concat(table.create(6, "\n"))}Encoding a table:\n\tInput:`, data, "\n\tOutput:", encoded)
	return encoded
end

return function (profileStoreObject: ProfileStore.ProfileStore<{}>)
	profileStoreObject
		:SetDeepCopyTableCallback(CustomDeepCopy :: any)
		:SetReconcileTableCallback(CustomReconcile :: any) -- though Profile:Reconcile
		-- is only ever called Manually! Maybe this was a pointless feature or maybe its
		-- good to have it anyways, for modularity.
		
		-- next up let's imagine two data states
		-- A - the *Decoded* data, whatever is the Profile.Data at RUNTIME
		--		CoffeeParser makes it easy to handle popular Roblox datatypes
		--		such as Color3, Vector3, UDim2, CFrame and more.
		--		With that in mind, the RUNTIME Profile.Data is allowed to contain
		--		such datatypes, and they will be *Encoded* before saved to Datastore
		--
		-- B - the *Encoded* data, whetever is saved into Datastore, such data is
		-- limited to contain only those datatypes handled natively by HttpService's
		-- JSONEncode method:
		--		string | number | boolean | buffer |
		--		{any of the mentioned} (as array) |
		--		{[string | number]: any of the mentioned (as dictionary / sparse array)}
		:SetDecodeCallback(DecodeProxy) -- convert state B to A (Datastore -> Runtime)
		:SetEncodeCallback(EncodeProxy) -- convert state A to B (Runtime -> Datastore)
end