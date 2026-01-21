fx_version 'cerulean'
game 'gta5'

name 'LonexDiscordAPI'
author 'LonexLabs'
description 'Discord API integration for FiveM'
version '1.1.0'
repository 'https://github.com/LonexLabs/LonexDiscordAPI'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

server_scripts {
    'server/http.lua',
    'server/cache.lua',
    'server/api.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

-- Dependencies (optional, enhances functionality)
-- dependency 'ox_lib'

-- Exports are defined in server/main.lua via runtime registration
