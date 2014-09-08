{View} = require 'mvc'
pubsub = require 'pubsub'


TAB = 9
UP = 38
DOWN = 40


handleTab = (e)->

    curr = _.indexOf(FocusContextView.instances, FocusContextView.focused)
    last = FocusContextView.instances.length - 1

    if not e.shiftKey
        next = if curr is last then 0 else curr + 1
    else
        next = if curr <= 0 then last else curr - 1
    $(':focus').blur()
    pubsub.publish('focuscontext:focus', FocusContextView.instances[next])

    no


$(document).on 'keydown', (e)->
    switch e.keyCode
        when TAB then handleTab e
        when UP then FocusContextView.focused?.selectPrevItem()
        when DOWN then FocusContextView.focused?.selectNextItem()
        else return yes
    e.preventDefault()
    no


class FocusContextView extends View

    @instances: []
    @focused: null

    events:
        'mousedown': 'handleMousedown'

    constructor: (options)->
        if not options.el
            options.el = options.delegate.el
        super options

    initialize: (options)->

        super options

        console.log 'XXX', @el

        FocusContextView.instances.push(@)

        @$el.addClass('focuscontext')

        @listenTo pubsub, 'focuscontext:focus', (view)=>
            if view is @
                @focus()
            else
                @blur()

    handleMousedown: (e)->
        pubsub.publish('focuscontext:focus', @)

    focus: =>
        FocusContextView.focused = @
        @$el.addClass('focused')

    blur: =>
        @$el.removeClass('focused')

    isFocused: =>
        @$el.hasClass('focused')

    remove: =>
        FocusContextView.instances = _.without(FocusContextView.instances, @)
        if @isFocused()
            FocusContextView.focused = null
        super()

    # Subclass methods
    selectNextItem: =>
        @options.delegate.selectNextItem()

    selectPrevItem: =>
        @options.delegate.selectPrevItem()


module.exports = FocusContextView
