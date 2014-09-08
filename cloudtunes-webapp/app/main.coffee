pubsub = require 'pubsub'
Application = require 'application'
Backbone = require 'backbone'


window.WEB_SOCKET_DEBUG = yes
window.WEB_SOCKET_SWF_LOCATION = '/static/socketio/WebSocketMain.swf'


window.soundManager.setup
    url: '/static/soundmanager/'
    onready: ->
        #console.log 'soundManager ready'


Backbone.urlRoot = '/api/'


if window.location.hash == '#_=_'
    # FB <http://stackoverflow.com/questions/7131909/facebook-callback-appends-to-return-url>
    window.location.hash = ''
    history.pushState('', document.title, window.location.pathname)

$ ->
    app = new Application()
    window.app = app
    app.initialize()
