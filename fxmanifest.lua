fx_version 'cerulean'
game 'gta5'

name 'cortex_soundtool'
author 'Cortex'
description 'Cortex Sound Tool — developer utility for browsing and testing GTA V sounds'
version '1.0.0'

shared_scripts {
    'config/config.lua',
    'config/vehicles.lua',
    'config/sounds.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/**/*',
    'config/sounds_database.json'
}
