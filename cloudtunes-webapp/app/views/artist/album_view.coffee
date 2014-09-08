{View} = require 'mvc'
pubsub = require 'pubsub'
template = require 'templates/artist/album'
AlbumTrackView = require 'views/artist/album_track_view'
{DraggableView} = require 'views/ui/dnd'


class AlbumView extends DraggableView

    template: template
    tagName: 'article'
    className: 'album'
    events:
        'click h3': 'toggleAlbum'
        'click .play-all': 'playTracks'
        'click .add-all': 'addTracks'

    initialize: (options)->
        options = options or {}
        options.draggableSelector ?= 'h3'
        super options
        @listenTo(pubsub.player, 'change:state', @setPlayingState)

    render: ->
        super()
        @setPlayingState()
        @

    getDragged: ->
        @model


    setPlayingState: =>
        track = pubsub.player.get('track')
        if track and track.get('album_mbid') is @model.id
            @$el.addClass('playing')
        else
            @$el.removeClass('playing')

    toggleAlbum: ->

        $body = @$el.find('.body')

        if @$el.hasClass('open')
            @$el.removeClass('open')
            return

        @$el.addClass('open')

        $tracklist = @$el.find('.tracklist').text('loading tracklist…')

        $.when(@model.tracks.ensureFetched()).then =>
            $tracklist.text('')
            @model.tracks.each (track)=>
                view = new AlbumTrackView(model: track)
                @$el.find('.tracklist').append(
                    @subview('track-' + track.id, view).render().el)
            @$el.addClass('loaded')

    playTracks: ->
        @model.getCloudtunesTracks().done (tracks)->
            pubsub.player.replaceQueue(tracks)
            pubsub.player.play()

    addTracks: ->
        console.log 'addTracks'

module.exports = AlbumView
