from __future__ import absolute_import

import tornadio2
from tornado.web import url, Application, StaticFileHandler

from cloudtunes import settings
from cloudtunes.handlers import (
    MainHandler,
    NoCacheStaticFileHandler
)
from cloudtunes.users.handlers import (
    UserHandler,
    LogoutHandler
)
from cloudtunes.library.handlers import (
    LibraryHandler,
    PlaylistHandler,
    PlaylistTracksHandler,
    TrackHandler
)
from cloudtunes.services.dropbox.handlers import (
    DropboxAuthHandler,
    DropboxAuthCallbackHandler,
    PlayHandler
)
from cloudtunes.artists.handlers import (
    ArtistHandler,
    AlbumHandler,
    ArtistsChartHandler,
    RecommendedArtistsHandler
)
from cloudtunes.search.handlers import SuggestHandler
from cloudtunes.services.facebook.handlers import FacebookHandler
from cloudtunes.services.lastfm.handlers import LastfmAuthHandler
from cloudtunes import realtime


handlers = realtime.router.urls + [

    ### API
    url('/api/library', LibraryHandler, name='library'),
    url('/api/library/tracks', TrackHandler),
    url('/api/library/playlists', PlaylistHandler),
    url('/api/library/playlists/([^/]+)', PlaylistHandler),
    url('/api/library/playlists/([^/]+)/tracks/(add|remove)', PlaylistTracksHandler),
    url('/api/user', UserHandler, name='user'),

    url('/api/search/suggest', SuggestHandler),
    url('/api/artist/([^/]+)', ArtistHandler),
    url('/api/album/([^/]+)', AlbumHandler),
    url('/api/explore/artists/(top|trending)', ArtistsChartHandler),
    url('/api/explore/artists/recommended', RecommendedArtistsHandler),

    url('/dropbox/play/([^/]+)', PlayHandler, name='play'),

    ### Auth
    url('/logout', LogoutHandler),
    url('/auth/dropbox', DropboxAuthHandler, name='dropbox', kwargs={
        'service_name': 'dropbox'
    }),
    url('/auth/dropbox/callback', DropboxAuthCallbackHandler,
        name='dropbox_callback', kwargs={
            'service_name': 'lastfm'
        }
    ),
    url('/auth/facebook', FacebookHandler, name='facebook', kwargs={
        'service_name': 'facebook'
    }),
    url('/auth/lastfm', LastfmAuthHandler, name='lastfm', kwargs={
        'service_name': 'lastfm'
    }),
    url('/auth/lastfm/popup', LastfmAuthHandler, name='lastfm_popup', kwargs={
        # Redirect with params doesn't work with Last.fm,
        # therefore we need a special URL it.
        'popup': True,
        'service_name': 'lastfm',
    }),

    ### Static files
    url(
        '/homepage/(.+)',
        handler=(
            NoCacheStaticFileHandler if settings.DEBUG else
            StaticFileHandler
        ),
        kwargs={
            'path': settings.HOMEPAGE_SITE_DIR + '/homepage'
        }
    ),
    url('.*', MainHandler),
]


app = Application(
    handlers=handlers,
    socket_io_address='0.0.0.0',
    **settings.TORNADO_APP
)


def main():
    tornadio2.server.SocketServer(app)


if __name__ == '__main__':
    main()
