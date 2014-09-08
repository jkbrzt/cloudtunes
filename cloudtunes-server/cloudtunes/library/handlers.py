from __future__ import absolute_import
import json

from bson import ObjectId
import tornado.web
import tornado.gen
from tornado.web import HTTPError
from mongoengine import ValidationError

from cloudtunes import async
from cloudtunes.base.handlers import ResourceHandler
from .utils import compress_tracks_to_json, FIELDS_ORDER
from .models import Playlist, Track


class LibraryHandler(ResourceHandler):
    """
    A handler that returns the whole library on GET (tracks and playlists).

    """
    @tornado.gen.coroutine
    @tornado.web.authenticated
    def get(self):

        tracks_query = async.mongo.tracks.find(
            {
                'user': self.current_user.id
            },
            fields={
                'source',
                'artist',
                'album',
                'title',
                'number',
                'youtube.id',
                'mbid',
                'artist_mbid',
                'album_mbid',
            },
        )

        playlists_query = async.mongo.playlists.find(
            {
                'owner': self.current_user.id
            },
            fields={
                'name',
                'collaborative',
                'tracks'
            }
        )

        tracks, playlists = yield [tracks_query.to_list(None),
                                   playlists_query.to_list(None)]

        library = {
            '_fields': FIELDS_ORDER,
            'collection': compress_tracks_to_json(tracks),
            'playlists': [
                {
                    'id': str(playlist['_id']),
                    'name': playlist['name'],
                    'collaborative': playlist.get('collaborative', False),
                    'tracks': [
                        str(track_id)
                        for track_id in playlist.get('tracks', [])
                    ],
                }
                for playlist in playlists
            ]
        }

        self.finish(json.dumps(library))


class PlaylistHandler(ResourceHandler):
    """Create/edit/delete a playlist."""

    def _get_playlist(self, playlist_id, not_found_status=410):
        try:
            return Playlist.objects.get(
                id=ObjectId(playlist_id),
                owner=self.current_user
            )
        except Playlist.DoesNotExist:
            raise HTTPError(not_found_status)

    @tornado.web.authenticated
    def delete(self, playlist_id):
        self._get_playlist(playlist_id, 204).delete()

    @tornado.web.authenticated
    def put(self, playlist_id):
        playlist = self._get_playlist(playlist_id)
        playlist.name = self.request.data.get('name')
        try:
            playlist.save()
        except ValidationError as e:
            self.set_status(400)
            self.write(e.to_dict())

    @tornado.web.authenticated
    def post(self):
        # TODO: validation, etc.
        playlist = Playlist(
            name=self.request.data['name'],
            owner=self.current_user
        )
        playlist.save()
        self.finish({
            'id': str(playlist.id)
        })


class PlaylistTracksHandler(ResourceHandler):
    """Add/remove tracks from a playlist on POST."""

    @tornado.web.authenticated
    def post(self, playlist_id, action):

        tracks = map(ObjectId, self.request.data)
        action = {
            'add': 'push_all__tracks',
            'remove': 'pull_all__tracks',
        }[action]

        Playlist.objects(owner=self.current_user, id=playlist_id)\
                .update_one(**{action: tracks})


class TrackHandler(ResourceHandler):

    @tornado.web.authenticated
    def post(self):
        # TODO: validation, create multiple, etc.
        data = self.request.data
        assert data.get('source') == 'y'
        data.update({
            'source': 'youtube',
            'youtube': {'id': data.pop('source_id')},
            'user': self.get_current_user()
        })
        track = Track(**data)
        track.save()
        self.finish({'id': str(track.id)})
