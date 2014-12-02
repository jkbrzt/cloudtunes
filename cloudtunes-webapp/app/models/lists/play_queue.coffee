Backbone = require 'backbone'
_ = require 'underscore'

class PlayQueue

    _.extend @::, Backbone.Events

    constructor: ->
        @tracks = []
        @clear()

    len: ->
        @tracks.length

    getCurrent: ->
        @tracks[@index]

    setCurrent: (track)->
        index = _.indexOf(@tracks, track)
        if index is -1
            throw 'Track not in queue!'
        @index = index

    hasNext: ->
        @len() and @len() > @index + 1

    hasPrev: ->
        @index > 0

    next: ->
        if @hasNext()
            @tracks[++@index]

    prev: ->
        if @hasPrev()
            @tracks[--@index]

    rewind: ->
        @index = 0

    clear: (options=silent:no)->
        @rewind()
        @tracks.length = 0
        if not options.silent
            @trigger('reset')

    replace: (tracks)->
        @clear(silent: yes)
        @add(tracks)
        @trigger('reset')

    add: (tracks)->
        Array::push.apply(@tracks, tracks)
        @trigger('reset')

    remove: (tracks)->

    move: (track, atIndex)->
        console.log 'moving', track.get('title'), 'to', atIndex

        fromIndex = _.indexOf(@tracks, track)

        if fromIndex is -1
            throw 'cannot move track; not in queue'

        if fromIndex is atIndex
            console.log 'no change'
            return

        # Remove
        @tracks.splice(fromIndex, 1)

        if fromIndex < atIndex
            atIndex -= 1

        # Insert
        console.log '@tracks.splice(', atIndex, '0', track, ')'
        @tracks.splice(atIndex, 0, track)


        @trigger('reset')

    # TrackList interface
    getTracks: ->
        [].concat(@tracks)

    getResult: ->
        @getTracks()


module.exports = PlayQueue

