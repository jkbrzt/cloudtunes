Medium = require 'models/media/base'

class SoundMedium extends Medium

    initialize: ->
        super
        @sound = soundManager.createSound
            id: "t#{ @id }"
            url: @_getUrl()

            onfinish: =>
                @trigger('finish')

            whileplaying: _.throttle =>
                return if not @sound
                @set('position', @sound.position / @sound.durationEstimate * 100)

            , 1000

            whileloading: _.throttle =>
                return if not @sound
                @set('loaded', @sound.bytesLoaded / @sound.bytesTotal * 100)
            , 200


    _getUrl: ->
        throw 'not implemented'

    play: ->
        @sound.play()

    pause: ->
        @sound.pause()

    paused: ->
        @sound.paused

    resume: ->
        @sound.resume()

    stop: ->
        @sound.stop()
        soundManager.destroySound(@sound.id)
        delete @sound

    setVolume: (volume)->
        @sound.setVolume(volume)

    setPosition: (position)->
        @sound.setPosition(((@sound.durationEstimate / 100) * position))


class DropboxTrack extends SoundMedium

    _getUrl: ->
        "/dropbox/play/#{ @get('track').id }"


module.exports =
    DropboxTrack: DropboxTrack
