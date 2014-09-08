{View} = require 'mvc'

class BaseSidebarView extends View

    initialize: (options)->
        super options
        @listenTo(@model, 'change:width', @setDimensions)
        $(window).on('resize', @setDimensions)
        @setDimensions()

    setDimensions: =>
        width = @model.get('width')
        @$el.width(width)


module.exports = BaseSidebarView
