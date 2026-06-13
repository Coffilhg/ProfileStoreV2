--[[

this shall be run via the Command Bar inside Roblox Studio
this code is very far from perfect, read and edit to your liking
observe the difference between using AllScopes and not
change the key for UpdateAsync, etc., test it yourself

--]]

print(table.concat(table.create(9, "\n")))
local DSS = game:GetService(`DataStoreService`)

local DSO = Instance.new(`DataStoreOptions`)
DSO:SetExperimentalFeatures({v2 = true})
DSO.AllScopes = true -- change this

local DS = DSS:GetDataStore(`Store1`, (DSO.AllScopes and "" or nil), DSO)

--
DS:UpdateAsync("e/"..table.concat(table.create(50, "a")), function(previousData)
	print("Previously saved data:", previousData)
	if not previousData then
		print("Saving from nothing, new count created: 0")
		return {
			count = 0
		}
	end

	previousData.count += 1
	print("Saving with coutn of", previousData.count)

	return previousData
end)
--]]

if DSO.AllScopes then
	local scopes = {}
	warn("Printing all full keynames")
	local function listScopes()
		local pages = DS:ListKeysAsync("", 100) :: DataStoreKeyPages
		local keys = pages:GetCurrentPage()

		for _, key : DataStoreKey in pairs(keys) do
			--print(key.ClassName, key.Name, key.KeyName, key["DataCost"])
			print(key.KeyName)
			scopes[key.KeyName:gsub(`(.*)\/.*`, `%1`)] = true
		end

		if pages.IsFinished == false then
			pages:AdvanceToNextPageAsync():Wait()
			listScopes()
		end
	end


	listScopes()
	warn("Lisitng scopes")
	local scopesArray = {}
	for scope in pairs(scopes) do
		table.insert(scopesArray, scope)
	end
	table.sort(scopesArray)
	print(`All Scopes (A-Z order):\n\t{table.concat(scopesArray, "\n\t")}`)
end
warn("Success")