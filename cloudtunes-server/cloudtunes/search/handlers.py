from tornado.gen import coroutine
from tornado.web import authenticated

from cloudtunes.base.handlers import ResourceHandler
from cloudtunes.services.musicbrainz.client import MusicbrainzClient


class SuggestHandler(ResourceHandler):

    @coroutine
    @authenticated
    def get(self):
        """
        Search for artists and tracks on MusicBrainz and return JSON.

        TODO: Search for tracks as well as combine queries ("artist album")

        """
        mb = MusicbrainzClient()
        query = self.get_argument('q')
        artists, tracks = yield [mb.search_artists(query),
                                 mb.search_tracks(query)]
        data = {
            'artists': [
                {
                    'id': artist['id'],
                    'artist': artist['name'],
                    'note': artist.get('disambiguation', '')
                }
                for artist in artists['artist-list']
            ],
            'tracks': [
                {
                    'id': track['id'],
                    'title': track['title'],
                    'artist': track['artist-credit-phrase']
                }
                for track in tracks['recording-list']
            ]
        }
        self.finish(data)
