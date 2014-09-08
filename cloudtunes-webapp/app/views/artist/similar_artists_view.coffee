SectionView = require 'views/page_section_view'
VideoListView = require 'views/artist/video_list_view'
template = require 'templates/artist/artist_list'


class SimilarArtistsView extends SectionView

    url: 'similar'
    className: 'similar-artists'
    name: 'Similar Artists'
    template: template

    getTemplateData: =>
        artists: @model.getSimilar()


module.exports = SimilarArtistsView
