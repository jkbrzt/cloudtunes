Track = require 'models/track'


class YouTubeTrack extends Track

    getImages: ->
        [
            "http://i.ytimg.com/vi/#{@getSourceID()}/default.jpg"
            #"http://i.ytimg.com/vi/#{@getSourceID()}/hqdefault.jpg"
        ]
