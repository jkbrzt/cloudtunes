{View} = require 'mvc'


class VideoListView extends View

    initialize: (options)->
        {@VideoView} = options

    render: =>
        @collection.each (video)=>
            view = new @VideoView(model: video)
            @$el.append(@subview('video-' + video.id, view).render().el)
        @


module.exports = VideoListView
