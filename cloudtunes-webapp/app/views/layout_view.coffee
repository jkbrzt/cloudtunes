pubsub = require 'pubsub'
{View} = require 'mvc'
{ColumnResizer, RightBoundColumnResizer} = require 'views/ui/resizer_views'
template = require 'templates/layout'


class Layout extends View

    template: template

    events:
        'click a': 'handleLinkClicked'

    initialize: ->
        super

        @listenTo(pubsub.navSidebar, 'change:width', @setNavSidebarWidth)
        @listenTo(pubsub.infoSidebar, 'change:width', @setInfoSidebarWidth)
        $(window).on('resize', @setPageHeight)

    render: ->
        super
        @setPageHeight()
        @setNavSidebarWidth()
        @setInfoSidebarWidth()
        @addNavSidebarResizer()
        @addInfoSidebarResizer()

    addNavSidebarResizer: ->
        resizer = @subview 'sidebar-resizer', new ColumnResizer
            el: $ '.resize-nav-sidebar'
            context: @$el
            value: pubsub.navSidebar.get('width')
            relative: no
            min: 100
            max: 400

        resizer.render()
        @listenTo resizer, 'resize', (x)->
            pubsub.navSidebar.set(width: x)

    addInfoSidebarResizer: ->
        resizer = @subview 'sidebar-resizer', new RightBoundColumnResizer
            el: $ '.resize-info-sidebar'
            context: @$el
            value: pubsub.infoSidebar.get('width')
            relative: no
            min: 150
            max: 400

        resizer.render()
        @listenTo resizer, 'resize', (x)->
            pubsub.infoSidebar.set(width: x)

    setPageHeight: =>
        height = $(window).height()
        $('#page, #main').height(height)

    handleLinkClicked: (e)=>
        $a = $(e.currentTarget)
        if not $a.attr('target') and not $a.is('.external')
            e.preventDefault()
            e.stopPropagation()
            url = $a.attr 'href'
            Backbone.history.navigate(url, true)

    setNavSidebarWidth: ->
        $('#page').css('margin-left', pubsub.navSidebar.get('width') + 'px')

    setInfoSidebarWidth: ->
        $('#page').css('margin-right', pubsub.infoSidebar.get('width') + 'px')


module.exports = Layout
