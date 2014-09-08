{Model} = require 'mvc'


missing = (name)->
    console.error "NotImplementedError #{name}"


class Medium extends Model

    defaults:
        position: 0
        loaded: 0
        track: null

    play: ->
        missing 'play'

    pause: ->
        missing 'pause'

    paused: ->
        missing 'paused'

    stop: ->
        missing 'stop'

    setVolume: ->
        missing 'setVolume'

    setPosition: ->
        missing 'setPosition'


module.exports = Medium
