{Collection} = require 'mvc'
SectionView = require 'views/page_section_view'
{TopTrackVideoView} = require 'views/artist/video_views'
BaseListView = require 'views/base_list_view'


itemTemplate = (track) -> """
    <tr class="item" data-track="#{track.cid}" draggable="true">
        <td><img height="45" src="#{ track.get('video').get('thumbnail').sqDefault }" /></td>
        <td>#{ _.escape track.get('title') }</td>
    </tr>

"""



class TopMusicVideosListView extends BaseListView

    tagName: 'table'
    className: 'playable-list'

    initialize: (options)->
        super options
        @tracks = new Collection(
            video.toCloudtunesTrack() \
            for video in @collection.models
        )

    getTracks: ->
        @tracks.models

    getDragged: ->
        track = @tracks.get(@$selectedItem.data('track'))
        # Return a copy of selected track so that it can be added
        # to the user library collection (can only belong to one).
        [track.clone()]

    handlePlay: (e)->
        $item = $(e.currentTarget)
        cid = $item.data('track')
        @play(cid)

    render: ->
        super
        html = (itemTemplate(track) for track in @getTracks()).join '\n'
        @$el.html html
        @


class TopTracksView extends SectionView

    url: 'tracks'
    className: 'top-tracks'
    name: 'Top Music Videos'

    initialize: (options)->
        super options
        @model.videos.fetch(success: @render)

    render: =>

        @$el.html('').append(new TopMusicVideosListView(
            collection: @model.videos
        ).render().el)

        @


module.exports = TopTracksView
