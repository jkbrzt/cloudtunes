pubsub = require 'pubsub'
BaseContentPageView = require 'views/base_content_page_view'
{HotArtistsSectionView
TrendingArtistsSectionView
RecommendedArtistsSectionView} = require 'views/explore/explore_artists_sections'


class ExplorePageView extends BaseContentPageView

    id: 'explore'
    pageName: 'Explore'
    pageURL: ''
    sections: [
        RecommendedArtistsSectionView
        HotArtistsSectionView
        TrendingArtistsSectionView
    ]

    render: ->
        super
        @renderSection()
        @

    getSections: ->
        sections = @sections
        if not @model.has('lastfm')
            sections = sections.slice(1)
        sections

    getTemplateData: ->
        _.extend(super, user: @model)


module.exports = ExplorePageView
