Backbone = require 'backbone'
{Collection} = require 'mvc'
{Playlist, Playlists, TrackList, AllPlaylist} = require 'models/lists/playlists'
TrackList = require 'models/lists/tracklist'
Track = require 'models/track'
{DROPBOX, YOUTUBE} = require 'source_ids'


decompressTree = (collectionTree, fieldNames)->
    tracks = []
    for artist, albums of collectionTree
        for album, albumTracks of albums
            for track in albumTracks
                tracks.push(decompressTrack(artist, album, track, fieldNames))
    tracks


decompressTrack = (artist, album, compressedTrack, fieldNames)->
    i = 0
    track = {
        artist
        album
    }
    for fieldName, i in fieldNames
        track[fieldName] = compressedTrack[i]

    track


class UserLibrary extends Collection

    model: Track
    url: '/api/library'

    initialize: (models, options)->
        super models, options

        # All tracks in the users library
        @tracklist = new TrackList(parent: @)

        @playlists = new Playlists [
            new AllPlaylist
                parent: @
                name: 'All'
                id: 'all'

            new Playlist
                parent: @
                name: 'Dropbox'
                icon: 'dropbox'
                id: 'dropbox'
                criteria: new TrackList::Criteria(source: DROPBOX)

            new Playlist
                parent: @
                name: 'YouTube'
                icon: 'youtube'
                id: 'youtube'
                criteria: new TrackList::Criteria(source: YOUTUBE)

        ]

    parse: (response, options)->
        @playlists.add(response.playlists)
        decompressTree(response.collection, response._fields)

    getTracks: ->
        # TrackList interface.
        @models

    ensureIncluded: (tracks)->
        dd = new $.Deferred()
        missingTracks = _.where(tracks, {id: undefined})
        if not missingTracks.length
            return dd.resolve()

        @add(missingTracks)
        requests = (track.save() for track in missingTracks)
        $.when.apply(null, requests).then(dd.resolve)
        dd.promise()


module.exports = UserLibrary
