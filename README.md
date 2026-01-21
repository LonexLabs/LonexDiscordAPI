# LonexDiscordAPI

**LonexDiscordAPI** is a powerful, high-performance Discord integration library for FiveM servers.  
It provides seamless Discord role syncing, permissions, webhooks, and player data access — all designed to be fast, reliable, and developer-friendly.

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
  Sync Discord roles to FiveM ACE permissions on player join
- **Role Inheritance**  
  Example:
  - VIP → inherits Member permissions  
  - Admin → inherits Moderator permissions
- **Wildcard Support**  
  `command.*` grants access to all command permissions
- **Priority System**  
  Higher priority roles override lower priority ones

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

---

## 📚 Documentation

Full documentation is available here:  
👉 **https://docs.lonexlabs.com/free/lonexdiscordapi**

The documentation includes:
- Installation & setup
- Bot configuration
- Permission & role examples
- Webhook usage
- API & export reference

---

## 🚀 Use Cases
- Discord-based staff permissions
- VIP & role-based features
- Automatic Discord ↔ FiveM syncing
- Advanced logging and moderation tools
- Cross-resource Discord integration

---

## 📄 License
This project is provided by **LonexLabs**.  
Please refer to the repository license for usage terms.

---

## ❤️ Credits
Developed and maintained by **LonexLabs**  
Built for performance, reliability, and ease of use.
