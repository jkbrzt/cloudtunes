_ = require 'underscore'
Backbone = require 'backbone'


class Model extends Backbone.Model

    fetch: (options)->
        @_deferred = super options

    ensureFetched: (options)->
        if not @_deferred
            @fetch(options)

    toString: ->
        "[#{@constructor.name} '#{ @get('name') or @get('title')}]'"


class Collection extends Backbone.Collection

    fetch: (options)->
        @_deferred = super options

    ensureFetched: (options)->
        if not @_deferred
            @fetch(options)

class Controller


class View extends Backbone.View
    ###
    Garbage collection inspired by:
    <http://stackoverflow.com/questions/7567404>

    ###

    subviews: null
    subviewsByName: null
    container: null
    template: null

    constructor: (args...)->
        @subviews = []
        @subviewsByName = {}
        super(args...)

    subview: (name, view)=>
        if not view

            if name instanceof View
                view = name
                name = view.cid
            else
                return @subviewsByName[name]

        view.once('remove', @_forgetSubview)

        @subviews.push(view)
        @subviewsByName[name] = view
        view

    _forgetSubview: (view)=>
        # Forget the subview once it's been destroyed.
        @subviews = _.without(@subviews, view)
        delete @subviewsByName[name]

    remove: =>
        ###
        - Remove from DOM and unbind DOM events.
        - Remove all listeners bind on this view.
        - Remove all listeners on models this views binds to.
        - Recursivelly call on all `@subviews`

        ###
        @trigger('remove', @)
        super()
        @off()
        @removeSubviews()

    removeSubviews: ->
        for view in @subviews
            view.remove()
        @subviews.length = 0

    getTemplate: ->
        @template

    getTemplateData: ->
        if @model
            @model.toJSON()

    # Main render function
    # This method is bound to the instance in the constructor (see above)
    render: =>
        template = @getTemplate()
        if template
            @$el.html(template(@getTemplateData()))
        if @container
            $(@container).append(@el)
        @



class PageView extends View
    container: '#page'


module.exports = {
    Model
    View
    PageView
    Collection
    Controller
}
