{Model, Collection} = require 'mvc'
{MBTracks} = require 'models/mb/track'


class MBAlbum extends Model

    initialize: ->
        @tracks = new MBTracks(@)

    getCloudtunesTracks: ->

        deferred = new $.Deferred()

        $.when(@tracks.ensureFetched()).then =>

            requests = @tracks.map (mbtrack)->
                mbtrack.videos.fetch()

            $.when.apply(null, requests).done =>
                tracks = _.compact @tracks.map (mbtrack)->
                    mbtrack.videos.first()?.toCloudtunesTrack()
                deferred.resolve(tracks)

        deferred.promise()

    getDragged: @::getCloudtunesTracks


class MBAlbums extends Collection

    model: MBAlbum

    initialize: (@artist)->

    parse: (response)->
        for album in response
            album.artist = @artist
        response


module.exports = {MBAlbums}
