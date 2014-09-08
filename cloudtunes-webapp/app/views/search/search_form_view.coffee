
{View, Model, Collection} = require 'mvc'
{escapeRegExp} = require 'utils'
template = require 'templates/search/search_suggest'
pubsub = require 'pubsub'
FocusContextView = require 'views/ui/focus_context_view'



class SuggestedItem extends Model


class SuggestedItems extends Collection

    model: SuggestedItem


class SearchFormView extends View

    events:
        'focus #q': 'activity'
        'keyup #q': 'activity'
        #'blur #q': 'end'

    initialize: (options)->
        super(options)
        @$q = @$('input')
        @suggest = new SuggestView
            el: @$ '.suggest'
            model: @model
        @suggest.hide()

    activity: =>
        @$el.addClass('active')
        @updateSuggestions($.trim(@$q.val()))

    activity: _.debounce(@::.activity, 500)

    end: =>
        @$el.removeClass('active')
        @suggest.hide()

    updateSuggestions: (query)=>
        if query
            @suggest.show()
            if query != @prevQuery
                @prevQuery = query
                @suggest.render(query)
        else
            @suggest.hide()


class Query extends Model

    initialize: ->
        query = @get('value')
        @res = (new RegExp(escapeRegExp(re), 'i') \
                for re in query.split(/\s+/g))

    matches: (text)=>
        _.all @res, (re) -> re.test(text)

    getTagText: ->
        @get('value')

    filter: (coll)->
        model for model in coll when @matches(model)


class BaseSourceSuggestView extends View


class CollectionSuggestView extends BaseSourceSuggestView

    className: 'suggest-collection'

    initialize: (options)->
        super options
        @artistNames = @model.library.tracklist.getArtistList()
        @albums = @model.library.tracklist.getAlbumList()
        @tracks = @model.library.tracklist

    render: (query)->

        mixes = _.map @model.library.playlists.models, (mix)->
            _.pick(mix.attributes, 'name', 'id')

        playlists =
            id: 'playlists'
            name: 'Playlists'
            type: 'collection:playlist'
            items: for mix in @filterItems(query, 3, mixes, 'name')
                value: mix.id
                text: mix.name

        artists =
            id: 'artists'
            name: 'Artists'
            type: 'collection:artist'
            items: for artist in @filterItems(query, 3, @artistNames.getResult())
                value: artist
                text: artist

        albums =
            id: 'albums'
            name: 'Albums'
            type: 'collection:album'
            items: for album in @filterItems(query, 3, @albums.getResult(), 'album')
                value: album.album
                text: album.album
                note: "by #{album.artist}"

        tracks =
            id: 'tracks'
            name: 'Tracks'
            type: 'collection:track'
            items: for track in @filterItems(query, 3, @tracks.getResult(), 'title')
                value: track.id
                text: track.get('title')
                note: "by #{track.get('artist')} from #{track.get('album')}"

        source =
            id: 'collection'
            name: 'Collection'
            showAllLabel: 'Show All Results…'
            sections: []

        for section in [playlists, artists, albums, tracks]
            if section.items.length
                @collection.add(section.items)
                source.sections.push(section)

        if not source.sections.length
            @$el.hide()
            no
        else
            @$el.html(template(source))
            @$el.show()
            yes


    filterItems: (query, limit, items, textField=null)->
        q = new Query value: query
        count = 0
        matched = []
        for item in items
            text = if textField then item[textField] else item
            if q.matches text
                matched.push item
                if ++count is limit
                    break
        matched


class ExternalSuggestView extends BaseSourceSuggestView

    className: 'suggest-external'

    initialize: (options)->
        @render = _.debounce(@render, 500)

    render: (query)=>

        $.get '/api/search/suggest', q: query, (data)=>
            source =
                id: 'external'
                name: 'Elsewhere'
                showAllLabel: 'Show All Results…'
                sections: []

            if data.artists.length
                artistsSection =
                    id: 'artists'
                    type: 'external:artist'
                    name: 'Artists'
                    items: for artist in data.artists
                        id: artist.id
                        text: artist.artist
                        note: artist.note
                @collection.add(artistsSection.items)
                source.sections.push(artistsSection)

            if data.tracks.length
                tracksSection  =
                    id: 'tracks'
                    type: 'external:track'
                    name: 'Tracks'
                    items: for track in data.tracks
                        id: track.id
                        text: track.title
                        note: "by #{track.artist}"
                @collection.add(tracksSection.items)
                source.sections.push(tracksSection)

            if not source.sections.length
                @$el.hide()
                no
            else
                @$el.html(template(source))
                @$el.show()
                yes


class SuggestView extends View

    events:
        'click .item': 'handleItemClick'
        'mouseover .item': 'handleItemHover'

    initialize: (options)->
        super options

        @subview(new FocusContextView(delegate: @))

        @collection = new SuggestedItems
        cv = @subview(
            'collection',
            new CollectionSuggestView({@model, @collection})
        )
        ex = @subview(
            'external',
            new ExternalSuggestView({@model, @collection})
        )
        @$el.append(cv.el)
        @$el.append(ex.el)

    render: (query)->
        #@focus()
        query = $.trim query
        if query.length > 1
            _.invoke(@subviews, 'render', query)
        else
            @hide()

    hide: =>
        @$el.hide()

    show: ->
        @$el.show()

    selectItem: ($item)->
        @$selectedItem?.removeClass('selected')
        if $item?.length
            $item.addClass('selected')
            @$selectedItem = $item

    selectPrevItem: ->
        if @$selectedItem
            $items = @$('.items')
            $toSelect = $($items.get($items.index(@$selectedItem) - 1))
            if $toSelect.length
                @selectedItem($toSelect)

    selectNextItem: ->
        if not @$selectedItem
            @selectItem(@$('.item:first'))
        else
            $items = @$('.items')
            $toSelect = $($items.get($items.index(@$selectedItem) + 1))
            if $toSelect.length
                @selectedItem($toSelect)

    handleItemHover: (e)->
        @selectItem($(e.currentTarget))

    handleItemClick: (e)=>
        $item = $(e.currentTarget)
        @navigateToItem(
            $item.data('type'),
            $item.data('item')
        )

    navigateToItem: (type, item)=>
        Backbone.history.navigate '/', true

        switch type

            when 'collection:playlist'
                @model.library.playlists.selected(
                    @model.library.playlists.get(item))

            when 'collection:artist'
                pubsub.publish('select:artist', artist: item)

            when 'collection:album'
                pubsub.publish('select:album', item)

            when 'collection:track'
                track = @model.library.get(item)
                pubsub.publish('select:track', track)

            when 'external:artist'
                pubsub.router.navigate('/artist/' + item, yes)

            else
                throw 'Unknown item ' + type

        @hide()


module.exports = SearchFormView
