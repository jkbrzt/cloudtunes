template = require 'templates/page'
BaseContentPageView = require 'views/base_content_page_view'
TopTracksView = require 'views/artist/top_tracks_view'
DiscographyView = require 'views/artist/discography_view'
SimilarArtistsView = require 'views/artist/similar_artists_view'


class ArtistPageView extends BaseContentPageView

    id: 'artist'
    className: 'content-page'
    template: template
    pageName: 'Loading…'
    pageURL: 'artist/'
    sections: [
        TopTracksView
        DiscographyView
        SimilarArtistsView
    ]

    initialize: (options)->
        @pageURL += @model.id
        @listenTo @model, 'change:name', =>
            @$('h2').text(@model.get('name'))
            @renderSection()
        @model.ensureFetched()
        super options


module.exports = ArtistPageView
