SectionView = require 'views/page_section_view'
template = require 'templates/artist/artist_list'
MBArtist = require 'models/mb/artist'
{Collection} = require 'mvc'


class Artists extends Collection
    model: MBArtist


class BaseExploreArtistsSectionView extends SectionView

    template: template

    initialize: (options)->
        super options
        @artists = new Artists()
        @artists.url = @endpoint
        @artists.fetch(success: @render)

    getTemplateData: =>
        artists: @artists.toJSON()


class HotArtistsSectionView extends BaseExploreArtistsSectionView

    name: 'Top'
    url: 'top'
    className: 'top'
    artsitsChart: 'top'
    endpoint: "/api/explore/artists/top"


class TrendingArtistsSectionView extends BaseExploreArtistsSectionView

    name: 'Trending'
    url: 'trending'
    className: 'trending'
    endpoint: "/api/explore/artists/trending"


class RecommendedArtistsSectionView extends BaseExploreArtistsSectionView

    name: 'Recommended'
    url: ''
    className: 'recommended'
    endpoint: "/api/explore/artists/recommended"


module.exports = {
    HotArtistsSectionView
    TrendingArtistsSectionView
    RecommendedArtistsSectionView
}
