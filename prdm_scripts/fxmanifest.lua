fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
games { 'gta5' }

name 'prdm_scripts'
version '0.1.0'
description 'Simple scripts to improve quality of life for development'
author 'i_Zolox'

client_scripts {
    'client/main.lua',
    'client/*.lua',
}

server_scripts {
    'server/main.lua',
    'server/*.lua',
}