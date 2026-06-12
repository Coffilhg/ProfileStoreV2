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
> So as a type it would be defined like this: (**[ProfileStore.luau line 994](<ProfileStore.luau#994>)**)
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
> **Note: DeepCopy callback might receive both State A and  State C as input, but must always output State C**
>
> **Note 2: If your use case is only making sure the data transitions from State B to State A on Load and State A to State B on Upload, you really don't have any differences between State C and State A; Thus meaning DeepCopy, Reconcile and RuntimeWrapper callbacks are useless for you.**

---

## Practical Working Example
To showcase how useful this can get, we got **[CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)** **[(V1.0.2)](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vCoffeeParser/1.0.2>)** and wired it into ProfileStore, using the V2 modifications, this was possible with just less than 90 lines of code - **[ModifyWithCoffeeParser.luau](<server/ModifyWithCoffeeParser.luau>)** then used this in **[ProfileStoreTest (line 183)](<ProfileStoreTest.server.luau#183>)**

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