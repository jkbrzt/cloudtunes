_ = require 'underscore'
{Model, Collection} = require 'mvc'
{escapeRegExp} = require 'utils'
pubsub = require 'pubsub'
Track = require 'models/track'
{YOUTUBE} = require 'source_ids'


class Video extends Model

    toCloudtunesTrack: ->
        {mbtrack, mbartist} = @collection


        # In the library?
        track = pubsub.user.library.findWhere
            source: YOUTUBE
            source_id: @id

        if not track
            if mbtrack
                track = mbtrack.toCloudtunesTrack()
            else
                track = new Track
                    artist: mbartist.get('name')
                    title: @getCleanTitle()
                    artist_mbid: mbartist.id

        track.set
            source: YOUTUBE
            source_id: @id
            video: @


        track

    getCleanTitle: ->
        artistName = (
            @collection.mbartist?.get('name') \
            or @collection.mbtrack.get('artist').get('name')
        )
        if not @_re
            reString = escapeRegExp(artistName.toLowerCase())
                        .replace(/\s+/g, '\s+')
                        .replace(/(and|&)+/g, '(and|&)')
            @_re = new RegExp("^\\s*(the\\s*)?#{ reString }[\\s|:/-]+", 'i')

        title = @get('title').replace(@_re, '')

        if title[0] in ['"', "'", '`']
            if title[0] is title[title.length - 1]
                title = title.slice(1, -1)  # remove quotes

        title or @get('title')


class YouTubeVideosSearch extends Collection

    model: Video

    initialize: (models, options)->
        {@mbartist, @mbtrack} = options
        # TODO: make this mbartist OR mbtrack nicer
        if not @mbartist and not @mbtrack
            throw 'MISSING TRACK OR ARTIST'
        super(models, options)

    url: ->
        q = (@mbartist or @mbtrack).getQuery()
        q = encodeURIComponent(q)
        "https://gdata.youtube.com/feeds/api/videos?v=2&alt=jsonc&category=Music&q=#{q}"

    fetch: (options)->
        if not options
            options = {}
        options.dataType = 'jsonp'
        super options

    parse: (response)->
        response.data.items


module.exports = YouTubeVideosSearch
