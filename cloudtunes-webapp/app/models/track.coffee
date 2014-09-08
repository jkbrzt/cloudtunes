{Model} = require 'mvc'


class Track extends Model

    defaults:
        artist: 'Unknown Artist'
        album: 'Unknown Album'
        title: 'Untitled Track'

    url: ->
        url = "#{@collection.url}/tracks"
        if @id
            url += "/#{@id}"
        url

    equals: (other)->

        if @ is other
            return yes

        if @has('mbid') and other.has('mbid')
            return @get('mbid') is other.get('mbid')

#        if @has('source_id') and other.has('source_id')
#            return @get('source_id') is other.get('source_id')


module.exports = Track
