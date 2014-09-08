$ = require 'jquery'
pubsub = require 'pubsub'
notify = require 'notifications'
Router = require 'router'

User = require 'models/user'
LibraryState = require 'models/library_state'
UserLibrary = require 'models/user_library'
Sidebar = require 'models/sidebar'
{PlayQueuePlaylist} = require 'models/lists/playlists'


Layout = require 'views/layout_view'
NavSidebarView = require 'views/sidebars/nav_sidebar_view'
InfoSidebarView = require 'views/sidebars/info_sidebar_view'

PLAYING = '▶'
PAUSED = '❚❚'


class Application

    initialize: ->

        @user = pubsub.user = new User()
        @user.library = new UserLibrary()

        @libraryState = new LibraryState(null, library: @user.library)

        @navSidebar = pubsub.navSidebar = new Sidebar(width: 150)
        @infoSidebar = pubsub.infoSidebar = new Sidebar(width: 250)

        @initLayout()

        @pubsub = pubsub
        pubsub.user = @user
        pubsub.libraryState = @libraryState
        pubsub.router = new Router()

        @user.fetch success: =>
            @libraryState.library.fetch(reset: true).then =>
                Backbone.history.start(pushState: true)
                io.connect('http:///sync')
                    .on 'user:change', (user)=>
                        @user.set(JSON.parse(user))

        @initPlayer()
        @initSidebars()

        $(window).on 'beforeunload', =>
            if @user.get('confirm_exit') and @player.playing()
                return 'CloudTunes music is still playing, do you really want to leave?'

    initLayout: ->
        new Layout(el: $(document.body)).render()


    initSidebars: ->
        new NavSidebarView(model: @navSidebar, el: $ '#nav-sidebar').render()
        new InfoSidebarView(model: @infoSidebar, el: $ '#info-sidebar').render()

    initPlayer: ->
        Player = require 'models/player'
        PlayerView = require 'views/player_view'

        @player = pubsub.player = new Player

        socket = io.connect('http:///player')

        # Remote control
        io.connect('http:///remote')

            .on 'play_artist', (name)=>
                playlist = @user.library.playlists.at(0).getChild()
                playlist.criteria.set(artist: name)
                @player.replaceQueue(playlist.getTracks())
                @player.play()

            .on 'play_pause', =>
                @player.toggle()

            .on 'play', (trackId)=>
                track = @user.library.get(trackId) if trackId
                @player.play(track)

            .on 'clear', =>
                @player.queue.clear()
                @player.stop()

            .on 'queue', (pos)=>
                playlist = @user.library.playlists.at(pos)
                @player.replaceQueue(playlist.getTracks())

            .on 'select', (pos)=>
                playlist = @user.library.playlists.at(pos)
                if playlist
                    playlist.collection.selected(playlist)

            .on 'pause', =>
                @player.pause()

            .on 'prev', =>
                @player.prev()

            .on 'next', =>
                @player.next()


        new PlayerView(model: @player, el: $ '#player').render()

        @user.library.playlists.unshift new PlayQueuePlaylist
            id: 'queue'
            parent: @player.queue
            name: 'Play Queue'

        @player
            .on 'change:state', =>
                if @player.playing()
                    track = @player.get('track')
                    if track isnt @player.previous('track')
                        socket.emit('play', track_dict: track)

            .on 'change:state', =>
                if @player.playing() and pubsub.user.get('desktop_notifications')
                    track = @player.get('track')
                    body = ""
                    if track.get('album')
                        body += " from #{track.get('album')}"
                    notify
                        title: "☁♪ Now Playing"
                        body: "#{ track.get('artist')} – #{track.get('title')}"

            .on 'change:state', =>
                track = @player.get('track')
                # TODO: titles when not playing
                if track
                    symbol = if @player.playing() then PLAYING else PAUSED
                    document.title = "#{ symbol } #{ track.get('title') } – #{ track.get('artist') }"
                else
                    document.title = 'cloudtunes' #'☁♪'


module.exports = Application
