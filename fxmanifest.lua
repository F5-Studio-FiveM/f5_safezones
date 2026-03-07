fx_version 'cerulean'
game 'gta5'

author 'F5 Studio - https://f5stud.io'
description 'Advanced Safezone System with Zone Creation and Interactive Map'
version '2.1.1'

shared_scripts {
    'config.lua',
    'bridge/loader.lua',
    'shared/debug.lua',
    'shared/zone_creator.lua',
    'shared/circle_zone_creator.lua',
    'locales/*.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/client.lua',
    'client/zones.lua',
    'client/collision.lua',
    'client/ui.lua'
}
server_scripts {
    'server/version_check.lua',
    'bridge/server.lua',
    'server/logging.lua',
    'server/server.lua',
    'server/zones.lua',
    'server/players.lua',
    'server/admin.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/maps/*.png',
    'html/maps/*.jpg',
    'html/locales/*.json'
}

dependencies {
    '/server:4752',
    '/gameBuild:2189'
}

exports {
    'IsPlayerInSafezone',
    'GetCurrentSafezone',
    'GetAllZones',
    'IsPlayerInGhostMode',
    'GetPerformanceStats',
    'IsDebugModeActive',
    'GetLowestPointInZone',
    'GetCollisionEntities',
    'GetGhostedVehicles',
    'GetGhostedPlayers',
    'GetPlayersInCurrentZone'
}

server_exports {
    'IsPlayerInSafezone',
    'GetPlayerSafezoneInfo',
    'GetAllPlayersInSafezones',
    'GetAllSafezones',
    'GetPlayersInSpecificZone'
}

lua54 'yes'

ui_page_preload 'yes'
