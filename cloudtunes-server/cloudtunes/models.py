from django.contrib.auth.models import AbstractUser
from django.db import models


class ServiceAccount(models.Model):

    service_name = None

    def get_username(self):
        raise NotImplementedError()

    def get_picture(self):
        raise NotImplementedError()

    def get_url(self):
        raise NotImplementedError()

    def to_json(self):
        return {
            'name': self.service_name,
            'username': self.get_username(),
            'url': self.get_url(),
            'picture': self.get_picture()
        }

    class Meta:
        abstract = True


class DropboxAccount(ServiceAccount):

    country = models.CharField(max_length=2, blank=True)
    display_name = models.CharField(max_length=255, blank=True)
    oauth_token_key = models.CharField(max_length=255)
    oauth_token_secret = models.CharField(max_length=255)
    delta_cursor = models.CharField(max_length=255, null=True)

    service_name = 'Dropbox'

    def get_username(self):
        return self.display_name

    def get_picture(self):
        return None

    def get_url(self):
        return None


class LastfmAccount(ServiceAccount):
    session_key = models.CharField(max_length=255)
    url = models.URLField(blank=True)
    name = models.CharField(max_length=255, blank=True)
    gender = models.CharField(max_length=1, blank=True)
    country = models.CharField(max_length=2, blank=True)
    lang = models.CharField(max_length=10, blank=True)
    realname = models.CharField(max_length=255, blank=True)
    subscriber = models.BooleanField()
    playcount = models.PositiveIntegerField()
    playlists = models.PositiveIntegerField()
    image = models.URLField()

    service_name = 'Last.fm'

    def get_username(self):
        return self.name

    def get_picture(self):

        for img in self['image']:
            if img['size'] == 'medium':
                return img['#text']

    def get_url(self):
        return self.url


class FacebookAccount(ServiceAccount):
    name = models.CharField(max_length=255)
    email = models.EmailField(blank=True)
    first_name = models.CharField(max_length=255)
    last_name = models.CharField(max_length=255)
    link = models.URLField()
    access_token = models.CharField(max_length=255)
    # ['data']['url'] / ['data']['is_silhouette']
    picture = models.URLField()

    service_name = 'Facebook'

    def get_username(self):
        return self.name

    def get_picture(self):
        if not self['picture']['data']['is_silhouette']:
            return self['picture']['data']['url']

    def get_url(self):
        return self.link


class User(AbstractUser):

    name = models.CharField(max_length=255)
    picture = models.URLField(blank=True)
    dropbox = models.OneToOneField(DropboxAccount, null=True)
    facebook = models.OneToOneField(FacebookAccount, null=True)
    lastfm = models.OneToOneField(LastfmAccount, null=True)

    desktop_notifications = models.BooleanField(default=True)
    confirm_exit = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        if not self.password:
            self.set_unusable_password()
        super(User, self).save(*args, **kwargs)


class Track(models.Model):
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
    user = models.ForeignKey(User, required=False)

    # All MBIDs are optional as they are filled only when possible.
    mbid = models.CharField(max_length=255, blank=True, db_index=True)
    artist_mbid = models.CharField(max_length=255, blank=True, db_index=True)
    album_mbid = models.CharField(max_length=255, blank=True, db_index=True)

    title = models.CharField(max_length=255)

    # artist and album names
    artist = models.CharField(max_length=255, blank=True)
    album = models.CharField(max_length=255, blank=True)

    number = models.PositiveIntegerField(null=True)
    # set = IntField()
    year = models.IntegerField(null=True)

    # Source metadata.
    source = models.CharField(
        choices=[
            ('youtube', 'YouTube'),
            ('dropbox', 'Dropbox'),
        ],
        max_length=20
    )
    # ID for YT, path for DropBox
    source_id = models.TextField(db_index=True)

    def __unicode__(self):
        return self.title


class Playlist(models.Model):
    name = models.CharField(max_length=255)
    public = models.BooleanField(default=False)
    collaborative = models.BooleanField(default=False)
    owner = models.ForeignKey(User, related_name='playlists')
    tracks = models.ManyToManyField(Track, related_name='playlists')


class FacebookUser(models.Model):
    fbid = models.PositiveIntegerField(unique=True)
    name = models.CharField(max_length=255)
    friends = models.ManyToManyField('self')
