import logging

import tornadio2
import tornado.gen
from tornado.web import decode_signed_value

from cloudtunes.users.models import User
from cloudtunes.users.sessions import Session
from cloudtunes import settings
from cloudtunes import async


class SocketConnection(tornadio2.SocketConnection):
    """
    Class representing the top-level socket.io connection from a client
    to the server.

    """

    # To be assigned in `.router`
    __endpoints__ = {}

    @tornado.gen.coroutine
    def on_open(self, request):
        """
        :type request: tornadio2.session.ConnectionInfo
        """
        # Get the current user.
        user_id = self.get_user_id(
            request.get_cookie(settings.SID_COOKIE).value)

        self.logger = logging.getLogger(
            '%s:user=%s.session=%s' % (
                __name__,
                user_id,
                self.session.session_id,
            )
        )

        self.logger.info('socketio user connected')

        try:
            self.user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            self.logger.warning('user does not exist, closing.')
            self.close()

        self.logger = logging.getLogger(
            '%s:user=%s' % (__name__, self.user.username))

        # Connect to Redis backend and subscribe to pubsub for this user.
        self.user_channel = 'user:%s' % user_id

        self.logger.debug('subscribing to redis channel %s:*',
                          self.user_channel)
        self.redis_client = async.RedisClient()
        self.redis_client.connect()

        yield tornado.gen.Task(
            self.redis_client.psubscribe,
            self.user_channel + ':*'
        )

        self.redis_router = RedisPubsubRouter(self)
        self.redis_client.listen(self.redis_router.on_message)

    def get_user_id(self, sid_cookie):
        sid = decode_signed_value(settings.TORNADO_APP['cookie_secret'],
                                  settings.SID_COOKIE, sid_cookie)
        session = Session(sid)
        session.load()
        return session['user']

    def on_close(self):
        self.logger.info('disconnected, unsubscribing from redis pubsub')
        self.redis_client.unsubscribe(self.user_channel)
        self.redis_client.disconnect()


class RedisPubsubRouter(object):
    """
    A top-level Redis PubSub listener.

    Each `SocketConnection` has a `RedisPubsubRouter`.

    It handles pubsub messages sent to the user's channel,
    and routes them to to the `BackendChannel` subclass instances
    stored in `self.channels`

    """

    def __init__(self, io):
        self.io = io
        self.logger = io.logger.getChild('RedisPubsubRouter')
        self.channels = {}

    def connect(self, BackendChannel, frontend_channel):
        """
        Connect `backend_channel` with `frontend_channel`.

        """
        # The backend channel can use the frontend one to talk to the user.
        backend_channel = BackendChannel(frontend_channel)

        # Route backend messages in the namespace to backend channel.
        self.channels[frontend_channel.namespace] = backend_channel

        return backend_channel

    def on_message(self, msg):
        """
        Delegate `msg` to the right BackendChannel instance.

        :type msg: tornadoredis.client.Message
        """
        if msg.kind == 'psubscribe':
            self.logger.info('subscribed')
            return

        self.logger.debug('got message from redis: channel=%r msg=%r',
                          msg.channel, msg)

        # "user:id:namespace:event"
        bits = msg.channel.split(':', 3)
        namespace = bits[2]  # "namespace"
        event = bits[3]  # "a:b:c"

        if namespace == 'session':
            session_id, namespace, event = event.split(':', 3)
            if session_id != str(self.io.session.session_id):
                self.logger.debug(
                    'not for this session, but for %s, ignoring', session_id)
                return
            else:
                self.logger.debug('yup, it\'s for me')

        channel = self.channels.get(namespace)

        if not channel:
            self.logger.warning(
                'No redis channel "%s" in this user chat. Message: %r',
                namespace, msg
            )
        else:
            self.logger.debug('routing to %s', channel)
            channel.handle(event, msg.body)
