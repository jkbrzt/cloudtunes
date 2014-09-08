SectionView = require 'views/page_section_view'
AlbumView = require 'views/artist/album_view'


class DiscographyView extends SectionView

    url: 'discography'
    className: 'discography'
    name: 'Discography'

    initialize: (options)->
        super options

    render: ->
        @model.albums.each (album)=>
            view = new AlbumView model: album
            @$el.append(@subview('album-' + album.id, view).render().el)

        if not @model.albums.length
            @$el.text('No albums found :(')

        @


module.exports = DiscographyView
