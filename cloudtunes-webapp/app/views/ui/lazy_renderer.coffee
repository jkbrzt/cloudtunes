Backbone = require 'backbone'


class Range

    constructor: (@start, @end)->

    iter: ->
        _.range @start, @end

    toString: ->
        "[Range start=#{ @start } end=#{ @end }]"


module.exports = class LazyRenderer

    _.extend @::, Backbone.Events

    constructor: (@viewport, @collection)->

        @rowHeight = 25
        @initial = 100
        @extra = 50
        @map = new Array(@collection.length)
        @rendered = 0

        @update.debounced = _.debounce(@update, 200)

        @viewport.on('scroll', @update.debounced)
        $(window).on('resize', @update.debounced)

    remove: ->
        @viewport.html('')
        @disengage()

    disengage: =>
        @viewport.off('scroll', @update.debounced)
        $(window).off('resize', @update.debounced)

    renderIntial: (range)->
        if not range
            range = new Range(0, Math.min(@collection.length, @initial))

        if @collection.length
            @render(range)

    getVisibleRange: ->
        top = Math.floor(@viewport.scrollTop() / @rowHeight)
        visible = Math.ceil(@viewport.outerHeight() / @rowHeight)

        new Range top, Math.min(@collection.length, top + visible)

    update: =>

        visibleRange = @getVisibleRange()
        hotSpot = new Range(
            Math.max(0, visibleRange.start - @extra),
            Math.min(@collection.length, visibleRange.end + @extra)
        )

        @ensureRendered(hotSpot)

    ensureRendered: (range)->

        subranges = @getUnrenderedRanges(range)

        for subrange in subranges
            @render(subrange)

        if subranges.length
            @trigger('update')

    getUnrenderedRanges: (range)->
        subrange = null
        ranges = []
        for i in range.iter()
            if @map[i]
                if subrange
                    ranges.push(subrange)
                    subrange = null
            else if not subrange
                subrange = new Range(i, i + 1)
            else
                subrange.end += 1

        if subrange
            ranges.push(subrange)

        ranges

    render: (range)->

        for i in range.iter()
            @map[i] = 1
            @rendered++

        $table = $ @makeTable(range)
        gaps = @getGaps(range)

        if @rendered == @collection.length
            @disengage()

        # Gap before
        if range.start > 0

            preGapRowIndex = range.start - gaps.before
            sel = ".item[data-track=#{@collection[preGapRowIndex - 1].cid}]:first"
            preGapTable = @viewport.find(sel).parents('table:first')
            preGapTable.css('margin-bottom', '')

            if gaps.before
                $table.css('margin-top', "#{ @px(gaps.before) }px")

        # Gap after
        postGapRowIndex = range.end + gaps.after
        if postGapRowIndex != @collection.length
            sel = ".item[data-track=#{@collection[postGapRowIndex].cid}]:first"
            postGapRow = @viewport.find(sel).parents('table:first')
            postGapRow.css('margin-top', '')

        if gaps.after
            $table.css('margin-bottom', "#{ @px gaps.after }px")

        # Insert table
        if range.start == 0 or not preGapTable?.length
            @viewport.prepend($table)
        else
            preGapTable.after($table)

        #@validate()

    validate: ->
        expected = @px(@collection.length)
        actual = @viewport[0].scrollHeight
        if actual > @viewport.height()
            return
        msg = "expected=#{expected} actual=#{actual} "   +
              "expected == actual: #{expected == actual}"
        if expected isnt actual
            console.warn('invalid state: ' + msg)

    getGaps: (range)->
        before = 0
        after = 0

        i = range.start
        while --i >= 0 and not @map[i]
            before++

        i = range.end
        while not @map[i] and ++i <= @collection.length
            after++

        {before, after}

    px: (rows)->
        rows * @rowHeight

    makeTable: (range)->
        throw "#{@}: makeTable() not implemented"

    addItem: (track, index)->

        @map.splice(index, 0, null)

        visible = @getVisibleRange()

        if @map[index + 1]
            $row = $(@makeRow(track))
            next = @collection[index + 1]
            $next = @viewport.find(".item[data-track='#{next.cid}']:first")
            $($row).insertBefore($next)
            ++@rendered
            @map[index] = 1


        else if @map[index - 1]
            prev = @collection[index - 1]
            $prev = @viewport.find(".item[data-track='#{prev.cid}']:first")
            $row = $(@makeRow(track))
            $($row).insertAfter($prev)
            @map[index] = 1
            ++@rendered
            @viewport.scrollTop(@viewport.scrollTop() + @rowHeight)

        else if visible.start <= index <= visible.end
            @update()


    removeItem: (track, index)->
        rendered = @map[index]
        @map.splice(index, 1)
        if rendered
            $rendered = @viewport.find(".item[data-track='#{track.cid}']:first")
            $rendered.remove()
            --@rendered
        else
            # TODO: remove the height from somewhere
        @trigger('update')

    changeItem: (track, index)->
