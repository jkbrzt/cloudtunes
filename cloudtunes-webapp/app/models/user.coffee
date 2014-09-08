_ = require 'underscore'
{Model} = require 'mvc'


class User extends Model

    url: '/api/user'
    isNew: -> no

    initialize: ->
        #@ioBind 'update', @serverChange

    serverChange: (data)->
        data = JSON.parse data
        @set data

    toJSON: ->
        _.pick(
            @attributes
            'email'
            'name'
            'picture'
            'username'
            'desktop_notifications'
            'confirm_exit'
            'location'
        )


module.exports = User
