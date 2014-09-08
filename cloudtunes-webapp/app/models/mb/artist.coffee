_ = require 'underscore'
{Model, Collection} = require 'mvc'
{MBAlbums} = require 'models/mb/album'
YouTubeVideosSearch = require 'models/mb/youtube'


class MBArtist extends Model

    url: ->
        '/api/artist/' + @id

    initialize: ->
        @albums = new MBAlbums(@)
        @videos = new YouTubeVideosSearch(null, mbartist: @)

    parse: (response)->
        if response.albums
            @albums.reset(@albums.parse(response.albums))
            delete response.albums
        response

    getQuery: ->
        @get 'name'

    getLibraryTopTracks: ->
        @videos.map (video)->
            video.toCloudtunesTrack()

    getSimilar: ->
        @get('similar')


module.exports = MBArtist
