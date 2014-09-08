{View} = require 'mvc'
BaseSidebarView = require 'views/sidebars/base'


class InfoSidebarView extends BaseSidebarView

    initialize: (options)->
        super options

    setDimensions: =>
        super
        width = @model.get('width')
        @$('#medium').height(width)


module.exports = InfoSidebarView
