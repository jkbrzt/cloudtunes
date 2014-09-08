{View} = require 'mvc'


class Resizer extends View

    dimension: null
    cssProperty: null
    eventProperty: null

    events:
        'mousedown': 'start'

    initialize: (options)->
        super options
        @$context = options.context
        {@value, @relative} = options
        @render()

    start: (e)=>
        @$el.addClass('active')
        @saveEventValue(e)
        $(window).on('mousemove', @move)
        $(window).on('mouseup', @finish)
        no

    move: (e)=>
        prevEventValue = @eventValue
        @saveEventValue(e)
        [min, max] = @getLimits()
        value = @getCurrentAbsoluteValue() - (prevEventValue - @eventValue)
        if value < min
            value = min
        else if value > max
            value = max
        @$el.css(@cssProperty, value + 'px')

    finish: (e)=>
        @saveEventValue(e)
        @$el.removeClass 'active'
        $(window).off('mousemove', @move)
        $(window).off('mouseup', @finish)
        @commit()
        @eventValue = null

    commit: ->
        if @relative
            @value = (@getCurrentAbsoluteValue() / @getContextSize()) * 100
        else
            @value = @getCurrentAbsoluteValue()
        @render()
        @trigger('resize', @value)

    getCSSValue: ->
        @value + (if @relative then '%' else 'px')

    getLimits: ->
        min = if @options.min? then @options.min else 0

        if @options.max
            if @options.max < 0
                max = @getContextSize() + @options.max
            else
                max = @options.max
        else
            max = @getContextSize()

        [min, max]

    getContextSize: ->
        @$context[@dimension]()

    saveEventValue: (e)->
        @eventValue = e[@eventProperty]

    render: ->
        @$el.css(@cssProperty, @getCSSValue())
        @

    getCurrentAbsoluteValue: ->
        parseInt(@$el.css(@cssProperty), 10)


class ColumnResizer extends Resizer

    eventProperty: 'pageX'
    cssProperty: 'left'
    dimension: 'width'


class RightBoundColumnResizer extends Resizer

    eventProperty: null
    cssProperty: 'right'
    dimension: 'width'

    saveEventValue: (e)=>
        @eventValue = Math.abs(e.pageX - @getContextSize())


class RowResizer extends Resizer

    eventProperty: 'pageY'
    cssProperty: 'top'
    dimension: 'height'


module.exports = {
    ColumnResizer
    RightBoundColumnResizer
    RowResizer
}
