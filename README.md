# ProfileStoreV2

This is a fork of **[ProfileStore](<https://github.com/MadStudioRoblox/ProfileStore>)**, it's original README is preserved at the bottom of this README.

This fork makes it easy to implement your own modifications to the data flow.

---

## Definitions

**Roblox Datatypes**
> **Those are the Datatypes exclusive to Roblox Studio, e.g. Color3, Vector3, UDim2, CFrame and more**

**JSON Acceptable**
> **Those are the Datatypes handled by HttpService:JSONEncode!**
> 
> Why?
> 
> > HttpService:JSONEncode is used automatically before saving to datastore as stated **[here](<https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits#data-limits>):**
> >
> > > “The data (key value) is also stored as a string, regardless of its initial type. You can check the size of the data with the `JSONEncode()` function, which converts Luau data into a serialized JSON table.”
> 
> So as a type it would be defined like this: (**[ProfileStore.luau line 994](<ProfileStore.luau/#L994>)**)
> 
> ```lua
> type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer
> ```

**State A / Runtime**
> **The type of data/data structure that is used at Runtime, the only limit is your implementation.**

**State B / Datastore**
> **The type of data/data structure that lives in the Datastore, limited to JSON Acceptable types**

**State C / Roblox**
> **The type of data/data structure that should be returned by Custom DeepCopy callback, it is highly recommended, that if your State A uses metatables, you limit it to only return clean Roblox tables containing only the actual Data, without metadata or metatables;**
>
> **Otherwise the memory used for storing and Decoding might get messy - up to you.**
>
> **This is a type of data/data structure, that isn't limited to JSON Acceptable types only, but is defined by you.**
>
> **Note: DeepCopy callback might receive both State A and State C as input, but must always output State C**
>
> **Note 2: If your use case is only making sure the data transitions from State B to State A on Load and State A to State B on Upload, you really don't have any differences between State C and State A; Thus meaning DeepCopy, Reconcile and RuntimeWrapper callbacks are useless for you.**

---

## Practical Working Example
To showcase how useful this can get, we got **[CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)** **[(V1.0.2)](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vCoffeeParser/1.0.2>)** and wired it into ProfileStore, using the V2 modifications, this was possible with just less than 90 lines of code - **[ModifyWithCoffeeParser.luau](<server/ModifyWithCoffeeParser.luau>)** then used this in **[ProfileStoreTest (line 183)](<ProfileStoreTest.server.luau/#L183>)**

<details>
  <summary>All tests passed!</summary>

  ## [PS_TEST]: Test complete! PASS ✅ = 13; FAIL ❌ = 0
  ## [PS_TEST]: Test Timestamps: 
  |	Test Name (✅/❌)                                       	|	Absolute time()	|	Relative time()	|
  |------------------------------------------------------------|-----------------|-----------------|
  |	Script Started (✅)                                    	|	0.000          	|	none           	|
  |	[PS_TEST]: Versioning test(✅)                         	|	2.208          	|	2.208          	|
  |	[PS_TEST]: Payload test(✅)                            	|	14.025         	|	11.817         	|
  |	[PS_TEST]: DataStore KeyInfo (Roblox Metadata) test(✅)	|	15.058         	|	1.033          	|
  |	[PS_TEST]: Message test(✅)                            	|	20.458         	|	5.400          	|
  |	[PS_TEST]: LastSavedData test(✅)                      	|	32.392         	|	11.933         	|
  |	[PS_TEST]: .OnOverwrite test(✅)                       	|	33.725         	|	1.333          	|
  |	[PS_TEST]: Test #1(✅)                                 	|	35.808         	|	2.083          	|
  |	[PS_TEST]: Test #2(✅)                                 	|	38.475         	|	2.667          	|
  |	[PS_TEST]: Test #3(✅)                                 	|	39.592         	|	1.117          	|
  |	[PS_TEST]: Test #4(✅)                                 	|	51.125         	|	11.533         	|
  |	[PS_TEST]: Test #5(✅)                                 	|	62.542         	|	11.417         	|
  |	[PS_TEST]: Test #6(✅)                                 	|	63.558         	|	1.017          	|
  |	[PS_TEST]: Cache test(✅)                              	|	66.592         	|	3.033          	|
  ## [PS_TEST]: Test PASSED ✅✅✅!

</details>

With this setup, it is possible to store and manipulate Roblox Datatypes at Runtime, whilst CoffeeParser and ProfileStoreV2 make sure they'll be saved in JSON Acceptable way (every Datatype handled by the HTTPService:JSONEncode)



# Changes made to ProfileStore

### Every ProfileStore Object now has Custom Callbacks for easy Data flow customization
- By default there are no modifications, ProfileStore works just the same as in it's original version. All of the custom callbacks are nil, therefore not used and do not apply any changes to the usual data flow.
    **[defined in lines 1389-1395 in ProfileStore.luau](<ProfileStore.luau/#L1389-1395>):**

    ```lua
    custom_callbacks = {
		DeepCopyTable = nil,
		ReconcileTable = nil,
		Decode = nil,
		Encode = nil,
		RuntimeWrapper = nil,
	},
    ```

    Each of the callbacks can be set using the new methods on ProfileStore Object

### New Methods for ProfileStore objects (All chainable)
- **:SetDeepCopyTableCallback(callback)**
    Sets the custom Deep Copy callback; Returns self.
    
    Your callback will receive State A or State C input and must output State C

    The <strong>callback</strong> will be called in many cases with a table Profile.Data (from the Datastore, but not limited to), must return a copy of that table (usually modified copying)
- **:SetReconcileTableCallback(callback)**
    Sets the custom Reconcile callback; Returns self.

    This one is only ever used when calling **Profile:Reconcile** on Profile objects created via this ProfileStore Object.

    The <strong>callback</strong> will be called at Profile:Reconcile() with ``( target: Profile.Data (Decoded; State A or State C), template: ProfileStore.Template | Profile.ProfileStore.Template (Can be any of the states A, B and C or also a hybrid - the handler is in your hands), profile: Profile<T> ["usually unnecessary/unused, so it was marked with ? to silence the type checker when you leave this unused"] ) -> nothing, but mutate the target to State A``
- **:SetDecodeCallback(callback)**
    Sets the custom Decode callback; Returns self.

    The <strong>callback</strong> will be called at the start of transform_function with Profile.Data (from the Datastore), if there was any saved;
    It will also be called at the start of Profile.New().

    Decode(State B) -> State C
- **:SetEncodeCallback(callback)** 
    Sets the custom Encode callback; Returns self.

    The <strong>callback</strong> will be called at the end of transform_function with Profile.Data (after it has been Decoded by the custom Decode callback set using SetDecodeCallback method), before it's returned back into DataStore
    
    Encode(State C) -> State B
- **:SetRuntimeWrapperCallback(callback)**
    Sets the custom Runtime Overwrite handler callback; Returns self.

    The callback will be executed whenever Profile.Data is manually overwritten at runtime.

    This does happen in the test cases! In an example with CoffeeParser this is not necessary.

    However more complex systems might need this.

    RuntimeWrapper(table that Can be any of the states A, B and C or also a hybrid - the handler is in your hands) -> State A


### Methods usage summary:
```lua
-- the types StateA, StateB and StateC are not defined anywhere
-- they are here solely for the looks of the example

local Store = ProfileStore.New("StoreName", {--[[data template]]})
    :SetDeepCopyTableCallback(function(t: (StateA | StateC)): StateC
        local copy : StateC = {}
        -- do your DeepCopy process
        return copy -- return as State C
    end)
    :SetReconcileTableCallback(function(
        target: (StateA | StateC), -- the table to mutate (make changes to) into StateA
        template: (StateA | StateB | StateC | any), -- truly your input of the [[data template]]
        profile -- : ProfileStore.Profile<[[data template]]> -- can be commented out
        -- why is it (profile) here? - Used internally to ensure custom DeepCopyTable callback is used
    )
        -- mutate target to contain all keys from template, that it doesn't have yet
        -- return nothing
    end)
    :SetDecodeCallback(function(data: StateB): StateC
        local result = {}
        -- do your Decoding process
        return result -- return as State C
    end)
    :SetEncodeCallback(function(data: StateC): StateB
        local result = {}
        -- do your Encoding process
        return result -- return as State B
    end)
    :SetRuntimeWrapperCallback(function(data: (StateA | StateB | StateC | any)): StateA
        local result = {}
        -- implement your own rules on what happens whenever Profile.Data is overwritten as a whole
        return result -- return as State A
    end)
```

### Every Profile object now doesn't have ["Data"] field directly

``Profile.__index`` was changed and ``Profile.__newindex`` added.

Profile Objects work just the way they did before, no new methods. The `Data` is now actually stored as `_Data`, however no changes to the code are needed, since per request of `Data` you'd end up receiving `_Data`. This change was only needed to implement Runtime Wrapper Callback functionalities, since `__newindex` only fires when the assigned key doesn't exist yet.

### ProfileStore object creation has two new additional params
```lua
-- learn more about datastores here:
-- https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching
--[=[-- quotes from the link above:

>   ⚠️ For new experiences, use listing and prefixes to organize keys in your data
>   store instead of the legacy scopes feature. For existing experiences that use
>   scopes, continue using them.

>   When you use the AllScopes property, ListKeysAsync() returns every key with their
>   scope as the prefix argument, such as global/player_data_1234 or houses/house3.
>   Remember that the default scope is global.

    Personal advice by Coffilhg:
    
    Not using scopes means you will be using the Key name to fit both your scope the key,
    that means you have only 50 characters to fit scope + key.
    Also when listing with `DataStoreOptions.AllScopes = true` and DataStore:ListKeysAsync()
    you'll see the following format `global/{your custom scope}{key}`

    Using specific scopes is not recommended by Roblox, as stated in the quote, I believe this is
    because that'd mean you need to get your DataStore in multiple Instances, e.g.
    local MyDatastoreWithScopeA = ProfileStore.New("MyDatastore", {--[[data template]]}, "ScopeA")
    local MyDatastoreWithScopeB = ProfileStore.New("MyDatastore", {--[[data template]]}, "ScopeB")
    Now you have 50 characters for the scope and 50 characters for the key and the scopes aren't
    messed up to be in the `global/{your custom scope}{key}` format, but there's a better way.

    You can do the following:
    local MyDatastoreWithAllScopes = ProfileStore.New("MyDatastore", {--[[data template]]}, nil, true)
    then whenever writing keys, do it using the `{scope}/{key}` format for your keys, Roblox then
    handles scope and key separately, this way you have 50 characters for both scope and the key
    later you can do :ListKeysAsync(`{scope}`) or
    DataStoreService:GetDataStore("MyDatastore", `{scope}`):ListKeysAsync()
    this would be the best, merged approach

    Check out
    other/DatastoreScopesListing.luau in this repository
    to test this yourself

    read more about the limits here:
    https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits#data-limits


--]=]--


-- highlights:
function ProfileStore.New(store_name, template, scope, allScopes)
    -- original code from ProfileService

    local options = Instance.new("DataStoreOptions")
	options:SetExperimentalFeatures({v2 = true})
	options.AllScopes = not not allScopes

	local effectiveScope = nil
	if options.AllScopes == true then
		effectiveScope = ""
	elseif type(scope) == `string` then
		effectiveScope = scope
	end

    -- original code from ProfileService

    self.data_store = DataStoreService:GetDataStore(store_name, effectiveScope, options)
```

---

# The original README Contents:

# MAD STUDIO - ProfileStore

ProfileStore is a Roblox DataStore wrapper that streamlines auto-saving, session locking and a few other features for the game developer. ProfileStore's source code runs on a single ModuleScript.

If you want to save time writing code for player data caching or want to prevent item "duping" in a game with trading - this can be a helpful resource!

💲💲💲 *Consider [donating R$ to the creator of ProfileStore (Click here)](https://www.roblox.com/games/103946622805308/MAD-STUDIO-Open-Source-Donations) if you find this resource helpful!*

## How does it work?

ProfileStore loads and caches data from a DataStore key on a single Roblox game server and prevents other game servers from accessing this data too soon by establishing a session lock and handling session lock conflicts between servers swiftly all while not using too many DataStore and MessagingService API calls.

Data units saved by ProfileStore are called **"profiles"** which can be accessed in-game by starting a **"session"**. During an active session you gain access to a table ([`Profile.Data`](/ProfileStore/api/#data)) which will either be saved to the DataStore on the next auto-save or when you manually end the session.

ProfileStore is primarily **player-data-oriented** and, by design, tweaked for a common use case where each game player would have a single profile dedicated to storing their game progress. Session locking addresses the issue of data access from more than one game server (which can cause item "dupes" in games with trading) by keeping track of which game server is currently caching data and gracefully switches ownership from one server to the other without failing new session requests. ProfileStore can still be used for non-player data storage, although ProfileStore's session locking is not ideal for quick writing from several game servers.

ProfileStore's module functions try to resemble the Roblox API for a sense of familiarity to Roblox developers. Methods with the `Async` keyword yield until a result is ready (e.g. `:StartSessionAsync()`), while others do not.

**ProfileStore is not designed (and never will be) for in-game leaderboards or any kind of global state.**

---

*Developed by [loleris](https://x.com/lolerismad)*

***See documentation:***
**[ProfileStore wiki](https://madstudioroblox.github.io/ProfileStore/)**

***Get it now on:***
[Roblox library](https://create.roblox.com/store/asset/109379033046155/ProfileStore)

If you need help integrating ProfileStore into your project, [join the discussion on the Roblox forums (Click here)](https://devforum.roblox.com/t/profilestore/3190543).