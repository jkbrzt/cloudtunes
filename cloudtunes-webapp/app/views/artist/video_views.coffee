{View} = require 'mvc'
pubsub = require 'pubsub'
template = require 'templates/artist/video'
{DraggableView} = require 'views/ui/dnd'


class BaseVideoView extends DraggableView

    template: template
    tagName: 'article'
    className: 'video'

    events:
        click: 'play'

    initialize: (options)->
        super options
        @listenTo(pubsub.player, 'change:state', @setPlayingState)

    render: ->
        super()
        @setPlayingState()
        @

    setPlayingState: =>
        isPlaying = pubsub.player.get('track')?.get('source_id') is @model.id
        if isPlaying
            @$el.addClass('playing')
        else
            @$el.removeClass('playing')

    getDragged: ->
        [@model.toCloudtunesTrack()]



class AlbumTrackVideoView extends BaseVideoView

    play: ->
        track = @model.toCloudtunesTrack()
        pubsub.player.replaceQueue([track])
        pubsub.player.play()


class TopTrackVideoView extends BaseVideoView

    play: ->
        topTracks = @model.collection.mbartist.getLibraryTopTracks()
        pubsub.player.replaceQueue(topTracks)
        pubsub.player.play(@model.toCloudtunesTrack())


module.exports = {
    AlbumTrackVideoView,
    TopTrackVideoView
}
