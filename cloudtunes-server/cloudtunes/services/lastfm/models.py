from mongoengine import (StringField, URLField,
                         BooleanField, IntField, ListField)

from cloudtunes.services.models import ServiceAccount


class LastfmAccount(ServiceAccount):
    session_key = StringField()
    url = URLField()
    name = StringField()
    gender = StringField(max_length=1)
    country = StringField(max_length=2)
    lang = StringField(max_length=10)
    realname = StringField()
    subscriber = BooleanField()
    playcount = IntField()
    playlists = IntField()
    image = ListField()

    service_name = 'Last.fm'

    def get_username(self):
        return self.name

    def get_picture(self):

        for img in self['image']:
            if img['size'] == 'medium':
                tmpimg = img['#text']
                if tmpimg == '':
                    tmpimg = 'http://cdn.last.fm/flatness/responsive/2/noimage/default_user_60_g1.png'
                    return tmpimg

    def get_url(self):
        return self.url

