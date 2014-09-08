{Model, Collection} = require 'mvc'
YouTubeVideosSearch = require 'models/mb/youtube'
Track = require 'models/track'
pubsub = require 'pubsub'


class MBTrack extends Model

    initialize: ->
        @videos = new YouTubeVideosSearch(null, mbtrack: @)

    getQuery: ->
        "#{@get('artist').get('name')} - #{@get('title')}"

    toCloudtunesTrack: ->
        # This track doesn't have a source and source_id. It needs to be
        # assigned before it's used in the library/player.
        new Track
            number: @get('number')
            title: @get('title')
            album: @get('album').get('name')
            artist: @get('artist').get('name')
            mbid: @id
            album_mbid: @get('album').id
            artist_mbid: @get('artist').id

    getDragged: ->
        dfd = new $.Deferred()
        $.when(@videos.ensureFetched()).then =>
            tracks = []
            if @videos.length
                tracks.push(@videos.first().toCloudtunesTrack())
            dfd.resolve(tracks)
        dfd


class MBTracks extends Collection

    model: MBTrack

    initialize: (@album)->

    url: ->
        "/api/album/#{ @album.id }"

    parse: (response)->
        for track in response
            track.artist = @album.get('artist')
            track.album = @album
        response


module.exports = {
    MBTracks
}
