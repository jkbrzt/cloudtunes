pubsub = require 'pubsub'
{View} = require 'mvc'

LazyRenderer = require 'views/ui/lazy_renderer'
{ColumnResizer} = require 'views/ui/resizer_views'
BaseLibraryListView = require 'views/playlists/base_list_view'


class TracksColumnResizer extends ColumnResizer

    className: 'resize-col'

    start: (e)->
        @$el.height(@getContextSize() + 'px')
        super(e)

    finish: (e)->
        @$el.height('')
        super(e)

    getLimits: ->
        minWidth = 45

        {prev, next} = @

        if prev
            min = prev.getCurrentAbsoluteValue() + minWidth
        else
            min = minWidth

        if next
            max = next.getCurrentAbsoluteValue() - minWidth
        else
            max = @getContextSize() - minWidth

        [min, max]


class ColumnsManagerView extends View

    initialize: (options)->
        super(options)
        @listenTo(@model, 'change:trackColumns', @render)
        @addResizers()

    addResizers: ->
        @resizers = []
        relativeX = 0
        for prevColWidth, i in @model.get('trackColumns')

            relativeX += prevColWidth
            view = new TracksColumnResizer
                context: @$el
                value: relativeX
                relative: yes

            @listenTo(view, 'resize', @handleColumnResized)

            view.$el.appendTo(@$('.head-wrap'))
            @resizers.push(view)
            @subview("resize-col-#{i}", view.render())

        for view, i in @resizers
            next = @resizers[i + 1]
            view.prev = prev
            view.next = next
            prev = view

    handleColumnResized: ->
        values = []
        prevColWidth = 0
        for x in _.pluck(@resizers, 'value')
            values.push(x - prevColWidth)
            prevColWidth = x

        @model.set
            trackColumns: values

    render: =>
        if not @$style
            @$style = $('<style id="tracks-cols" />').appendTo($('head'))
        css = '\n'

        total = 0
        for colWidth, i in @model.get('trackColumns')
            i += 1
            total += colWidth
            css += """
            #playlist .tracks td:nth-child(#{i}) {
                width: #{colWidth}% !important;
            }
            """

        css += """
        #playlist .tracks td:nth-child(#{i+1}) {
            width: #{100 - total }% !important;
        }
        """
        @$style.text(css)


class TracksLazyRenderer extends LazyRenderer

    makeRow: (track)->
        """
            <tr class="item" data-track="#{track.cid}" draggable="true">
                <td>#{ track.get('number') or ''}</td>
                <td>#{ _.escape track.get('title') }</td>
                <td>#{ _.escape track.get('artist') }</td>
                <td>#{ _.escape track.get('album') }</td>
            </tr>
        """


    makeTable: (range)->
        table = [
            "<table>"
        ]
        for i in range.iter()
            table.push(@makeRow(@collection[i]))
        table.push('</table>')
        table.join('')


class TracksSortingView extends View

    events:
        'mousedown td': 'sortBy'

    initialize: (options)->
        super options
        @listenTo(@model, 'change:sortBy change:ordering', @render)

    render: =>
        @$el.addClass('sorting-enabled')
        if not @_orig
            @_orig = @$el.attr('class')
        @$el.attr('class', "#{@_orig} order-#{@model.get('ordering')}")
        orderedByClass = 'sorted-by'
        @$(".#{orderedByClass}").removeClass(orderedByClass)
        @$("[data-order-field=#{ @model.get('sortBy') }]").addClass(orderedByClass)

        @

    sortBy: (e)=>
        $td = $(e.target)
        sortBy = $td.data('order-field')
        if sortBy == @model.get('sortBy')
            @model.toggleOrdering()
        else
            @model.set('sortBy', sortBy)


class TrackListView extends BaseLibraryListView

    namespace: 'track'
    className: 'playlist'

    initialize: (options)->
        super options

        @subview('columnsManager', new ColumnsManagerView({@model, @el}))

        if not options.disableSorting
            @subview('sorting', new TracksSortingView
                model: @model
                el: @$('.head')
            ).render()

        @listenTo(pubsub.player, 'change:track', @markPlayingItem)
        @listenTo(pubsub, 'select:artist select:album select:track', @select)

    remove: ->
        @renderer?.remove()
        super

    render: (sorting)=>
        if sorting
            # TODO: sorting is slow
            range = @renderer.getVisibleRange()

        @renderer?.remove()
        @renderer = new TracksLazyRenderer(@$body, @collection.getResult())
        @renderer.renderIntial(range)

        $headWrap = @$('.head-wrap')
        scrollbarWidth = @$el.width() - @$body[0].scrollWidth
        $headWrap.css('margin-right', scrollbarWidth + 'px')

        @select(@model.get('track'))
        @subview('columnsManager').render()

        delete @$playing
        @markPlayingItem()

        @

    renderFresh: ->
        @render(no)

    renderOnPosition: ->
        @render(yes)

    updatePlayingTrack: ->

    mousedown: (e)=>
        $item = $(e.currentTarget)
        @selectItem($item)
        # FIXME: track might not be in library
        track = @model.library.get($item.data('track'))
        @model.set(track: track)

    getDragged: ->
        # FIXME: track might not be in library
        cid = @$selectedItem.data('track')
        [_.findWhere(@collection.getTracks(), {cid})]
#        [@model.library.get()]

    select: (track)=>
#        if track and track.cid is @$selectedItem?.data('track')
#            return
        $item = track and @getTrackItem(track)
        if not $item
            $item = @$body.find('.item:first')
        @selectItem($item)

    getTrackItem: (track)->
        $item = @$body.find("[data-track='#{track.cid}']:first")
        if $item.length
            $item

    handlePlay: (e)->
        $item = $(e.currentTarget)
        @selectItem($item)
        cid = $item.data('track')
        @play(cid)

    addItem: (track, index)->
        @renderer.addItem(track, index)

    removeItem: (track, index)->
        @renderer.removeItem(track, index)

    changeItem: (track, index)->
        @renderer.changeItem(track, index)

    markPlayingItem: =>
        # TODO: distinguish between playing/paused. Maybe ask the queue for current.
        className = 'playing'
        track = pubsub.player.get('track')

        if track and @$playing and track.cid is @$playing.data('track')
            return

        if @$playing
            @$playing.removeClass(className)
            delete @$playing

        if not track
            return

        @$playing = @getTrackItem(track)
        @$playing?.addClass(className)


module.exports = TrackListView
