pubsub = require 'pubsub'
BaseLibraryListView = require 'views/playlists/base_list_view'


itemTemplate = (namespace, item)->
    "<div class='#{ namespace } item' draggable='true'>#{ _.escape(item) }</div>"


listTemplate = (namespace, items)->
    """
        <div class='#{ namespace } all item' draggable='true'>
            All (<span>#{ items.length }</span> #{ namespace }s)
        </div>
    """ + (itemTemplate(namespace, item) for item in items).join('')


class BaseFilterListView extends BaseLibraryListView

    events: _.extend(
        'mousedown h2': 'unselect',
        BaseLibraryListView::events
    )

    render: =>
        super
        @$body.html(listTemplate(@namespace, @collection.getResult()))
        @select(@model.get('track'))

    addItem: (track, index)->
        console.log 'addItem', i, track, @
        $newAtIndex = @renderItem(track)
        $current = @getItem(index)

        if $current
            $newAtIndex.insertBefore($current)
        else
            @$body.append($newAtIndex)

        @updateCount()

    removeItem: (track, index)->
        @getItem(index)?.remove()
        @updateCount()

    updateCount: ->
        @$body.find('.item.all:first span').text(@collection.getResult().length)

    getItem: (index)->
        $item = @$body.find(".item:eq(#{ index + 1 })")
        if $item.length
            return $item

    renderItem: (track)->
        $(@itemTemplate(@namespace, track(@namespace)))

    select: (track)=>
        value = track?.get(@namespace)
        if not value
            @selectItem(@$body.find('.item:first'))
        else
            @$body.find('.item').each (i, el)=>
                if el.textContent is value
                    @selectItem($(el))
                    no

    unselect: =>
        pubsub.publish("select:#{@namespace}", null)

    getDragged: ->
        @model.getTrackList().getResult()


class ArtistListView extends BaseFilterListView

    namespace: 'artist'

    initialize: (options)->
        super options
        @listenTo(@model, 'tracks:reset change:source', @render)
        @listenTo(pubsub, 'select:artist', @select)

    mousedown: (e)=>
        $item = $(e.currentTarget)
        @selectItem $item
        artist = if $item.hasClass('all') then null else $item.text()
        @model.set
            artist: artist
            album: null


class AlbumListView extends BaseFilterListView

    namespace: 'album'

    initialize: (options)->
        super options
        @listenTo(@model, 'change:artist tracks:reset change:source', @render)
        @listenTo(pubsub, 'select:album', @select)

    mousedown: (e)=>
        $item = $ e.currentTarget
        @selectItem $item
        album = if $item.hasClass('all') then null else $item.text()
        @model.set({album})


module.exports = {
    AlbumListView
    ArtistListView
}
