FocusContextView = require 'views/ui/focus_context_view'
{View} = require 'mvc'
pubsub = require 'pubsub'
{DROPBOX, YOUTUBE} = require 'source_ids'
{DroppableView} = require 'views/ui/dnd'
{UserPlaylist} = require 'models/lists/playlists'
addTemplate = require 'templates/sidebars/youtube_add_dialog'
itemTemplate = require 'templates/sidebars/item'
userTemplate = require 'templates/sidebars/user'
BaseSidebarView = require 'views/sidebars/base'

syncSocket = io.connect('http:///sync')


class YoutubeAddDialog extends View

    className: 'dialog modal'
    template: addTemplate
    container: 'body'

    events:
        'click': 'remove'
        'click button': 'submit'
        'click .body': 'prevent'

    prevent: =>
        no

    submit: =>
        $input = @$('input')
        url = $input.val()
        if not url
            $input.focus()
        else
            @remove()
            syncSocket.emit('add_url', {url})

        no


class SidebarItemView extends View
    tagName: 'li'
    className: 'item'
    template: itemTemplate
    events:
        mousedown: 'activate'
        # "click .button" colides with "mousedown: 'activate'" for some reason,
        # that is why we use "mousedown" here.
        'mousedown .button': 'buttonClicked'

    activate: ->
        # Simulate click.
        pubsub.router.navigate(@$('a').attr('href'), trigger: yes)


class ExploreItemView extends SidebarItemView

    initialize: (options)->
        super
        @listenTo(pubsub.router, 'route', @render)
        @listenTo pubsub.user.library.playlists, 'change:selected', =>
            @$el.removeClass('selected')

    render: =>
        super
        if _.contains(['', 'trending'], Backbone.history.fragment)
            @$el.addClass('selected')
        @

    getTemplateData: ->
        url: '/'
        icon: 'compass'
        name: 'Explore'
        button: null


class SearchItemView extends SidebarItemView

    getTemplateData: ->
        url: '/search'
        icon: 'search'
        name: 'Search'
        button: null




class PlaylistView extends SidebarItemView

    initialize: (options)->
        super options
        #@listenTo(@model, 'change', @render)
        if @model.acceptsTracks()
            @subview('droppable', new DroppableView(
                delegate: @
                el: @el
            ))

    render: =>
        super
        @setClasses()
        @


    getTemplateData: ->
        url: @model.getRoute()
        icon: @model.get('icon')
        name: @model.get('name')

    setClasses: ->
        if @model.get('selected')
            @$el.addClass('selected')
        else
            @$el.removeClass('selected')

        if @model.acceptsTracks()
            @$el.addClass('accepts-tracks')

    drop: (tracks)->
        console.log 'tracksDropped', @, tracks
        if not @model.acceptsTracks()
            throw '!'
        @model.addTracks(tracks)


class QueuePlaylistView extends PlaylistView

    render: ->
        super
        @setClasses()
        @


class YouTubePlaylistView extends PlaylistView


    buttonClicked: =>
        new YoutubeAddDialog().render()

    getTemplateData: ->
        data = super
        data.icon = 'youtube'
        data.button =
            title: 'Add YouTube song'
            className: 'add'
            icon: 'plus-sign'
        data

    render: =>
        super


class AllPlaylistView extends PlaylistView

class DropboxPlaylistView extends PlaylistView

    getTemplateData: ->
        data = super
        data.button =
            title: 'Sync Dropbox'
            className: 'sync'
            icon: 'refresh'
        data

    buttonClicked: =>
        if pubsub.user.has('dropbox')
            @startSync()
        else
            pubsub.router.navigate 'settings/social',
                trigger: yes
                replace: yes

    startSync: =>
        console.log('starting dropbox sync')
        syncSocket.emit('dropbox')


# These go to the built-in list.
VIEWS = {}
VIEWS['queue'] = QueuePlaylistView
VIEWS['all'] = AllPlaylistView
VIEWS['dropbox'] = DropboxPlaylistView
VIEWS['youtube'] = YouTubePlaylistView


class ItemListView extends View

    initialize: (options)->
        super options
        @subview(new FocusContextView(delegate: @))

        @listenTo(@collection, 'reset add remove change', @render)
        @listenTo pubsub.router, 'route', ->
            if _.contains(['', 'trending'], Backbone.history.fragment)
                # Unselect selected playlist when we
                # navigate to one of the explore views.
                @$('.item:not(.explore)').removeClass('selected')

        @$add = @$('.add')
        @$builtInPlaylists = @$('ul.builtin-playlists')
        @$userPlaylists = @$('ul.user-playlists')
        @$exploreList = @$('section.explore ul')

        @$exploreList.append @subview(
            'explore-item',
            new ExploreItemView
        ).render().el

        @$exploreList.append @subview(
            'search-item',
            new SearchItemView
        ).render().el

        @collection.each (playlist)=>
            # Initiate built-in playlists and queue views.
            if not (playlist instanceof UserPlaylist)
                if playlist.id is 'queue'
                    @$exploreList.append(@subview('queue',
                        new QueuePlaylistView(model: playlist).render()).el)
                else
                    View = VIEWS[playlist.id]
                    view = @subview("builtin-playlist-#{playlist.id}",
                                    new View({model: playlist})).render()
                    @$builtInPlaylists.append(view.el)

    render: =>

        for subview in @subviews

            if subview.model instanceof UserPlaylist
                subview.remove()
            else
                subview.render()

        @collection.each (playlist)=>
            if playlist instanceof UserPlaylist
                view = @subview(
                    "user-playlist-#{playlist.id}",
                    new PlaylistView({model: playlist})
                )
                @$userPlaylists.append(view.render().el)

    selectedViewIndex: =>
        i = _.indexOf(
            @subviews,
            _.find(@subviews, (view)-> view.$el.is('.selected'))
        )
        console.log 'selectedViewIndex', i
        i

    selectNextItem: =>
        i = @selectedViewIndex()
        if i < @subviews.length - 1
            @subviews[i + 1].activate()

    selectPrevItem: =>
        i = @selectedViewIndex()
        if i > 0
            @subviews[i - 1].activate()


class CreatePlaylistButton extends DroppableView

    events:
        click: 'click'

    click: ->
        @openDialog()

    openDialog: (tracks)->
        name = window.prompt('New Playlist Name:')
        if not name
            return
        pubsub.user.library.playlists.create {name}, success: (playlist)->
            pubsub.user.library.playlists.selected(playlist)
            if tracks
                playlist.addTracks(tracks)

    drop: (tracks)->
        @openDialog(tracks)



class UserView extends View

    className: 'user'
    template: userTemplate
    container: '#header'

    events:
        'click img': 'toggleMenu'
        'click li': 'toggleMenu'

    initialize: (options)->
        super options
        @isOpen = no
        @listenTo(@model, 'change reset', @render)

    render: ->
        super
        @$menu = @$('.menu')
        @setMenuPos()
        @

    setMenuPos: =>
        if @isOpen
            top = "#{ @$el.height() + 1 }px"
        else
            top = "#{ @$el.height() - @$menu.height() }px"
        @$menu.css('top', top)

    toggleMenu: =>
        @isOpen = not @isOpen
        @setMenuPos()


class NavSidebarView extends BaseSidebarView

    initialize: (options)->
        super options
        @subview('items', new ItemListView(
            collection: pubsub.user.library.playlists
            el: @$el
        )).render()

        @subview(
            'create-playlist',
            new CreatePlaylistButton(el: @$el.find('.create-playlist'))
        )

        @subview('user', new UserView(model: pubsub.user, el: @$('.profile'))).render()



module.exports = NavSidebarView
