pubsub = require 'pubsub'
{PageView, View} = require 'mvc'
MenuView = require 'views/ui/menu_view'
{UserPlaylist} = require 'models/lists/playlists'
PlaylistBrowseView = require 'views/playlists/playlist_browse_view'
PlaylistView = require 'views/playlists/playlist_view'
PlayQueueView = require 'views/playlists/play_queue_view'
headerTemplate = require 'templates/playlists/playlist_header'


class PlaylistHeaderView extends View
    className: 'playlist-header'
    tagName: 'header'
    template: headerTemplate
    events:
        'click .options': 'openMenu'

    initialize: (options)->
        @listenTo(@model, 'change', @render)

    getTemplateData: ->
        console.log @model.toJSON()
        _.extend @model.toJSON(),
            showOptions: @model.canRename() or @model.canDelete()

    openMenu: (e)->
        actions = {}
        if @model.canRename()
            actions.rename =
                label: 'Rename'
                icon: 'edit'
                callback: =>
                    name = prompt('New Name', @model.get('name'))
                    if name
                        @model.save({name})

        if @model.canDelete()
            actions.delete =
                label: 'Delete'
                icon: 'remove'
                callback: =>
                    @model.destroy()
                    pubsub.router.navigate('/collection', trigger: yes)

        MenuView.fromMouseEvent e, {actions}



class QueueHeaderView extends PlaylistHeaderView




class PlaylistPageView extends PageView

    id: 'playlist'

    initialize: (options)->
        console.log 'new PlaylistPageView'
        super(options)
        @listenTo(@model, 'change:playlist', @render)

    render: =>
        super

        @subview('header')?.remove()
        @subview('playlist')?.remove()

        playlist = @model.getPlaylist()

        headerViewClass = null
        if playlist.id == 'queue'
            headerViewClass = QueueHeaderView
            playlistViewClass = PlayQueueView
        else
            if playlist instanceof UserPlaylist
                playlistViewClass = PlaylistView
            else
                playlistViewClass = PlaylistBrowseView
            if playlist.id isnt 'all'
                headerViewClass = PlaylistHeaderView

        if headerViewClass

            @$el.addClass('has-header').append(@subview(
                'header',
                new headerViewClass({
                    model: playlist
                })
            ).render().el)
        else
            @$el.removeClass('has-header')

        @$el.append(@subview(
            'playlist',
            new playlistViewClass({@model})
        ).render().el)


module.exports = PlaylistPageView
