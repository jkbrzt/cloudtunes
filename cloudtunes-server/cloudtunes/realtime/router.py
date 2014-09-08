from tornadio2 import TornadioRouter

from cloudtunes.realtime import frontend

from .connection import SocketConnection


ENABLED_CHANNELS = {
    frontend.RemoteControlChannel,
    frontend.ModelChannel,
    frontend.PlayerChannel,
    frontend.SyncChannel,
}

# Install endpoints.
SocketConnection.__endpoints__ = {
    '/' + channel.namespace: channel
    for channel in ENABLED_CHANNELS
}

router = TornadioRouter(SocketConnection)
