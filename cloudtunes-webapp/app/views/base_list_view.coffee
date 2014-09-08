{View} = require 'mvc'
pubsub = require 'pubsub'
FocusContextView = require 'views/ui/focus_context_view'
{DraggableView} = require 'views/ui/dnd'


class BaseListView extends View

    events:
        'mousedown .item': 'mousedown'
        'dblclick .item': 'handlePlay'

    initialize: (options)->
        super options
        @$body = @getBody()
        @subview(new FocusContextView(
            delegate: @
            el: @$body
        ))

        @subview('draggable', new DraggableView(
            delegate: @,
            draggableSelector: '.item'
            el: @el,
        ))

    getBody: ->
        @$el

    render: ->
        super
        @$selectedItem = null
        @

    handlePlay: (e)=>
        @play()

    getTracks: ->
        throw 'not implemented'

    play: (cid=null)->
        # Allway use the current tracklist
        tracks = @getTracks()
        if cid
            # Start play from this track.
            track = _.findWhere(tracks, {cid})
        else
            # From the first track.
            track = null
        pubsub.player.replaceQueue(tracks)
        pubsub.player.play(track)

    mousedown: (e)->
        # select item, etc
        $item = $(e.currentTarget)
        @selectItem($item)

    getDragged: =>
        ###
        Return a list of tracks that should be dragged
        when an item in the list is dragged.

        ###
        throw 'not implemented'

    selectItem: ($item)->
        @$selectedItem?.removeClass('selected')

        if $item?.length
            $item.addClass('selected')
            @$selectedItem = $item

            height = @$body.height()
            posTop = $item.position().top
            if posTop < 0 or posTop > height
                @$body.scrollTop($item[0].offsetTop - (height / 2))

    focus: ->
        console.log 'FOCUS', @$selectedItem, @
        super
        if not @$selectedItem
            @selectItem(@$body.find('.item:first'))

    _navigate: (where)->
        switch where
            when 'next'
                $item = @$selectedItem.next('.item:first')
            when 'prev'
                $item = @$selectedItem.prev('.item:first')
            else
                throw 'no where ' + where
        return if not $item.length
        @selectItem $item

        window.clearTimeout @_timerSelectNextItem
        @_timerSelectNextItem = window.setTimeout ->
            $item.trigger('mousedown')
        , 200

    selectPrevItem: ->
        @_navigate('prev')

    selectNextItem: ->
        @_navigate('next')

    # NOT IMPLEMENTED here
    addItem: (track, index)->
    removeItem: (track, index)->
    changeItem: (track, index)->


module.exports = BaseListView
