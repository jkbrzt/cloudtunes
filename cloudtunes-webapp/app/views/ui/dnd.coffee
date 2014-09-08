$ = require 'jquery'
{View} = require 'mvc'
pubsub = require 'pubsub'


class DraggableView extends View

    events: {}

    initialize: (options)->
        super options
        if not options.draggableSelector
            # Otherwise need to be set manually on $(options.draggableSelector)
            @$el.attr('draggable', 'true')
        @events["dragstart #{ options.draggableSelector or '' }"] = '_dragstart'
        @delegateEvents()

    getDragged: (e)->
        @options.delegate.getDragged(e)

    _dragstart: (e)->
        # if $(e.currentTarget).is('tr')
        #   TODO: drag table rows feedback image
        #   $(e.currentTarget).css('display', 'block')
        dragged = @getDragged(e)
        console.log('dragstart', dragged)
        pubsub._dragged = dragged


class DroppableView extends View
    ###
    Drop target view.

    Can be subclassed or a options.delegate provided.

    ###

    events: {}

    initialize: (options)->
        super options
        dragEvents =
            dragover: '_dragover'
            dragenter: '_dragenter'
            dragleave: '_dragleave'
            drop: '_drop'


        if options.droppableSelector
            events = {}
            for event, handler of dragEvents
                events["#{ event } #{ options.droppableSelector }"] = handler

            dragEvents = events

        _.extend @events, dragEvents
        @delegateEvents()

    drop: (dragged, e)=>
        @options.delegate.drop(dragged, e)

    draghover: (e)->
        # Init active droppzone UI
        $(e.currentTarget).addClass('draghover')
        @options.delegate?.draghover?(e)

    dragleave: (e)->
        # Cleanup inactive droppzone UI
        $(e.currentTarget).removeClass('draghover')
        @options.delegate?.dragleave?(e)

    _dragover: (e)->
        #console.log '_dragover', e
        @draghover(e)
        no

    _dragenter: (e)->
        #console.log '_dragenter', e
        @draghover(e)
        no

    _dragleave: (e)->
        #console.log '_dragleave', e
        @dragleave(e)
        no

    _drop: (e)->
        console.log '_drop', e

        dragged = pubsub._dragged
        pubsub._dragged = null

        if dragged.getDragged
            # Lazy/async dragged retrieval; can return a `Deferred`.
            dragged = dragged.getDragged()

        $.when(dragged).then (dragged)=>
            @drop(dragged, e)
            @dragleave(e)
        no


module.exports = {
    DraggableView
    DroppableView
}
