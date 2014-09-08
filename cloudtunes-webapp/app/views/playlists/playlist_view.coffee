{View} = require 'mvc'
template = require 'templates/playlists/tracklist'
TrackListView = require 'views/playlists/track_list_view'


class PlaylistView extends View

    template: template
    id: 'playlist-flat'
    className: 'flat-playlist-body playlist-body'

    render: =>
        super
        @subview(
            new TrackListView(
                model: @model
                el: @$('.tracks')
                disableSorting: yes
            )
        ).render()
        @


module.exports = PlaylistView
