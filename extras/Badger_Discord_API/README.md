# Badger_Discord_API Compatibility Bridge

This is a compatibility layer that allows existing scripts using `Badger_Discord_API` to work with `LonexDiscordAPI` without any code changes.

## Installation

1. **Install LonexDiscordAPI** and configure it with your bot token and guild ID
2. **Place this resource** in your resources folder (must be named `Badger_Discord_API`)
3. **Remove the original** Badger_Discord_API if you had it installed
4. **Update server.cfg:**

```cfg
# LonexDiscordAPI config
set lonex_discord_token "YOUR_BOT_TOKEN"
set lonex_discord_guild "YOUR_GUILD_ID"

# Start LonexDiscordAPI FIRST, then the bridge
ensure LonexDiscordAPI
ensure Badger_Discord_API
```

That's it! All existing scripts calling `exports.Badger_Discord_API` will now work automatically.

## Supported Functions

| Function | Status | Notes |
|----------|--------|-------|
| `GetDiscordRoles(user)` | ✅ | Returns array of role IDs |
| `GetDiscordName(user)` | ✅ | Returns Discord username |
| `GetDiscordNickname(user)` | ✅ | Returns server nickname |
| `GetDiscordAvatar(user)` | ✅ | Returns avatar URL |
| `GetDiscordEmail(user)` | ⚠️ | Requires email OAuth scope |
| `IsDiscordEmailVerified(user)` | ⚠️ | Requires email OAuth scope |
| `GetGuildName()` | ✅ | |
| `GetGuildDescription()` | ✅ | |
| `GetGuildIcon()` | ✅ | Returns icon URL |
| `GetGuildSplash()` | ✅ | Returns splash URL |
| `GetGuildMemberCount()` | ✅ | |
| `GetGuildOnlineMemberCount()` | ✅ | |
| `GetGuildRoleList()` | ✅ | Returns `{name = id}` table |
| `GetRoleIdFromRoleName(name)` | ✅ | |
| `CheckEqual(role1, role2)` | ✅ | Compares roles by name or ID |
| `SetNickname(user, nick)` | ✅ | |
| `AddRole(user, roleId)` | ✅ | |
| `RemoveRole(user, roleId)` | ✅ | |
| `SetRoles(user, roleList)` | ✅ | |
| `ChangeDiscordVoice(user, channelId)` | ❌ | Not implemented |

## Why Use This?

- **Zero code changes** - Existing scripts work as-is
- **Better performance** - LonexDiscordAPI has improved caching and rate limiting
- **More features** - Access LonexDiscordAPI's additional features in new scripts
- **Active development** - LonexDiscordAPI is actively maintained

## Migrating to LonexDiscordAPI

While this bridge works great, you may want to update your scripts to use LonexDiscordAPI directly for:
- Access to new features (weapon/vehicle/ped permissions, tags, etc.)
- Better error handling
- Cleaner async/await patterns

See the [LonexDiscordAPI documentation](https://github.com/LonexLabs/LonexDiscordAPI) for the full API reference.

## Troubleshooting

**"attempt to index a nil value"**
- Make sure LonexDiscordAPI is started BEFORE this bridge
- Check that LonexDiscordAPI is configured correctly

**Functions returning nil**
- Ensure the player has Discord linked to FiveM
- Check LonexDiscordAPI logs for API errors

**Email functions not working**
- Email requires special OAuth scopes that most servers don't have
- This is a Discord limitation, not a bridge issue
