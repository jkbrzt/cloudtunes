from mongoengine import (
    PULL, ReferenceField,
    StringField, URLField, DictField, EmailField, IntField, ListField
)

from cloudtunes.base.models import Document
from cloudtunes.services.models import ServiceAccount
# from cloudtunes.users.models import User


class FacebookUser(Document):
    fbid = IntField(unique=True)
    name = StringField()
    friends = ListField(
        ReferenceField(
            'self',
            dbref=False,
            reverse_delete_rule=PULL,
        )
    )


class FacebookAccount(ServiceAccount):
    name = StringField()
    email = EmailField()
    first_name = StringField()
    last_name = StringField()
    link = URLField()
    access_token = StringField()
    # ['data']['url'] / ['data']['is_silhouette']
    picture = DictField()

    service_name = 'Facebook'

    def get_username(self):
        return self.name

    def get_picture(self):
        if not self['picture']['data']['is_silhouette']:
            return self['picture']['data']['url']

    def get_url(self):
        return self.link
