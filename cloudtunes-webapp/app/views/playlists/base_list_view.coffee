BaseListView = require 'views/base_list_view'


class BaseLibraryListView extends BaseListView

    # The name of the entity/cursor store on library.cursors.<name>
    namespace: null

    initialize: (options)->
        super options
        @collection = @getList(@model.getPlaylist())
        @listenTo(@collection, 'add', @addItem)
        @listenTo(@collection, 'change', @changeItem)
        @listenTo(@collection, 'remove', @removeItem)
        @listenTo(@collection, 'reset', @render)


    getBody: ->
        @$('.body:first')

    getTracks: ->
        @model.getTrackList().getResult()

    getList: (playlist)->
        ###
        Return correct list from

        @param playlist TrackList

        ####
        playlist.children["#{ @namespace }s"]


module.exports = BaseLibraryListView
