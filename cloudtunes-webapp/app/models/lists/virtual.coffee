BaseList = require 'models/lists/base'


class BaseVirtualList extends BaseList
    ###
    Virtual lists don't result in tracks,
    but in a list of attributes (album names, artist names)

    ###

    _getValue: (track)=>
        track.get(@namespace)

    _getValues: (tracks)->
        _.unique(_.map(tracks, @_getValue))


class AlbumNameList extends BaseVirtualList

    namespace: 'album'


class ArtistNameList extends BaseVirtualList

    namespace: 'artist'


module.exports = {
    AlbumNameList
    ArtistNameList
}
