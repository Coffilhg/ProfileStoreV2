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