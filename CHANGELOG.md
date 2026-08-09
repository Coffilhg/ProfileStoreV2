# v2.0.3
- Optimized `SaveProfileAsync` to omit decoding the Data received from Profile Store
    `SaveProfileAsync`'s `transform_params.EditProfile` handler unconditionally does `latest_data.Data = profile.Data`, overwriting whatever `Decode` (if set) produces inside `UpdateAsync`' `transform_function`, which is expected. And `latest_data.Data` is not read anywhere across `SaveProfileAsync`, so the `Decode` is simply wasted work and can be safely omitted.

    <details>
    <summary>More Details:</summary>

    > `SaveProfileAsync` does not (and never did) read `loaded_data.Data` during the execution of `UpdateAsync` (fulfilling `transform_params`).
    >
    > `UpdateAsync`, however, would still use the Decode callback: `latest_data.Data = decode(latest_data.Data)` previously (if a decode callback was set)
    >
    > ...just for it to be overwritten by the `transform_params.EditProfile` handler
    >
    > To omit decoding the data from the datastore when it is not needed to (only the case for `SaveProfileAsync`)
    >
    > A fix similar to one in v2.0.1 (coincidentally with `SaveProfileAsync` too) was made,
    >
    > `UpdateAsync` now has yet another new optional parameter - `is_decode_ignored`
    >
    >
    >
    > One of the reasons to do it this way is that it is fast and easy, another, is that we don't try to infer the intent from existing arguments, which is quite troublesome, as seen here:
    > Function calling `UpdateAsync` -> passed argument value | `is_get_call` | `transform_params.EditProfile`
    > |-------------------------------------------------|---------------|-------------------------------|
    > `SaveProfileAsync` | `nil` | `function`
    > `StartSessionAsync` | empty (effectively `nil`) | `function`
    > `MessageAsync` | empty (effectively `nil`) | `function`
    > `GetAsync` | `true` | `nil`

    </details>
- `Profile:MessageHandler` is now consistent and uses the custom deep copy callback, if some was set. This should have been there since v2.0.0;
- Type definitions for custom callbacks were adjusted, because `{}` would require an empty table, whilst the original intent was to have a table in general, so it's now `{} | any`
- README changed, notable changes:
    > the Decode is more likely to end up returning StateA, not StateC as stated previously, if such distinction exists in your project. With that clarification you now don't need to analyze the complete flow of the data and wonder on how to achieve StateA.
    >
    > Whatever the Decode produces will be set as the `Profile.Data` in `Profile.New` (e.g. on session start `StartSessionAsync`)
    >
    > DeepCopy shall always return StateC. 
    >
    > Encode and Decode must be LOSSLESS, if this wasn't obvious previously.

# v2.0.2
- Cherry-Picked **[PR#22 ~ "Fix buffers being copied by reference in deep copies"](<https://github.com/MadStudioRoblox/ProfileStore/pull/22>)** from upstream.

# v2.0.1
- Improved `RuntimeWrapperCallback` - it is now called with `({} | any, profile: Profile<T>)` (previously it was just `({} | any)`);
    > `{} | any` is the value that is being written to profile.Data
    >
    > `profile: Profile<T>` is the profile to which that Data is being written to
    >
    > `RuntimeWrapperCallback` is fired whilst profile still has the old data; For example this way you could abort any profile.Data writes during Runtime (this is purely an example and not a recommended use case):
    > ```lua
    > local MyProfileStore: ProfileStore.ProfileStore<ProfileTemplate> = ProfileStore.New("Example", ProfileTemplate)
    >     :SetRuntimeWrapperCallback(function(value, profile)
    >         warn(`There was an attempt overwriting Profile.Data, aborted data:`, value)
    >         return profile.Data
    >     end)
    > ```
    > it would be more clean to have it fire as `(profile, value)`, but that wouldn't be backwards compatible, so it's `(value, profile)`
- `Profile.LastSavedData` would change over a Profile' lifetime previously. StateC via `Profile.New` at the start, then StateB (Datastore) after any save. Now it is consistently StateC. (If you have no difference between StateC and StateA, this effectively means that `Profile.LastSavedData` is always StateA)
- Patched passing invalid `deep_copy_table` to `MockUpdateAsync`
- Since the last release Roblox Type Checker has been changed, thus making it necessary to redundantly define the type of `profile_key` for all of `ProfileStore<T>` methods. For consistency a new type was created (`type profile_key = string`) and applied to types `ProfileStoreStandard<T>` and `ProfileStoreModule`. Whilst `profile_key` is used across the whole script, the type was only defined again for the following methods of `ProfileStore`:
    > StartSessionAsync
    >
    > MessageAsync
    >
    > GetAsync
    >
    > RemoveAsync
    >
    > VersionQuery

# v2.0.0
### This is the initial release of the Fork
**All details about changes made: [README.md at github.com/Coffilhg/ProfileStoreV2](<https://github.com/Coffilhg/ProfileStoreV2>)**