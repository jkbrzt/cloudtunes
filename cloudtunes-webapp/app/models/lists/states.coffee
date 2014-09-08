{Model} = require 'mvc'
_ = require 'underscore'


class Criteria extends Model
    ###
    Model that does filtering of collection of tracks.

    ###
    apply: (tracks)->
        ###
        Return filtered tracks.
        Similar to `_.where()`, but if looking for a list,
        we use `_.contains(q, val)`

        ###
        if @hasRules()
            tracks = _.filter(tracks, @matches)
        tracks

    matches: (track)=>
        for attname, needle of @attributes
            value = track.get(attname)
            if needle isnt null and not (
                    (_.isArray(needle) and _.contains(needle, value)) \
                    or needle is value)
                return no
        yes

    hasRules: ->
        Boolean(_.compact(_.values(@attributes)).length)


class NullOrdering extends Model

    apply: _.identity


class Ordering extends NullOrdering
    ###
    Model class for ordering result lists (tracks, or artist or album names).

    ###
    @ASC: 'asc'
    @DESC: 'desc'

    defaults:
        direction: @ASC

    apply: (result)->
        result = @_sortAscending(result)
        if @get('direction') is Ordering.DESC
            result.reverse()
        result

    getSortedIndex: (result, value)->
        _.sortedIndex(result, value, @_getComparator())

    _sortAscending: (result)->
        result.sort()

    _getComparator: ->
        (value)->
            console.log value
            value.toLowerCase()


class TrackOrdering extends Ordering
    ###
    Special ordering for tracks.

    ###
    defaults: _.extend({
        field: 'artist'
    }, Ordering::defaults)

    _sortAscending: (result)->
         _.sortBy(result, @_getComparator())

    _getComparator: ->
        zeros = [
            '0000',
            '000',
            '00',
            '0'
        ]

        number = (track)->
            zeros[String(track.get('number')).length] + track.get('number')

        switch @get('field')
            when 'artist'
                (track)->
                    [
                        track.get('artist').toLowerCase()
                        track.get('album').toLowerCase()
                        number(track)
                        track.get('title').toLowerCase()
                    ].join('|')
            when 'album'
                (track)->
                    [

                        track.get('album').toLowerCase()
                        number(track)
                        track.get('title').toLowerCase()
                    ].join('|')
            else
                field = @get('field')
                if field isnt 'number'
                    return (track)-> track.get(field).toLowerCase()
                else
                    return (track)-> track.get(field)

module.exports = {
    Criteria
    NullOrdering
    Ordering
    TrackOrdering
}
