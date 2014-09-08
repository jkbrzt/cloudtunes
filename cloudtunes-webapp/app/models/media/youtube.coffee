{Model} = require 'mvc'
Medium = require 'models/media/base'


class Video extends Medium

    initialize: ->
        @player = player

    stop: ->
        @player.off null, null, @
        @player.stop()

    play: ->
        @player.on 'change:state', =>
            if @player.get('state') is @player.ENDED
                @trigger('finish')
        , @

        @player.on 'change:position', (@player, position)=>
            @set('position', position)
        , @

        @player.on 'change:loaded', (@player, loaded)=>
            @set('loaded', loaded)
        , @

        @player.play(@get('track').get('source_id'))

    pause: ->
        @player.pause()

    paused: ->
        @player.paused()

    resume: ->
        @player.resume()

    setVolume: (volume)->
        @player.setVolume(volume)

    setPosition: (position)->
        @player.setPosition(position)


class YouTubePlayer extends Model

    id: 'youtube-player'

    UNSTARTED: -1
    ENDED: 0
    PLAYING: 1
    PAUSED: 2
    BUFFERING: 3
    VIDEO_CUED: 5

    # Custom
    INITIALIZING: 11
    READY: 12
    ERROR: 13

    defaults:
        state: @::INITIALIZING
        error: ''
        position: 0
        loaded: 0

    initialize: ->
        $("<div id='#{@id}'></div>").appendTo($('#medium'))

        window.youtubePlayer = @
        window.onYouTubePlayerReady = @playerReady

        # http://code.google.com/p/swfobject/wiki/api
        options =
            url: 'http://www.youtube.com/apiplayer?enablejsapi=1&version=3'
            id: @id
            width: '150'
            height: '150'
            version: '8'
            xiUrl: null
            flashVars: null
            params:
                allowScriptAccess: 'always'
            attributes: null
            callback: @swfReady

        swfobject.embedSWF(
            options.url
            options.id
            options.width
            options.height
            options.version
            options.xiUrl
            options.flashVars
            options.params
            options.attributes
            options.callback
        )

    player: ->

    swfReady: (result)->
        if not result.success
            alert 'YouTube player failed to load'
            return
        result.ref.style.visibility = 'hidden'

    playerReady: =>
        player = document.getElementById @id
        @set state: @READY

        player.addEventListener 'onStateChange', 'youtubePlayer.handleStateChanged'
        player.addEventListener 'onError', 'youtubePlayer.handleError'

        @player = ->
            # We cannot assign player to @, otherwise the hell breaks loose
            # in Chrome 22.0.1229.79
            player

        if @autoplay
            @play()
        if @autovolume
            @setVolume @autovolume

    handleStateChanged: (state)=>
        window.clearInterval @timer
        if state == @BUFFERING or state == @PLAYING
            @timer = window.setInterval(@reportProgress, 1000)
        @set('state', state)

    reportProgress: =>
        @set
            position: (@player().getCurrentTime() / @player().getDuration()) * 100
            loaded: @player().getVideoLoadedFraction() * 100

    handleError: (code)=>
        error = switch code
            when 2
                'request contains an invalid parameter'
            when 100
                'the video requested was not found'
            when 101, 150
                'the video requested does not allow playback in the embedded players'
            else
                'unknown error'

        @set
            state: @ERROR
            error: error

    stop: ->
        @player().style.visibility = 'hidden'
        @player().stopVideo()

    play: (id)->
        console.log 'playing ', id
        @player().style.visibility = 'visible'
        if not @player()
            @autoplay = yes
        else
            @player().loadVideoById(id)

    pause: ->
        @player().pauseVideo()

    paused: ->
        @player().getPlayerState() is @PAUSED

    resume: ->
        @player().playVideo()

    setVolume: (volume)->
        if @player()
            @player().setVolume volume
        else
            @autovolume = volume

    setPosition: (position)->
        return if not @player()
        duration = @player().getDuration()
        return 0 if duration is 0
        @player().seekTo (duration / 100) * position, yes


player = new YouTubePlayer()


module.exports = Video
