{View} = require 'mvc'


module.exports = class SliderView extends View

    events:
        'mousedown': 'start'

    initialize: (options)->
        super options
        @$pos = @$ '.pos'
        @$elapsed = @$ '.elapsed'
        @listenTo(@model, "change:#{@field}", @render)

    render: =>
        left = @positionFromValue()
        @$pos.css('left', "#{left}px")
        @$elapsed.css('width', "#{left + 4}px")
        @

    getBounds: ->
        width = @$el.width()
        positionWidth = @$pos.width()
        min = 0
        max = width - positionWidth
        {min, max, positionWidth}

    positionFromValue: ->
        {min, max} = @getBounds()
        (max - min) / 100 * @model[@field]()

    valueFromPosition: ->
        pos = parseInt(@$pos.css('left'), 10)
        {min, max} = @getBounds()
        Math.round((pos / (max - min)) * 100)

    start: (e)=>
        @$el.addClass('active')
        $(window).on('mousemove', @move)
        $(window).on('mouseup', @finish)
        @move(e)
        no

    positionFromEvent: (e)->
        {left} = @$el.offset()
        {min, max, positionWidth} = @getBounds()
        mouse = e.pageX - (positionWidth / 2)

        Math.max(min, Math.min(max, mouse - min - left))

    move: (e)=>
        left = @positionFromEvent(e)
        @$pos.css('left', "#{left}px")
        @$elapsed.css('width', "#{left + 4}px")
        @setValue()

    setValue: ->
        value = @valueFromPosition()
        @model[@field] value

    finish: (e)=>
        @$el.removeClass 'active'
        $(window).off('mousemove', @move)
        $(window).off('mouseup', @finish)
        @setValue()
