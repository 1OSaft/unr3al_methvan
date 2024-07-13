fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author '1OSaft'
description 'Advanced methcar script'
version '2.1.3'

dependencies {'es_extended', 'ox_lib'}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'client_config.lua',
    'config_Hardcore.lua',
    'locales/*.lua',
}
client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/*.lua',
    'logs/config.log.lua'
}
