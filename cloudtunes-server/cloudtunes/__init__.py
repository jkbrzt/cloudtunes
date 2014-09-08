import mongoengine

from cloudtunes import settings


mongoengine.connect('cloudtunes', **settings.MONGODB)


# Load all models so that mongoengine properly registers them.
from .users.models import User
from .library.models import Track, Playlist
from .services.dropbox.models import DropboxTrack, DropboxAccount
from .services.lastfm.models import LastfmAccount
from .services.facebook.models import FacebookAccount, FacebookUser
from .services.youtube.models import YoutubeTrack
