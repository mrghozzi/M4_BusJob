fx_version 'cerulean'
game 'gta5'

author 'MrGhozzi'
description 'A QBCore bus job script with dynamic lines, GPS routing, in-bus dashboard, virtual passengers, financial rewards, and realistic depot interaction.'

version '1.5'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu'
}
