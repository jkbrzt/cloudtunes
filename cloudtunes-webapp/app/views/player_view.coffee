pubsub = require 'pubsub'
{View} = require 'mvc'
SliderView = require 'views/ui/slider_view'
template = require 'templates/player'
trackTemplate = require 'templates/player_track'


class ButtonView extends View

    events:
        click: 'click'

    initialize: (options)->
        super options
        @listenTo(@model, 'change:state', @render)
        @listenTo(@model.queue, 'reset', @render)

    click: ->
        if @enabled()
            @action()

    render: ->
        if @activated()
            @$el.removeClass('inactive')
        else
            @$el.addClass('inactive')
        @

    activated: ->
        @enabled()

    enabled: ->
        yes


class RepeatButtonView extends ButtonView

    initialize: (options)->
        super options
        @listenTo(@model, 'change:repeat', @render)

    action: =>
        @model.set('repeat', not @model.get('repeat'))

    activated: ->
        @model.get('repeat')


class PrevButtonView extends ButtonView

    action: =>
        @model.prev()

    enabled: ->
        @model.queue.hasPrev()


class NextButtonView extends ButtonView

    action: =>
        @model.next()

    enabled: ->
        @model.queue.hasNext()


class PlayPauseButtonView extends ButtonView

    render: =>
        super()
        if @model.playing()
            @$el.removeClass('icon-play').addClass('icon-pause')
        else
            @$el.removeClass('icon-pause').addClass('icon-play')
        @

    action: =>
        @model.toggle()

    enabled: ->
        Boolean(@model.queue.len())




class VolumeView extends SliderView

    field: 'volume'


class VolumeWidgetView extends View

    events:
        'mouseover .button': 'open'
        'mouseout': 'unopen'

    initialize: (options)->
        super options
        @$popup = @$('.volume-popup')
        @listenTo(@model, 'change:volume', @render)

    open: =>
        @$el.removeClass('closed').addClass('open')

    unopen: (e)=>
        if not @$el.andSelf().find(e.relatedTarget).length
            @$popup.one('transitionend', @close)
            @$el.removeClass('open')

    close: =>
        @$el.addClass('closed')

    render: =>
        classes = [
            'icon-volume-off'
            'icon-volume-down'
            'icon-volume-up'
        ]
        [lo, mid, hi] = classes
        volume = @model.get('volume')

        className = if volume < 5
            lo
        else if volume < 60
            mid
        else
            hi

        console.log 'VOLUME:', volume, className

        @$('.volume-icon').removeClass(classes.join(' ')).addClass(className)
        @


class PositionView extends SliderView

    field: 'position'

    initialize: (options)->
        super options
        @$loaded = @$('.loaded')
        @listenTo @model, "change:loaded", (model, loaded)=>
            @$loaded.css('width', "#{loaded}%")



class TrackView extends View

    template: trackTemplate

    events:
        'click .artist': 'selectArtist'
        'click .album': 'selectAlbum'
        'click .title': 'selectTrack'

    initialize: (options)->
        super options
        @listenTo(@model, 'change:track', @render)

    getTemplateData: ->
        track: @model.get('track')?.toJSON() or {}

    selectArtist: =>
        pubsub.publish('select:artist', @model.get('track'))

    selectAlbum: =>
        pubsub.publish('select:album', @model.get('track'))

    selectTrack: =>
        pubsub.publish('select:track', @model.get('track'))


class PlayerView extends View

    template: template

    render: ->
        super
        subviews =
            prev: PrevButtonView
            next: NextButtonView
            toggle: PlayPauseButtonView
            repeat: RepeatButtonView
            volume: VolumeView
            position: PositionView
            track: TrackView
            'volume-widget': VolumeWidgetView

        for name, SubView of subviews
            el = @$ ".#{name}"
            @subview(name, new SubView({@model, el}).render())
        @

module.exports = PlayerView
