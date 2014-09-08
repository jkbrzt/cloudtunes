{Collection} = require 'mvc'
pubsub = require 'pubsub'
TrackList = require 'models/lists/tracklist'
{NullOrdering} = require 'models/lists/states'


class Playlist extends TrackList

    getRoute: ->
        "/playlist/#{@id}"


    acceptsTracks: -> no
    canRename: -> no
    canDelete: -> no


class UserPlaylist extends Playlist

    editable: yes

    defaults:
        icon: 'music'

    constructor: (attributes, options)->
        attributes.parent = pubsub.user.library
        tracks = attributes.tracks or []
        delete attributes.tracks
        super(attributes, options)
        @criteria.set('id', tracks)

    acceptsTracks: -> yes
    canRename: -> yes
    canDelete: -> yes

    addTracks: (tracks)->
        pubsub.user.library.ensureIncluded(tracks).done =>
            currentIds = @criteria.get('id')
            addIds = _.pluck(tracks, 'id')
            addIds = _.difference(addIds, currentIds)
            if addIds.length
                @criteria.set(id: addIds.concat(currentIds))
                @_updateTracks(addIds, 'add')

    removeTracks: (tracks)->
        currentIds = @criteria.get('id')
        removeIds = _.pluck(tracks, 'id')
        removeIds = _.intersection(removeIds, currentIds)
        if removeIds.length
            @criteria.set('id', _.without(currentIds, removeIds))
            @_updateTracks(removeIds, 'remove')

    _updateTracks: (tracks, action)->
        $.ajax
            url: @url() + '/tracks/' + action
            type: 'POST'
            dataType: 'json'
            contentType: 'application/json',
            data: JSON.stringify(tracks)


class PlayQueuePlaylist extends Playlist
    ###
    @parent is a `PlayQueue`
    ###
    defaults:
        icon: 'list-ol'
    Ordering: NullOrdering

    acceptsTracks: ->
        yes

    getRoute: ->
        '/queue'

    getChild: ->
        # No need to create a copy.
        @

    addTracks: (tracks)->
        @parent.add(tracks)


class AllPlaylist extends Playlist

    defaults:
        icon: 'globe'

    acceptsTracks: ->
        yes

    getRoute: ->
        '/collection'

    addTracks: (tracks)->
        @parent.ensureIncluded(tracks)


class Playlists extends Collection

    model: UserPlaylist
    url: '/api/library/playlists'

    selected: (playlist=null)->
        if not playlist
            @findWhere(selected: yes)
        else
            @selected()?.set({selected: no}, {silent: yes})
            playlist.set('selected', yes)


module.exports = {
    Playlist
    Playlists
    PlayQueuePlaylist
    AllPlaylist
    UserPlaylist
}
