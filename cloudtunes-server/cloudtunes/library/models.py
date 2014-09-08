from mongoengine import (
    CASCADE, PULL, EmbeddedDocumentField,
    ListField, StringField, BooleanField, ReferenceField, IntField
)

from cloudtunes.base.models import Document
from cloudtunes.users.models import User
from cloudtunes.services.youtube.models import YoutubeTrack
from cloudtunes.services.dropbox.models import DropboxTrack


UNTITLED_ARTIST = 'Unknown Artist'
UNTITLED_ALBUM = 'Unknown Album'


class Track(Document):
    """
    Track is a reference to a playable medium stored in an external,
    online source.

    It has common meta data (title, year, album name, artist name, ...)
    and is optionally linked to Musicbrainz DB via the track's MBID,
    artist's MBID, or/and album MBID.

    It is an "item" in FRBR's parlance.
    It is a "recording" in MB's parlance.

    http://en.wikipedia.org/wiki/FRBR
    http://musicbrainz.org/doc/MusicBrainz_Database/Schema

    It has `source` which determines where the medium is physically stored.

    """
    # User is optional as tracks can exist and be in no one's music collection.
    # However, as soon a user adds it to their collection, an editable copy
    # of the track with the user assigned is created.
    user = ReferenceField(
        User,
        dbref=False,
        required=False,
        reverse_delete_rule=CASCADE
    )

    # All MBIDs are optional as they are filled only when possible.
    mbid = StringField()
    artist_mbid = StringField()
    album_mbid = StringField()

    title = StringField(required=True)

    # artist and album names
    artist = StringField()
    album = StringField()

    number = IntField()
    # set = IntField()
    year = IntField()

    # Source metadata.
    source = StringField(
        required=True,
        choices=[
            'youtube',
            'dropbox'
        ]
    )
    dropbox = EmbeddedDocumentField(DropboxTrack)
    youtube = EmbeddedDocumentField(YoutubeTrack)

    meta = {
        'collection': 'tracks',
        'allow_inheritance': False,
        'indexes': [
            'user',
            'mbid',
            'artist_mbid',
            'album_mbid',
        ]
    }

    def __unicode__(self):
        return self.title

    def to_json(self):

        data = {
            'id': str(self.pk),
            'title': self.title,
            'artist': self.artist or UNTITLED_ARTIST,
            'album': self.album or UNTITLED_ALBUM,
            'number': self.number,
            'source': self.source[0],
        }

        if self.source == 'youtube':
            data['sourceId'] = self.youtube.id

        return data


class Playlist(Document):

    name = StringField(
        max_length=255,
        min_length=1,
        required=True
    )
    public = BooleanField(
        default=False
    )
    collaborative = BooleanField(
        default=False
    )
    owner = ReferenceField(
        User,
        dbref=False,
        required=True
    )
    tracks = ListField(
        ReferenceField(
            Track,
            dbref=False,
            reverse_delete_rule=PULL
        )
    )
    meta = {
        'collection': 'playlists',
        'allow_inheritance': False
    }
