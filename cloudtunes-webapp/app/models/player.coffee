{Model} = require 'mvc'
pubsub = require 'pubsub'

{DROPBOX, YOUTUBE} = require 'source_ids'
{DropboxTrack} = require 'models/media/sound'
YoutubeVideo = require 'models/media/youtube'

PlayQueue = require 'models/lists/play_queue'


[PLAYING, PAUSED, STOPPED] = ['playing', 'paused', 'stopped']


mediaFactory = (track)->
    switch track.get('source')
        when DROPBOX then new DropboxTrack({track})
        when YOUTUBE then new YoutubeVideo({track})
        else throw 'Unknown source'


class Player extends Model

    defaults:
        repeat: no
        random: no
        state: STOPPED
        track: null
        volume: 50
        position: 0
        duration: 0
        loaded: 0
        playlist: null

    initialize: (attributes, options)->
        super attributes, options
        @queue = new PlayQueue

    state: (state=null)->
        if state
            @set('state', state)
        else
            @get('state')

    playing: (set)->
        @state(if set? then PLAYING else null) is PLAYING

    paused: (set)->
        @state(if set? then PAUSED else null) is PAUSED

    stopped: (set)->
        @state(if set? then STOPPED else null) is STOPPED

    volume: (volume)=>
        if volume?
            @set('volume', volume)
            @medium?.setVolume(volume)
        else
            @get('volume')

    position: (position, keep)=>
        if position?
            @set('position', position)
            if not keep
                @medium?.setPosition(position)
        else
            @get('position')

    play: (track=null)->
        @stop()
        if track
            @queue.setCurrent(track)
        else
            track = @queue.getCurrent()
        @medium = mediaFactory(track)

        @medium.on('finish', @next, @)
        @medium.on 'change:position', (medium, position)=>
            if medium is @medium
                @position position, yes
        , @
        @medium.on 'change:loaded', (medium, loaded)=>
            if medium is @medium
                @set 'loaded', loaded
        , @

        @medium.setVolume(@volume())

        @set
            track: track
            state: PLAYING
            position: 0
            loaded: 0

        @medium.play()

    stop: =>
        @stopped(yes)

        if @medium
            @medium.off(null, null, @)
            @medium.stop()
            delete @medium

    toggle: =>
        if not @medium
            track = @queue.getCurrent()
            @play(track)
        else if @medium.paused()
            @resume()
        else
            @pause()

    pause: =>
        @medium.pause()
        @paused yes

    resume: =>
        @playing yes
        @medium.resume()

    next: =>
        if @queue.hasNext()
            @play(@queue.next())
        else if @get('repeat')
            @queue.rewind()
            @play()
        else
            @stop()
            @queue.rewind()

    prev: =>
        track = @queue.prev()
        if track
            @play(track)
        else
            @stop()
            @queue.rewind()

    replaceQueue: (tracks)->
        @stop()
        @queue.replace(tracks)


module.exports = Player
