"""
Channels that handle user SocketIO events.

"""
import time
import logging

import tornadio2
import tornado

from cloudtunes.utils import cached_property
from cloudtunes.library.models import Track
from cloudtunes.services.dropbox.sync import sync_account
from cloudtunes.services.lastfm.client import AsyncLastfmClient
from cloudtunes.services.youtube.sync import add_video_by_url
from .backend import ForwardBackendChannel


class BaseFrontendChannel(tornadio2.SocketConnection):
    """
    A Socket.io channel.

    """
    namespace = None
    BackendChannel = None

    def __init__(self, session, endpoint=None):
        super(BaseFrontendChannel, self).__init__(session, endpoint)
        self.user = self.session.conn.user
        self.user_channel = self.session.conn.user_channel
        if self.BackendChannel:
            session.conn.redis_router.connect(
                frontend_channel=self,
                BackendChannel=self.BackendChannel
            )
        self.logger = logging.getLogger(
            'cloudtunes.chat.frontend'
            ':namespace={namespace}'
            ':user={user}'
            ':session={session}'
            .format(
                user=self.user.username,
                namespace=self.namespace,
                session=self.session.session_id
            )
        )


class RemoteControlChannel(BaseFrontendChannel):

    namespace = 'remote'
    BackendChannel = ForwardBackendChannel

    def delegate(self, session_id, event, message=None):
        self.user.emit(
            namespace='remote',
            session_id=session_id,
            event=event,
            message=message
        )

    @tornadio2.event
    def get_my_session_id(self):
        self.emit('your_session_id', self.session.session_id)

    @tornadio2.event
    def play_artist(self, session_id, artist):
        self.delegate(session_id, 'play_artist', artist)

    @tornadio2.event
    def play_pause(self, session_id):
        self.delegate(session_id, 'play_pause')

    @tornadio2.event
    def prev(self, session_id):
        self.delegate(session_id, 'prev')

    @tornadio2.event
    def next(self, session_id):
        self.delegate(session_id, 'next')


class SyncChannel(BaseFrontendChannel):

    namespace = 'sync'
    BackendChannel = ForwardBackendChannel

    @tornadio2.event
    def dropbox(self):
        logging.info('starting dropbox sync %s', self.user)
        sync_account.delay(self.user.dropbox.id)

    @tornadio2.event
    def add_url(self, url):
        add_video_by_url.delay(user_id=self.user.id, url=url)


class ModelChannel(BaseFrontendChannel):
    """
    REST over Socket.io.

    """
    BackendChannel = ForwardBackendChannel
    namespace = 'model'

    def __init__(self, session, endpoint=None):
        super(ModelChannel, self).__init__(session, endpoint)

        self.resources = {
            # 'user': UserResource(self.user)
        }

    def on_event(self, name, args=None, kwargs=None):
        resource, method = name.split(':')
        assert resource in self.resources
        return self.resources[resource].dispatch(method, args, kwargs)


class PlayerChannel(BaseFrontendChannel):
    namespace = 'player'
    BackendChannel = ForwardBackendChannel
    current_track = None

    @cached_property
    def lastfm(self):
        return AsyncLastfmClient(
            session_key=self.user['lastfm']['session_key'])

    @tornadio2.event
    @tornado.gen.coroutine
    def play(self, track_dict):

        self.logger.info('play(): %r' % track_dict)

        if self.user['lastfm']:


            track = Track(**track_dict)

            if self.current_track:
                self.logger.info(
                    'play(): scrobbling previous track: %r',
                    self.current_track
                )
                # noinspection PyUnresolvedReferences
                resp = yield self.lastfm.track.scrobble(
                    track=self.current_track.title,
                    artist=self.current_track.artist,
                    album=self.current_track.album,
                    timestamp=self.current_track._timestamp,
                )
                self.logger.debug('play(): scrobble response: %r', resp)

            self.logger.info('play(): updating "Now Playing"')
            resp = yield self.lastfm.track.update_now_playing(
                track=track.title,
                artist=track.artist,
                album=track.album,
            )
            self.logger.debug('play(): update_now_playing response: %r', resp)
            track._timestamp = int(time.time())
            self.current_track = track
