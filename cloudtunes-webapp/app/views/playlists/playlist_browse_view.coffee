pubsub = require 'pubsub'
{View} = require 'mvc'
template = require 'templates/playlists/playlist_browse'
{ColumnResizer, RowResizer} = require 'views/ui/resizer_views'
{ArtistListView, AlbumListView} = require 'views/playlists/filter_list_views'
TrackListView = require 'views/playlists/track_list_view'


class PlaylistBrowseView extends View

    template: template
    id: 'playlist-browse'
    className: 'playlist-body'

    initialize: (options)->
        super options
        @listenTo(@model, 'change:centerX', @updateGridColumns)
        @listenTo(@model, 'change:centerY', @updateGridRows)

    handleRowResized: (y)->
        @model.set('centerY', y)

    handleColumnResized: (x)->
        @model.set('centerX', x)

    updateGridColumns: =>
        artists = @model.get('centerX')
        albums = 100 - artists
        @subview('artists').$el.css('width', artists + '%')
        @subview('albums').$el.css('width', albums + '%')

    updateGridRows: =>
        groups = @model.get('centerY')
        tracks = 100 - groups

        @subview('artists').$el.css('height', groups + '%')
        @subview('albums').$el.css('height', groups + '%')
        @subview('tracks').$el.css('height', tracks + '%')

    render: =>
        super

        @subview('artists', new ArtistListView({@model, el: @$ '.artists'}))
        @subview('albums',  new AlbumListView({@model, el: @$ '.albums'}))
        @subview('tracks',  new TrackListView({@model, el: @$ '.tracks'}))

        rowResizer = @subview 'resize-row', new RowResizer
            el: @$('.resize-row.resize-main-grid')
            context: @$el
            value: @model.get('centerY')
            relative: yes
            min: 100
            max: -100

        @listenTo(rowResizer, 'resize', @handleRowResized)

        columnResizer = @subview 'resize-col', new ColumnResizer
            el: @$('.resize-col.resize-main-grid')
            value: @model.get('centerX')
            context: @$el
            relative: yes
            min: 100
            max: -100

        @listenTo(columnResizer, 'resize', @handleColumnResized)

        for view in @subviews
            view.render()

        @updateGridColumns()
        @updateGridRows()

        @


module.exports = PlaylistBrowseView
