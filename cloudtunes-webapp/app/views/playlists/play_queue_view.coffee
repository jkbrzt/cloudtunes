{View} = require 'mvc'
template = require 'templates/playlists/tracklist'
TrackListView = require 'views/playlists/track_list_view'
pubsub = require 'pubsub'
{DroppableView} = require 'views/ui/dnd'


class PlayQueueTrackListView extends TrackListView

    initialize: (options)->
        super options

        @subview('droppable', new DroppableView(
            delegate: @
            droppableSelector: '.item'
            el: @el
        ))


    play: (cid)->
        # No need to replace the Queue like in the base class.
        tracks = @model.getTrackList().getResult()  # ie., the play queue
        track = _.findWhere(tracks, {cid})
        pubsub.player.play(track)

    draghover: (e)->
        $item = $(e.currentTarget)
        cursor = e.originalEvent.offsetY
        mid = $item.height() / 2
        drop = if cursor < mid then 'above' else 'bellow'
        $item.removeClass('drop-bellow drop-above')
             .addClass("drop-#{ drop }")

    dragleave: (e)->
        #console.log '_dragleave', e
        $(e.currentTarget).removeClass('drop-bellow drop-above')

    drop: (dragged, e)->
        # Queue reordering.
        console.log 'PlayQueueTrackListView.drop', dragged, e
        $item = $(e.currentTarget)  # Item under cursor
        if not $item.data('track')
            # Not dropped on an item.
            # FIXME: we pass droppableSelector: '.item'; why it listens on @$el too?
            return
        tracks = @model.getTrackList().getResult()
        draggedOnto = _.findWhere(tracks, {cid: $item.data('track')})
        moveToIndex = _.indexOf(tracks, draggedOnto)
        console.log 'dragged onto', draggedOnto.get('title')

        if $item.hasClass('drop-above')
            moveTo = moveToIndex
        else if $item.hasClass('drop-bellow')
            moveTo = moveToIndex + 1
        else
            throw 'No drop-{above,bellow} class!'

        pubsub.player.queue.move(dragged[0], moveTo)


class PlayQueueView extends View

    template: template
    id: 'play-queue'
    className: 'flat-playlist-body playlist-body'

    render: =>
        super
        @subview(
            new PlayQueueTrackListView(
                model: @model
                el: @$('.tracks')
                disableSorting: yes
            )
        ).render()
        @



module.exports = PlayQueueView
