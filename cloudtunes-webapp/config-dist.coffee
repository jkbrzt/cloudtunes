{config} = require './config.coffee'


config.sourceMaps = no
config.paths.public = 'build/production'
config.files.javascripts.joinTo = 'cloudtunes.js'

exports.config = config
