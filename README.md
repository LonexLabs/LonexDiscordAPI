# LonexDiscordAPI

**LonexDiscordAPI** is a powerful, high-performance Discord integration library for FiveM servers.  
It provides seamless Discord role syncing, permissions, webhooks, player data access, and server utilities — all designed to be fast, reliable, and developer-friendly.

[![Discord Banner 2](https://discord.com/api/guilds/1454578226700615815/widget.png?style=banner2)](https://discord.gg/LonexLabs)

---

## ✨ Key Features

### 🔗 Discord Integration
- **Player Lookup**  
  Retrieve Discord ID, username, avatar, and nickname for any connected player
- **Guild Data**  
  Fetch Discord server information, roles, and member counts

---

### 👥 Role System
- **Role Checking**  
  Check if players have specific Discord roles (by role ID)
- **Role Management**  
  Add or remove Discord roles directly from in-game
- **Audit Logging**  
  Optional logging for role changes
- **Nickname Sync**  
  Update Discord nicknames from in-game actions

---

### 🔐 Permission System
- **Automatic Role Sync**  
  Sync Discord roles to FiveM ACE permissions during player connection
- **vMenu & ACE Compatible**  
  Uses `identifier.discord:ID` format for full ACE inheritance support
- **Role Inheritance**  
  Example:
  - VIP → inherits Member permissions  
  - Admin → inherits Moderator permissions
- **Wildcard Support**  
  `command.*` grants access to all command permissions
- **Priority System**  
  Higher priority roles override lower priority ones
- **Weapon/Vehicle/Ped Restrictions**  
  Restrict weapons, vehicles, and ped models based on Discord roles

---

### 🏷️ Tags System
- **Head Tags**  
  Display role-based tags above players' heads
- **Chat Tags**  
  Role-based chat prefixes with color support
- **Voice Tags**  
  pma-voice integration for overhead voice indicators
- **NUI Menu**  
  Players can select their tag and toggle visibility via `/tags`

---

### 🚨 Emergency Calls (911/311)
- **911 & 311 Calls**  
  Players can request emergency assistance with location
- **Duty System**  
  Only on-duty players receive calls
- **Discord Integration**  
  Calls are logged to Discord channels
- **Response System**  
  Responders can set waypoints to caller locations with `/resp`

---

### 🎮 Server Utilities
- **AOP (Area of Play)**  
  Set and display the current roleplay area
- **PeaceTime**  
  Toggle PeaceTime with automatic weapon blocking and speed limit warnings
- **Announcements**  
  Server-wide on-screen announcements
- **Postals**  
  Navigate to postal codes with `/postal`
- **Server HUD**  
  Configurable HUD with compass, street, zone, postal, AOP, and player info

---

### 🛡️ Moderation Tools
- **Delete Vehicle**  
  Remove vehicles you're in or nearby with `/dv`
- **Delete All Vehicles**  
  Clear all unoccupied vehicles server-wide with countdown warning
- **Clear Chat**  
  Wipe server chat for all players
- **Role-Based Access**  
  All moderation commands can be restricted to specific Discord roles

---

### 📨 Webhook System
- **Send Messages & Embeds**  
  Post messages and rich embeds to Discord channels
- **Template System**  
  Pre-defined embed templates with `{placeholder}` replacement
- **Rate Limiting & Queuing**  
  Prevents Discord API bans
- **Named Webhooks**  
  Easily manage channels like `logs`, `admin`, `joins`, etc.

---

### ⚡ Performance
- **Smart Caching**  
  TTL-based cache with LRU eviction
- **Rate Limit Handling**  
  Automatic retry on Discord `429` responses
- **Request Queuing**  
  Ensures requests stay within Discord API limits

---

### 🛠️ Developer Friendly
- **60+ Exports**  
  Designed for use by other FiveM resources
- **Full API Documentation**  
  Includes detailed usage examples
- **Debug Commands**  
  Built-in commands for testing and troubleshooting
- **LuaDoc Annotations**  
  IDE auto-completion and inline documentation support
- **Badger_Discord_API Bridge**  
  Drop-in compatibility layer for existing scripts

---

## 📚 Documentation

Full documentation is available here:  
👉 **https://docs.lonexlabs.com/free/lonexdiscordapi**

The documentation includes:
- Installation & setup
- Bot configuration
- Permission & role examples
- Webhook usage
- Server utilities configuration
- Emergency calls setup
- Tags system customization
- API & export reference

---

## 🚀 Use Cases
- Discord-based staff permissions
- VIP & role-based features
- Automatic Discord ↔ FiveM syncing
- Advanced logging and moderation tools
- Cross-resource Discord integration
- Roleplay server utilities (AOP, PeaceTime, HUD)
- Emergency services dispatch system
- Player identification with head/chat tags

---

## 📋 Commands

### Player Commands
| Command | Description |
|---------|-------------|
| `/aop <zone>` | Set the Area of Play |
| `/peacetime` or `/pt` | Toggle PeaceTime |
| `/announce <message>` | Send server announcement |
| `/postal <code>` | Set waypoint to postal |
| `/togglehud` | Toggle HUD visibility |
| `/tags` | Open tag selection menu |
| `/911 <message>` | Send emergency call |
| `/311 <message>` | Send non-emergency call |
| `/resp <id>` | Respond to a call |
| `/duty` | Toggle duty status |

### Moderation Commands
| Command | Description |
|---------|-------------|
| `/dv` | Delete vehicle you're in or nearby |
| `/dvall` | Delete all unoccupied vehicles (20s countdown) |
| `/clearchat` | Clear server chat for all players |

### Console Commands
| Command | Description |
|---------|-------------|
| `lonex_roles` | List all configured role mappings |
| `lonex_syncall` | Manually sync all connected players |
| `lonex_debug_player <id>` | Full diagnostic for player permissions |

---

## 📄 License
This project is provided by **LonexLabs**.  
Please refer to the repository license for usage terms.

---

## ❤️ Credits
Developed and maintained by **LonexLabs**  
Built for performance, reliability, and ease of use.
