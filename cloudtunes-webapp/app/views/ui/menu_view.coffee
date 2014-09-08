{View} = require 'mvc'
itemTemplate = require 'templates/ui/menu_item'


class MenuItemView extends View

    className: 'item'
    template: itemTemplate
    events:
        click: 'click'

    constructor: (options)->
        {@action} = options
        if @action.url
            @tagName = 'a'
            @attributes =
                href: @action.url
        super options

    click: ->
        console.log 'CLICKED', @
        @action.callback?()

    getTemplateData: ->
        @action


module.exports = class MenuView extends View

    initialize: (options)->
        super options
        {@actions} = options

    render: ->
        for id, action of @actions
            action = _.extend(id: id, action)
            view = @subview(new MenuItemView(action: action))
            @$el.append(view.render().el)
        @

    @fromMouseEvent: (e, options)->
        e.stopPropagation()
        view = new MenuView(options).render()

        $menu = $('#menu')
        $menu
            .append(view.el)
            .css(
                top: e.clientY  + 10
                left: e.clientX - ($menu.width() / 2)
            )
            .show()
            .addClass('open')

        $(document).one 'click', ->
            console.log 'REMOVEING'
            $menu.removeClass('open')
            $menu.one 'transitionend', ->
                view.remove()
                $menu.hide()

        view

