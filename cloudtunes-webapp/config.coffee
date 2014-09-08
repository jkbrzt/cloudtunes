###
Docs:

    https://github.com/brunch/brunch/blob/stable/docs/config.md

Defaults:

    https://github.com/brunch/brunch/blob/master/src/helpers.coffee#L197

###

exports.config =

#    conventions:
#        ignored: (path)->
#            ignore = path.indexOf('artials/_') > -1
#            console.log ignore, path
#            ignore
#            no

    paths:
        'public': 'build/development'

    plugins:
        sass:
            debug: 'comments'

    files:
        javascripts:
            joinTo:
                'cloudtunes.js': /^app/
                'vendor.js': /^vendor/
            order:
                # Files in `vendor` directories are compiled before other files
                # even if they aren't specified in order.before.
                before: [
                    'vendor/scripts/console-helper.js',
                    'vendor/scripts/jquery.js',
                    'vendor/scripts/underscore.js',
                    'vendor/scripts/backbone.js'
                ]
        stylesheets:
            joinTo: 'cloudtunes.css'
            order:
                before: [
                    'vendor/styles/normalize-1.0.0.css'
                ]
        templates:
            joinTo: 'cloudtunes.js'
