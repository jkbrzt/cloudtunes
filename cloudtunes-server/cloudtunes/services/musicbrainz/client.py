"""
http://musicbrainz.org/doc/MusicBrainz_Database/Schema

"""
from io import BytesIO
import json
from urllib import urlencode

from tornado.gen import coroutine, Task, Return
from tornado.httpclient import AsyncHTTPClient
from musicbrainzngs import mbxml

from cloudtunes import async


BASE_URL = 'http://musicbrainz.org/ws/2'


class MusicbrainzClient(object):

    def __init__(self, base=BASE_URL, cache=True):
        self.cache = cache
        self.base = base
        self.http = AsyncHTTPClient()

    def parse_response_body(self, body):
        return mbxml.parse_message(BytesIO(body))

    @coroutine
    def fetch(self, url, method):
        assert method == 'GET'

        data = None
        cache_key = 'cache:musicbrainz:%s' % url

        if self.cache:
            response = (yield Task(async.redis.get, cache_key))
            if response:
                data = json.loads(response)

        if not data:
            response = yield self.http.fetch(url, method=method)
            if response.error is not None:
                response.rethrow()
            data = self.parse_response_body(response.body)
            yield Task(async.redis.setex,
                       key=cache_key,
                       ttl=60 * 60 * 24 * 7,
                       value=json.dumps(data))
        raise Return(data)

    def request(self, url, params=None):
        url = self.base + url
        if params:
            url += '?' + urlencode(params)
        return self.fetch(url=url, method='GET')

    def search_artists(self, query, limit=5):
        return self.request('/artist', params={
            'query': query,
            'limit': limit
        })

    def search_tracks(self, query, limit=3):
        return self.request('/recording', params={
            'query': query,
            'limit': limit
        })

    def lookup_artist(self, mbid):
        return self.request('/artist/' + mbid, params={
            'inc': 'release-groups',
        })

    def lookup_release_group(self, mbid):
        """Albums."""
        return self.request('/release-group/' + mbid, params={
            'inc': 'releases'
        })

    def lookup_release(self, mbid):
        return self.request('/release/' + mbid, params={
            'inc': 'recordings',
        })

    def get_releases(self, release_group_mbid, callback):
        """Album release."""
        self.request('/release', params={
            'release-group': release_group_mbid,
            'inc': 'recordings',
        })
