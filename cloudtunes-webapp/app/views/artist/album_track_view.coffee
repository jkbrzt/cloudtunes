{DraggableView} = require 'views/ui/dnd'
pubsub = require 'pubsub'
template = require 'templates/artist/track'
VideoListView = require 'views/artist/video_list_view'
{AlbumTrackVideoView} = require 'views/artist/video_views'


class AlbumTrackView extends DraggableView

    className: 'track'
    template: template

    events:
        'click h4': 'toggleVideos'

    initialize: (options)->
        options = options or {}
        options.draggableSelector ?= 'h4'
        super(options)
        @listenTo(pubsub.player, 'change:state', @setPlayingState)

    setPlayingState: =>
        isPlaying = pubsub.player.get('track')?.equals(@model.toCloudtunesTrack())
        if isPlaying
            @$el.addClass('playing')
        else
            @$el.removeClass('playing')

    render: ->
        super()
        @setPlayingState()
        @

    getDragged: =>
        @model

    toggleVideos: =>

        $videos = @$('.videos')
        $videos.text('finding track…')
        $wrap = @$('.videos-wrap')

        if $wrap.hasClass('open')
            $wrap.removeClass('open')
            return

        $wrap.addClass('open')

        $.when(@model.videos.ensureFetched()).then =>
            $videos.width(@model.videos.length * 160)
            $videos.html('')
            @subview('videos', new VideoListView
                el: $videos
                collection: @model.videos
                VideoView: AlbumTrackVideoView
            ).render()


module.exports = AlbumTrackView
