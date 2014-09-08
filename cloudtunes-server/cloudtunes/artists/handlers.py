import json
from operator import itemgetter

import tornado.web
from tornado.gen import coroutine, Task

from cloudtunes import async
from cloudtunes.base.handlers import ResourceHandler
from cloudtunes.services.musicbrainz.client import MusicbrainzClient
from cloudtunes.services.lastfm.client import AsyncLastfmClient


# TODO: some lastfm artists don't have ids yet, allow lookup by name
# FIXME: Data Rock has no albums
# http://cloudtun.es/artist/5cefe5de-98fb-4a78-8d2f-3b6e7d9cf441/discography


def serialise_lastfm_artists(artists):
    return [
        serialise_lastfm_artist(artist)
        for artist in artists if artist['mbid']
    ]


def serialise_lastfm_artist(artist):
    return {
        'id': artist['mbid'],
        'name': artist['name'],
        'images': {
            img['size']: img['#text']
            for img in artist['image']
        },
    }


class ArtistHandler(ResourceHandler):

    @tornado.web.authenticated
    @coroutine
    def get(self, mbid):
        """Return artist's info and its discography as JSON.

        :param mbid: the artist's MusicBrainz ID

        """

        cache_key = 'cache:artist:%s' % mbid

        cached = yield Task(async.redis.get, cache_key)
        if cached:
            self.finish(cached)
            return

        mb = MusicbrainzClient()
        lf = AsyncLastfmClient()

        mb_artist = yield mb.lookup_artist(mbid)

        mb_artist = mb_artist['artist']
        lf_artist, lf_similar, lf_albums = yield [
            lf.artist.get_info(artist=mb_artist['name'], mbid=mbid),
            lf.artist.get_similar(artist=mb_artist['name'], mbid=mbid),
            lf.artist.get_top_albums(artist=mb_artist['name'], mbid=mbid)
        ]

        # FIXME: the following sometimes fails.
        # assert lf_artist['mbid'] == mbid

        similar = [] if not isinstance(lf_similar['artist'], list) else [
            serialise_lastfm_artist(similar_artist)
            for similar_artist in lf_similar['artist']
            if similar_artist['mbid']
        ]
        albums = lf_albums.get('album', [])
        if isinstance(albums, dict):
            albums = [albums]
        data = {
            'id': mbid,
            'name': mb_artist['name'],
            'albums': [
                {
                    'id': album['mbid'],
                    'name': album['name'],
                    'year': '(year)', #parse_year(album['first-release-date']),
                    'type': '(type)', #album.get('type'),
                    'subtypes': [], #album.get('secondary-type-list'),
                    'images': {
                        img['size']: img['#text']
                        for img in album['image']
                    }
                }
                for album in albums
                if album['mbid']
                #if 'secondary-type-list' not in album
            ],
            'bio': lf_artist['bio']['content'].strip(),
            'images': {
                img['size']: img['#text']
                for img in lf_artist['image']
            },
            'similar': similar
        }

        data['albums'].sort(key=itemgetter('year'), reverse=True)

        data_json = json.dumps(data)

        self.finish(data)

        yield Task(async.redis.set, cache_key, data_json)


class AlbumHandler(ResourceHandler):

    @coroutine
    @tornado.web.authenticated
    def get(self, mbid):
        """Return an album track list as JSON.

        :param mbid: the album's MusicBrainz ID

        """
        mb = MusicbrainzClient()

        response = yield mb.lookup_release(mbid)
        release = response['release']
        track_list = release['medium-list'][0]['track-list']
        tracks = []
        for number, track in enumerate(track_list, start=1):
            recording = track['recording']
            tracks.append({
                'id': recording['id'],
                'number': number,
                'title': recording['title'],
                'album': release['title']
            })

        self.finish(json.dumps(tracks))


class ArtistsChartHandler(ResourceHandler):

    @coroutine
    @tornado.web.authenticated
    def get(self, chart):
        lastfm = AsyncLastfmClient()
        get_artists = {
            'top': lastfm.chart.get_top_artists,
            'trending': lastfm.chart.get_hyped_artists,
        }[chart]
        response = yield get_artists()
        artists = serialise_lastfm_artists(response['artist'])
        self.finish(json.dumps(artists))


class RecommendedArtistsHandler(ResourceHandler):

    @coroutine
    @tornado.web.authenticated
    def get(self):
        if not self.current_user['lastfm']:
            artists = []
        else:
            lf = AsyncLastfmClient(
                session_key=self.current_user.lastfm.session_key
            )

            response = yield lf.user.get_recommended_artists()
            artists = serialise_lastfm_artists(response['artist'])
        self.finish(json.dumps(artists))
