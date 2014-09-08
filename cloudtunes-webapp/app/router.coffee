Backbone = require 'backbone'
pubsub = require 'pubsub'

PlaylistPageView = require 'views/playlists/playlist_page_view'
SettingsPageView = require 'views/settings/settings_page_view'
ArtistPageView = require 'views/artist/artist_page_view'
ExplorePageView = require 'views/explore/explore_page_view'
SearchPageView = require 'views/search/search_page_view'

MBArtist = require 'models/mb/artist'


class Router extends Backbone.Router

    routes:

        'collection': 'library'
        'queue': 'queue'
        'playlist/:playlist': 'library'

        'settings/:section': 'settings'
        'settings': 'settings'

        'artist/:id/:section': 'artist'
        'artist/:id': 'artist'

        'search': 'search'
        '': 'explore'
        ':section': 'explore'

    explore: (section)->
        @view?.remove()
        @view = new ExplorePageView({section, model: pubsub.user}).render()

    search: ->
        @view?.remove()
        @view = new SearchPageView().render()

    queue: ->
        @library('queue')

    library: (playlist_id='all')->
        @view?.remove()
        playlists = pubsub.user.library.playlists
        playlist = playlists.get(playlist_id)
        if playlist
            playlists.selected(playlist)
        @view = new PlaylistPageView
            model: pubsub.libraryState
        @view.render()

    settings: (section)->
        @view?.remove()
        @view = new SettingsPageView
            model: pubsub.user
            section: section
        @view.render()

    artist: (id, section)->
        @view?.remove()
        @view = new ArtistPageView
            model: new MBArtist({id})
            section: section
        @view.render()


module.exports = Router
