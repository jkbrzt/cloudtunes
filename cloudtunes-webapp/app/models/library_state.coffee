pubsub = require 'pubsub'
{Model} = require 'mvc'
UserLibrary = require 'models/user_library'
{AlbumNameList, ArtistNameList} = require 'models/lists/virtual'
TrackList = require 'models/lists/tracklist'
{Ordering} = require 'models/lists/states'


SOURCES =
    d: 'Dropbox'
    y: 'YouTube'


class LibraryState extends Model
    ###
    Model representing the user's library ant its UI state.

    ###

    defaults:

        # Selection
        playlist: null
        artist: null
        album: null
        track: null

        # Track sorting
        sortBy: 'artist'
        ordering: 'asc'

        # Position
        centerY: 25
        centerX: 35
        trackColumns: [5, 32, 32]

    initialize: (attributes, options)->

        @library = options.library

        @library.playlists.on 'change:selected', (playlist)=>
            if not playlist.get('selected')
                # TODO: kill children
            else
                @setPlaylist(playlist)
        @library.playlists.selected(@library.playlists.first())

        @library.on 'reset', =>
            @library.playlists.selected(@library.playlists.first())

        @on 'change:artist change:album change:sortBy change:ordering', =>
            @updateLists()

        @library.on 'all', =>
            @trigger('tracks:' + arguments[0], _.toArray(arguments).slice(1))

        pubsub.on('select:artist', @selectArtist)
              .on('select:album',  @selectAlbum)
              .on('select:track',  @selectTrack)

        io.connect('http:///sync')

            .on 'track:add', (track)=>
                @library.add JSON.parse track

            .on 'track:change', (track)=>
                @library.add JSON.parse track

            .on 'track:remove', (id)=>
                track = @library.byId[id]
                if track
                    @library.remove track

            .on 'dropbox:reset', =>
                @library.remove(@library.where(source:'d'), silent: yes)
                @library.trigger('reset')

    getPlaylist: ->
        @get('playlist')

    getArtistList: ->
        @getPlaylist().children.artists

    getAlbumList: ->
        @getPlaylist().children.albums

    getTrackList: ->
        @getPlaylist().children.tracks

    setPlaylist: (playlist)=>
        if not playlist.children
            playlist.children =
                artists: playlist.getArtistList()
                albums: playlist.getAlbumList()
                tracks: playlist.getChild()
        @set('playlist', playlist)

    updateLists: =>
        ### Proxy the library state to item lists. ###
        console.log 'updateLists'

        playlist = @getPlaylist()

        return if not playlist.children

        playlist.children.albums.criteria.set
            artist: @get('artist')

        playlist.children.tracks.criteria.set
            artist: @get('artist')
            album: @get('album')

        playlist.children.tracks.ordering.set
            field: @get('sortBy')
            direction: @get('ordering')

    selectArtist: (track=null)=>
        console.log 'selectArtist', track

        if not track
            @set
                artist: null
        else
            @set
                artist: track.get('artist')
                album: null
                track: track

    selectAlbum: (track=null)=>
        if not track
            @set
                album: null
        else
            @set
                artist: track.get('artist')
                album: track.get('album')
                track: track

    selectTrack: (track=null)=>
        @set
            track: track
            artist: track.get('artist')
            album: track.get('album')

    toggleOrdering: ->
        @set 'ordering', if @get('ordering') is Ordering.ASC \
                           then Ordering.DESC \
                           else Ordering.ASC


module.exports = LibraryState
