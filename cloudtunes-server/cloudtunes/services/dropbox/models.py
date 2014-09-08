from mongoengine import StringField

from cloudtunes.base.models import EmbeddedDocument
from cloudtunes.services.models import ServiceAccount


class DropboxAccount(ServiceAccount):
    country = StringField(max_length=2)
    display_name = StringField()
    oauth_token_key = StringField()
    oauth_token_secret = StringField()
    delta_cursor = StringField()

    service_name = 'Dropbox'

    def get_username(self):
        return self.display_name

    def get_picture(self):
        return None

    def get_url(self):
        return None


class DropboxTrack(EmbeddedDocument):

    path = StringField(required=True)
