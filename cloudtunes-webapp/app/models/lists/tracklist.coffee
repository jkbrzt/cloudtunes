BaseList = require 'models/lists/base'
{AlbumNameList, ArtistNameList} = require 'models/lists/virtual'
{TrackOrdering} = require 'models/lists/states'


class TrackList extends BaseList

    namespace: 'track'

    Ordering: TrackOrdering

    acceptsTracks: ->
        no

    getChild: ->
        ###
        Return a new `TrackList`, a child of this one.

        ###
        new TrackList parent: @

    getAlbumList: ->
        ###
        Return a new `AlbumNameList`, a child of this one.

        ###
        new AlbumNameList parent: @

    getArtistList: ->
        ###
        Return a new `AlbumNameList`, a child of this one.

        ###
        new ArtistNameList parent: @

    _getValue: _.identity
    _getValues: _.identity


module.exports = TrackList
