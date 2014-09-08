{PageView} = require 'mvc'
template = require 'templates/search/search_page'
SearchFormView = require 'views/search/search_form_view'
pubsub = require 'pubsub'


module.exports = class SearchPageView extends PageView

    id: 'search'
    template: template

    render: ->
        super
        @subview(new SearchFormView(
            el: @$('#search')
            model: pubsub.libraryState
        )).render()
        @
