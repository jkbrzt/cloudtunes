"""
Channels that handle user messages from Redis pubsub.

"""


class BaseBackendChannel(object):
    """
    A Redis pubsub channel.

    """

    namespace = None

    def __init__(self, frontend_channel):
        """
        :type frontend_channel: BaseFrontendChannel
        """
        self.frontend_channel = frontend_channel

    def handle(self, event, body):
        handler = getattr(self, event, None)
        if handler:
            if not getattr(handler, 'is_handler', False):
                raise AttributeError('%s is not a handler!' % handler)
        else:
            handler = self.forward_to_client

        # noinspection PyCallingNonCallable
        handler(event, body)

    def forward_to_client(self, event, body):
        self.frontend_channel.emit(event, body)


class ForwardBackendChannel(BaseBackendChannel):
    """Forward messages sent to this channel to the socket io channel."""
