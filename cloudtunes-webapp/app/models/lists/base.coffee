_ = require 'underscore'
pubsub = require 'pubsub'
{Model} = require 'mvc'
{Criteria, Ordering} = require 'models/lists/states'


class BaseList extends Model
    ###
    A view on a filtered list of values things (tracks, artist or album names)
    from a source of tracks.

    Similar to Backbone.Collection, but has state.

    It is connected to a parent list changes on whom proapgate to this list
    if the the changed tracks match @criteria.

    ###

    # Namespace for event names and, if applicable,
    # the name of the field whose values this list represents.
    namespace: null

    # Parent list. Has guaranteed to have getTracks().
    parent: null

    # A Criteria instance used for filtering parent's tracks.
    criteria: null

    # An Ordering instance used for ordering results.
    ordering: null

    # Upon retrieval and filtering from @parent, the result is cached here.
    cachedResult: null

    # Default criteria class.
    Criteria: Criteria

    # Default ordering class.
    Ordering: Ordering

    constructor: (attributes, options)->

        throw 'MISSING PARENT LIST' if not attributes.parent

        [@parent, @criteria, @ordering] = [
            attributes.parent
            attributes.criteria or new @Criteria
            attributes.ordering or new @Ordering
        ]

        super(_.omit(attributes, 'parent', 'criteria', 'ordering'), options)

        # State change resets.
        @listenTo(@criteria, 'change', @reset)
        @listenTo(@ordering, 'change', @reset)

        # Parent change resets.
        @listenTo(@parent, 'reset add change remove', @reset)

#            .on()
#            .on(@namespace + ':add', @_proxyAdd, @)
#            .on(@namespace + ':change', @_proxyChange, @)
#            .on(@namespace + ':remove', @_proxyRemove, @)
#            .on 'all', (eventName, args...)=>
#                # FIXME: propagate events on different namespaces too
#                # Now adding a track with a unique artist/album doesn't
#                # add it to album, artist list
#                console.log eventName, args, @

    reset: =>
        ###
        Invalidate cache and let listeners know abou that.

        ###
        @cachedResult = null
        @trigger('reset')

    close: ->
        ###
        Stop listening to the parent.

        ###

        @parent.off(null, null, @)

    getTracks: ->
        ###
        Return a filtered list of tracks (by @criteria).

        Not cached.

        ###
        @criteria.apply(@parent.getTracks())

    getResult: ->
        ###
        Return a filtered and sorted list of values extracted
        from tracks this list represents.

        Cached.

        ###
        if not @cachedResult
            @cachedResult = @_getResult()
        @cachedResult

    clone: ->
        ###
        Return a copy of this list.

        ###
        # FIXME: these are shallow copies
        attributes = _.extend {}, @attributes,
            parent: @parent
            criteria: @criteria.clone()
            ordering: @ordering.clone()
        new @constructor(attributes)

    _getResult: ->
        ###
        Return a filtered list of values extracted
        from tracks this list represents.

        Not cached.

        ###
        @ordering.apply(@_getValues(@getTracks()))

    _includes: (track)->
        ###
        Is the track's value already included in this result list?

        ###
        _.include(@getResult(), @_getValue(track))

    _getValue: (track)->
        ###
        Translate track to the value type included in result.

        ###
        throw 'NOT IMPLEMENTED'

    _getValues: (tracks)->
        ###
        Translate tracks into things this list represents
        (identity, artist names, etc.)

        ###
        throw 'NOT IMPLEMENTED'

    _proxyAdd: (track)=>
        ###
        Handle 'add' event that has ocurred on the parent list.

        ###
        console.log '_proxyAdd', @criteria.matches(track), @, track
        if @criteria.matches(track)
            index = @_add(track)
            @trigger('add', track, index)
            @trigger(@namespace + ':add', track)

    _proxyChange: (track)=>
        ###
        Handle 'change' event that has ocurred on the parent list.

        ###
        # TODO: handle change-based addition/removal (starts/stops matching)
        if @_includes(track)
            index = _.indexOf(@cachedResult, @_getValue(track))
            @trigger('change', track, index)
            @trigger(@namespace + ':change', track)

    _proxyRemove: (track)=>
        ###
        Handle 'remove' event that has ocurred on the parent list.

        ###
        if @_includes(track)
            index = @_remove(track)
            @trigger('remove', track, index)
            @trigger(@namespace + ':remove', track)

    _add: (track)->
        ###
        Add `track` to @cachedResult and return its index.

        ###
        @getResult()
        index = @ordering.getSortedIndex(@cachedResult, @_getValue(track))
        @cachedResult.splice(index, 0, @_getValue(track))
        index

    _remove: (track)->
        ###
        Remove `track` from @cachedResult and return its original index.

        ###
        @getResult()
        index = _.indexOf(@cachedResult, @_getValue(track))
        @cachedResult.splice(index, 1)
        index


module.exports = BaseList
